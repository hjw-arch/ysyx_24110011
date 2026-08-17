#include "../Include/sdb.h"
#include "../Include/common.h"
#include "../Include/cpu_exec.h"
#include "../Include/log.h"
#include "../Include/device.h"
#include "../Include/difftest.h"
#include "../Include/pmc.h"

#ifdef NVBOARD
#include "nvboard.h"
#endif

#ifdef SOC
#include "VysyxSoCFull___024root.h"
#else
#include "Vysyx___024root.h"
#endif

#define EBREAK_INST 0x00100073u
#define MIN_NUM_TO_DISASM 10

// rob_commit_t 字段在 VlWide<5> 中的低位偏移（packed struct，最低位 = 最后声明字段）
// inst: [31:0]  lo=0
// pc:   [63:32] lo=32
#define COMMIT_INST_LO  0
#define COMMIT_PC_LO   32

#define WIDE_U32(data, lo) \
	({ \
		const WData *const words = (data); \
		const int low = (lo); \
		(uint32_t)((((uint64_t)words[low / 32 + 1] << 32) | words[low / 32]) >> (low % 32)); \
	})

#ifdef SOC
#define CORE_SIG(name) dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__##name
#else
#define CORE_SIG(name) dut.rootp->ysyx__DOT__u_cpu__DOT__##name
#endif

// OoO 版本：通过 ROB commit 包获取提交的 pc/inst
#define COMMIT_PC()    WIDE_U32(CORE_SIG(commit_pkt).data(), COMMIT_PC_LO)
#define COMMIT_INST()  WIDE_U32(CORE_SIG(commit_pkt).data(), COMMIT_INST_LO)
#define COMMIT_VALID() CORE_SIG(commit_valid)
#define LSU_AXI_DONE() CORE_SIG(u_lsu__DOT__mem_resp_fire)

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
	bool is_load = CORE_SIG(u_lsu__DOT__input_is_load);
	uint8_t len = 1u << ((COMMIT_INST() >> 12) & 0x3);
	uint32_t data = is_load ? CORE_SIG(u_lsu__DOT__axi_rdata) : 0;
	mtrace_record(COMMIT_PC(), is_load, CORE_SIG(u_lsu__DOT__mem_addr), len, data);
}
#endif

static commit_info_t get_commit_info() {
	return {
		.pc   = COMMIT_PC(),
		.inst = COMMIT_INST(),
	};
}

// OoO 版本：架构寄存器状态从 physical_regfile 中读取。
// rename_map_table 维护 arch_reg → phys_reg 映射，但 Verilator 不直接暴露其内部数组，
// 因此利用 ROB commit 时更新的方式：每次 commit rd_wen 时将结果写入 cpu.registerFile。
// 对于 difftest，这样增量更新等同于完整同步（顺序提交保证）。
// rob_commit_t 从 LSB 起：inst, pc, redirect(33), sys(5), rd_wen(1), result(32),
// phys_rd_old(6), phys_rd(6), arch_rd(5), valid(1)
// result lo = 32(inst)+32(pc)+33(redirect)+5(sys)+1(rd_wen) = 103
// arch_rd lo = 103+32+6+6 = 147
#define COMMIT_RESULT_LO  103
#define COMMIT_RD_WEN_LO  102
#define COMMIT_ARCH_RD_LO 147

static uint32_t commit_result_u32() {
	return WIDE_U32(CORE_SIG(commit_pkt).data(), COMMIT_RESULT_LO);
}

static uint32_t commit_arch_rd_u32() {
	return WIDE_U32(CORE_SIG(commit_pkt).data(), COMMIT_ARCH_RD_LO) & 0x1fu;
}

static bool commit_rd_wen_b() {
	return (WIDE_U32(CORE_SIG(commit_pkt).data(), COMMIT_RD_WEN_LO) & 0x1u) != 0;
}

static void sync_arch_state_on_commit() {
	// 顺序提交：用 commit 结果增量更新架构寄存器镜像，供 ebreak/difftest
	cpu.pc = COMMIT_PC();
	if (commit_rd_wen_b()) {
		uint32_t rd = commit_arch_rd_u32();
		if (rd != 0) {
			cpu.registerFile[rd] = commit_result_u32();
		}
	}
}

static void exec_cycle() {
	bool axi_done = LSU_AXI_DONE();
	bool next_skip_ref = false;

#ifdef CONFIG_DIFFTEST
	next_skip_ref = axi_done && difftest_addr_needs_skip(CORE_SIG(u_lsu__DOT__mem_addr));
#endif

	IFDEF(CONFIG_MTRACE, if (axi_done) record_mtrace_lsu());
	IFDEF(CONFIG_PERFORMANCE_COUNTER,
		if (CORE_SIG(rob_flush)) PerformanceCounter_record_wbu_redirect();
		if (CORE_SIG(exu_redirect_valid)) PerformanceCounter_record_lsu_redirect();
		PerformanceCounter_record_cycle());
	cycle;
	IFDEF(NVBOARD, nvboard_update());
	cycle_times++;
	wbu_skip_ref = COMMIT_VALID() && next_skip_ref;
}

static commit_info_t cpu_exec_one() {
	uint64_t retire_cycles = 0;
	const uint64_t TIMEOUT_CYCLES = 100000;

	while (!COMMIT_VALID()) {
		exec_cycle();
		retire_cycles++;
		if (retire_cycles >= TIMEOUT_CYCLES) {
			fprintf(stderr,
				"[OoO TIMEOUT] no commit for %llu cycles\n"
				"  cycle_times=%llu dynamic_insts=%llu\n"
				"  rob_flush=%d exu_redirect_valid=%d\n"
				"  last cpu.pc=0x%08x\n",
				(unsigned long long)retire_cycles,
				(unsigned long long)cycle_times,
				(unsigned long long)dynamic_insts,
				(int)CORE_SIG(rob_flush),
				(int)CORE_SIG(exu_redirect_valid),
				cpu.pc);
			npc_set_state(NPC_ABORT, cpu.pc, -1);
			return {.pc = cpu.pc, .inst = 0, .skip_ref = false};
		}
	}

	// 在消费 commit 拍之前采样 commit 包（同步寄存器镜像）
	commit_info_t commit = get_commit_info();
	commit.skip_ref = wbu_skip_ref;
	sync_arch_state_on_commit();
	exec_cycle();   // 消费这个 commit 拍
	retire_cycles++;
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
			IFDEF(CONFIG_DEVICE, if (!(dynamic_insts & 0x3ff)) device_update());
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
