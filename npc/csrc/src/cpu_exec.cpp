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

// 仿真契约：只读顶层展平信号（ysyx_24110011 中 public_flat_rd）
// 禁止再对 rob_commit_t / VlWide 做手算位域偏移；改字段请改 RTL 展平口
#ifdef SOC
#define CORE_SIG(name) dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__##name
#else
#define CORE_SIG(name) dut.rootp->ysyx__DOT__u_cpu__DOT__##name
#endif

#define COMMIT_PC()          CORE_SIG(commit_pc)
#define COMMIT_INST()        CORE_SIG(commit_inst)
#define COMMIT_VALID()       CORE_SIG(commit_valid)
#define COMMIT_RD_WEN()      CORE_SIG(commit_rd_wen)
#define COMMIT_ARCH_RD()     CORE_SIG(commit_arch_rd)
#define COMMIT_RESULT_ARCH() CORE_SIG(commit_result_arch)
// load AXI 完成或 store drain 完成（mtrace / difftest skip）
#define LSU_AXI_DONE()       CORE_SIG(u_lsu__DOT__axi_activity_done)

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

// 架构寄存器镜像：顺序 commit 时增量更新（DiffTest 等价全量同步）
// CSR 写回用 commit_result_arch（旧 CSR 值），普通指令用 ROB.result
static void sync_arch_state_on_commit() {
	cpu.pc = COMMIT_PC();
	if (COMMIT_RD_WEN()) {
		uint32_t rd = (uint32_t)COMMIT_ARCH_RD() & 0x1fu;
		if (rd != 0) {
			cpu.registerFile[rd] = COMMIT_RESULT_ARCH();
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
				"  last cpu.pc=0x%08x\n"
				"  ROB head=%u count=%u head_ready=%d\n"
				"  IQ valid=0x%02x issuable=0x%02x\n"
				"  LSU st=%u cam_stall=%d hold_flush=%d hold_addr=0x%08x hold_rob=%u\n"
				"  SQ cnt=%u commit_req=%d drain_req=%d ifu_pc=0x%08x\n",
				(unsigned long long)retire_cycles,
				(unsigned long long)cycle_times,
				(unsigned long long)dynamic_insts,
				(int)CORE_SIG(rob_flush),
				(int)CORE_SIG(exu_redirect_valid),
				cpu.pc,
				(unsigned)CORE_SIG(u_rob__DOT__rob_head),
				(unsigned)CORE_SIG(u_rob__DOT__rob_count),
				(int)CORE_SIG(u_rob__DOT__head_ready),
				(unsigned)CORE_SIG(u_iq__DOT__ent_valid),
				(unsigned)CORE_SIG(u_iq__DOT__ent_issuable),
				(unsigned)CORE_SIG(u_lsu__DOT__state),
				(int)CORE_SIG(u_lsu__DOT__cam_stall_block),
				(int)CORE_SIG(u_lsu__DOT__hold_flushed),
				(unsigned)CORE_SIG(u_lsu__DOT__hold_mem_addr),
				(unsigned)CORE_SIG(u_lsu__DOT__hold_rob_idx),
				(unsigned)CORE_SIG(u_sq__DOT__count),
				(int)CORE_SIG(sq_commit_req),
				(int)CORE_SIG(drain_req),
				(unsigned)CORE_SIG(u_ifu__DOT__pc_r));
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
