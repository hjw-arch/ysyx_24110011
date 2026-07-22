#include "../Include/sdb.h"
#include "../Include/common.h"
#include "../Include/cpu_exec.h"
#include "../Include/log.h"
#include "../Include/device.h"
#include "../Include/difftest.h"
#include "../Include/pmc.h"

#ifdef SOC
#include "VysyxSoCFull___024root.h"
#else
#include "Vysyx___024root.h"
#endif

#define EBREAK_INST 0x00100073u
#define MIN_NUM_TO_DISASM 10

#define EX2LS_PC_HI 204
#define EX2LS_PC_LO 173
#define EX2LS_INST_HI 172
#define EX2LS_INST_LO 141
#define EX2LS_STORE_DATA_HI 31
#define EX2LS_STORE_DATA_LO 0
#define LS2WB_PC_HI 102
#define LS2WB_PC_LO 71
#define LS2WB_INST_HI 70
#define LS2WB_INST_LO 39

#define WIDE_BITS(data, hi, lo) \
	({ \
		const WData *const words = (data); \
		const int high = (hi); \
		const int low = (lo); \
		uint32_t value = 0; \
		for (int bit = low; bit <= high; bit++) { \
			if (words[bit / 32] & (1u << (bit % 32))) { \
				value |= 1u << (bit - low); \
			} \
		} \
		value; \
	})

#ifdef SOC
#define CORE_SIG(name) dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__##name
#else
#define CORE_SIG(name) dut.rootp->ysyx__DOT__u_cpu__DOT__##name
#endif

#define LSU_PC() WIDE_BITS(CORE_SIG(ex2ls_data).data(), EX2LS_PC_HI, EX2LS_PC_LO)
#define LSU_INST() WIDE_BITS(CORE_SIG(ex2ls_data).data(), EX2LS_INST_HI, EX2LS_INST_LO)
#define LSU_STORE_DATA() WIDE_BITS(CORE_SIG(ex2ls_data).data(), EX2LS_STORE_DATA_HI, EX2LS_STORE_DATA_LO)
#define WBU_PC() WIDE_BITS(CORE_SIG(ls2wb_data).data(), LS2WB_PC_HI, LS2WB_PC_LO)
#define WBU_INST() WIDE_BITS(CORE_SIG(ls2wb_data).data(), LS2WB_INST_HI, LS2WB_INST_LO)
#define LSU_AXI_DONE() CORE_SIG(u_LSU__DOT__mem_resp_fire)

typedef struct {
	uint32_t pc;
	uint32_t inst;
	bool skip_ref;
} commit_info_t;

cpu_t cpu;
npc_state_t npc_state = {NPC_STOP, 0, 0};

uint64_t cycle_times = 0;
uint64_t dynamic_insts = 0;
static bool wbu_skip_ref = false;

void npc_set_state(npc_exec_state_t state, uint32_t halt_pc, uint32_t halt_ret) {
	npc_state.state = state;
	npc_state.halt_pc = halt_pc;
	npc_state.halt_ret = halt_ret;
}

bool npc_is_exit_status_bad() {
	return !((npc_state.state == NPC_END && npc_state.halt_ret == 0) ||
			 npc_state.state == NPC_QUIT);
}

static void npc_report_state() {
	if (npc_state.state == NPC_END) {
		printf("%s at pc = 0x%08x\n",
			npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN)
									 : ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED),
			npc_state.halt_pc);
	} else if (npc_state.state == NPC_ABORT) {
		printf("%s at pc = 0x%08x\n", ANSI_FMT("ABORT", ANSI_FG_RED), npc_state.halt_pc);
	}
}

#ifdef CONFIG_DIFFTEST
#define ADDR_IN_RANGE(addr, base, size) ((uint32_t)((addr) - (base)) < (size))

static bool difftest_addr_needs_skip(uint32_t addr) {
#ifdef SOC
	return !(ADDR_IN_RANGE(addr, 0x30000000u, 0x10000000u) ||
			 ADDR_IN_RANGE(addr, 0x0f000000u, 0x00002000u) ||
			 ADDR_IN_RANGE(addr, 0xa0000000u, 0x02000000u));
#else
	return !ADDR_IN_RANGE(addr, RAM_START_ADDR, RAM_SIZE);
#endif
}
#endif

#ifdef CONFIG_MTRACE
static void record_mtrace_lsu() {
	bool is_load = CORE_SIG(u_LSU__DOT__input_is_load);
	uint8_t len = 1u << ((LSU_INST() >> 12) & 0x3);
	uint32_t data = is_load ? CORE_SIG(u_LSU__DOT__axi_rdata) : LSU_STORE_DATA();
	mtrace_record(LSU_PC(), is_load, CORE_SIG(u_LSU__DOT__lsu_addr), len, data);
}
#endif

static commit_info_t get_commit_info() {
	return {
		.pc = WBU_PC(),
		.inst = WBU_INST(),
	};
}

static void sync_arch_state(uint32_t pc) {
	for (int i = 0; i < RF_NUM; i++) {
		cpu.registerFile[i] = CORE_SIG(u_WBU__DOT__u_registerfile__DOT__register_file)[i];
	}
	cpu.registerFile[0] = 0;
	cpu.pc = pc;
}

static void exec_cycle() {
	bool axi_done = LSU_AXI_DONE();
	bool next_skip_ref = false;

#ifdef CONFIG_DIFFTEST
	next_skip_ref = axi_done && difftest_addr_needs_skip(CORE_SIG(u_LSU__DOT__lsu_addr));
#endif

	IFDEF(CONFIG_MTRACE, if (axi_done) record_mtrace_lsu());
	IFDEF(CONFIG_PERFORMANCE_COUNTER,
		if (CORE_SIG(wbu_redirect_valid)) PerformanceCounter_record_wbu_redirect();
		if (CORE_SIG(lsu_redirect_valid)) PerformanceCounter_record_lsu_redirect();
		PerformanceCounter_record_cycle());
	cycle;
	cycle_times++;
	wbu_skip_ref = CORE_SIG(ls2wb_valid) && next_skip_ref;
}

static commit_info_t cpu_exec_one() {
	uint64_t retire_cycles = 0;

	while (!CORE_SIG(ls2wb_valid)) {
		exec_cycle();
		retire_cycles++;
	}

	commit_info_t commit = get_commit_info();
	commit.skip_ref = wbu_skip_ref;
	exec_cycle();			// 正式提交
	retire_cycles++;
	sync_arch_state(commit.pc);
	dynamic_insts++;
	IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_record_commit(commit.pc, commit.inst, retire_cycles));
	return commit;
}

void cpu_exec(uint32_t n) {
	if (npc_state.state == NPC_END || npc_state.state == NPC_ABORT) {
		Log("Program has ended; restart NPC to run it again.");
		return;
	}

	if (npc_state.state == NPC_QUIT) {
		return;
	}

	npc_set_state(NPC_RUNNING, cpu.pc, 0);

	for (uint32_t i = 0; i < n; i++) {
		commit_info_t commit = cpu_exec_one();

		if (n < MIN_NUM_TO_DISASM) {
			char disasm_buf[64];
			printf("0x%08x: ", commit.pc);
			for (int j = 3; j >= 0; j--) {
				printf("%02x ", ((uint8_t *)&commit.inst)[j]);
			}
			disassemble(disasm_buf, sizeof(disasm_buf), commit.pc, (uint8_t *)&commit.inst, 4);
			printf("        %s\n", disasm_buf);
		}

		IFDEF(CONFIG_ITRACE, iringbuf_load(commit.pc, commit.inst));
		IFDEF(CONFIG_FTRACE, ftrace_record(commit.pc, commit.inst));

		if (commit.inst == EBREAK_INST) {
			Log("Get 'ebreak' instruction, program over.");
			npc_set_state(NPC_END, commit.pc, cpu.registerFile[10]);
		}

#ifdef CONFIG_DIFFTEST
		if (npc_state.state == NPC_RUNNING) {
			difftest_step(commit.pc, commit.skip_ref);
		}
#endif
		IFDEF(CONFIG_WATCHPOINT, if (npc_state.state == NPC_RUNNING) diff_wp(commit.pc));

		if (npc_state.state == NPC_RUNNING) {
			IFDEF(CONFIG_DEVICE, device_update());
			IFDEF(NVBOARD, nvboard_update());
			continue;
		}

		if (npc_state.state == NPC_END || npc_state.state == NPC_ABORT) {
			printf(ANSI_FG_CYAN "\n\nTotal cycle times = %llu, Total dynamic_insts = %llu\n\n" ANSI_NONE,
				(unsigned long long)cycle_times, (unsigned long long)dynamic_insts);
			IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_display(); PerformanceCounter_export_json());
			npc_report_state();
		}
		return;
	}

	if (npc_state.state == NPC_RUNNING) {
		npc_set_state(NPC_STOP, cpu.pc, 0);
	}
}
