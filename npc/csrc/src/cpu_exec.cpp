#include "../Include/sdb.h"
#include "../Include/common.h"
#include "../Include/cpu_exec.h"
#include "../Include/log.h"
#include "../Include/device.h"
#include "../Include/difftest.h"

#ifdef SOC

#include "VysyxSoCFull___024root.h"

#else

#include "Vysyx___024root.h"

#endif

#ifdef WAVE

#include "verilated_vcd_c.h"
extern VerilatedVcdC tfp;

#endif


#define ebreak      0x00100073

#define min_num_to_disasm   10

#define FTRACE_RECORD     record_ftrace(current_pc, current_inst == 0x8067 ? 1 : 0, cpu.pc)

#ifdef SOC
#define CORE_SIG(name) dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__##name
#else
#define CORE_SIG(name) dut.rootp->ysyx__DOT__u_cpu__DOT__##name
#endif

cpu_t cpu;
uint32_t current_pc, current_inst;

uint32_t cpu_state = RUNNING;

uint64_t cycle_times = 0;
uint64_t dynamic_insts = 0;

void PerformanceCounter_display();
void PerformanceCounter_record_cycle(
	uint32_t pc,
	bool wbu_valid,
	uint32_t wbu_pc,
	bool ifu_req_valid,
	bool ifu_req_ready,
	bool ifu_resp_valid,
	bool ifu_resp_ready,
	bool ifu_flush,
	bool icache_req_hit,
	bool icache_req_miss,
	bool icache_miss_busy,
	bool icache_drop_refill,
	bool icache_invalidate,
	bool lsu_mem_req_fire,
	bool lsu_input_is_load,
	bool lsu_input_is_store,
	bool lsu_state_busy,
	bool hazard_valid,
	bool rs1_block_ex,
	bool rs2_block_ex,
	bool rs1_block_ls,
	bool rs2_block_ls,
	bool ex_is_load,
	bool ex_is_csr,
	bool ls_is_csr,
	bool ls_can_wb,
	bool idu_valid,
	uint8_t fwd_rs1_sel,
	uint8_t fwd_rs2_sel,
	bool rf_rs1_bypass,
	bool rf_rs2_bypass
);
void PerformanceCounter_record_lsu_redirect(
	uint32_t pc,
	uint32_t target,
	uint32_t inst,
	bool kill_if,
	bool kill_id,
	bool kill_ex,
	bool icache_miss_busy
);
void PerformanceCounter_record_wbu_redirect(
	uint32_t pc,
	uint32_t target,
	uint32_t inst,
	bool kill_if,
	bool kill_id,
	bool kill_ex,
	bool kill_ls,
	bool icache_miss_busy
);
void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles);

typedef struct {
	uint32_t pc;
	uint32_t inst;
	uint32_t next_pc;
} commit_info_t;

typedef struct {
	uint32_t pc;
	uint32_t target;
	bool valid;
} redirect_info_t;

typedef struct {
	uint32_t pc;
	bool valid;
} skip_info_t;

static redirect_info_t pending_redirect = {};
static skip_info_t pending_difftest_skip = {};
static bool current_difftest_skip = false;

static uint32_t get_wide_bits(const WData *data, int hi, int lo) {
	uint32_t value = 0;
	for (int bit = lo; bit <= hi; bit++) {
		if (data[bit / 32] & (1u << (bit % 32))) {
			value |= 1u << (bit - lo);
		}
	}
	return value;
}

static bool addr_in_range(uint32_t addr, uint32_t base, uint32_t size) {
	return addr - base < size;
}

static bool difftest_addr_is_pmem(uint32_t addr) {
#ifdef SOC
	return addr_in_range(addr, 0x30000000u, 0x10000000u) ||  // flash
	       addr_in_range(addr, 0x0f000000u, 0x00002000u) ||  // SRAM
	       addr_in_range(addr, 0xa0000000u, 0x02000000u);    // SDRAM
#else
	return addr_in_range(addr, RESET_VECTOR, RAM_SIZE);
#endif
}

static uint32_t get_lsu_pc() {
	return get_wide_bits(CORE_SIG(lsu_data_i).data(), 168, 137);
}

static uint32_t get_lsu_inst() {
	return get_wide_bits(CORE_SIG(lsu_data_i).data(), 136, 105);
}

static uint32_t get_wbu_pc() {
	return get_wide_bits(CORE_SIG(wbu_data_i).data(), 101, 70);
}

static uint32_t get_wbu_inst() {
	return get_wide_bits(CORE_SIG(wbu_data_i).data(), 69, 38);
}

static void record_lsu_redirect() {
	if (CORE_SIG(lsu_flush)) {
		pending_redirect.pc = get_lsu_pc();
		pending_redirect.target = CORE_SIG(lsu_pc_target);
		pending_redirect.valid = true;
		IFDEF(PERFORMANCE_COUNTER, PerformanceCounter_record_lsu_redirect(
			pending_redirect.pc,
			pending_redirect.target,
			get_lsu_inst(),
			CORE_SIG(ifu_valid_o),
			CORE_SIG(idu_valid_i),
			CORE_SIG(exu_valid_i),
			CORE_SIG(u_IFU__DOT__u_icache__DOT__state)
		));
	}
}

static void record_wbu_redirect() {
	if (CORE_SIG(wbu_flush)) {
		IFDEF(PERFORMANCE_COUNTER, PerformanceCounter_record_wbu_redirect(
			get_wbu_pc(),
			CORE_SIG(wbu_pc_target),
			get_wbu_inst(),
			CORE_SIG(ifu_valid_o),
			CORE_SIG(idu_valid_i),
			CORE_SIG(exu_valid_i),
			CORE_SIG(lsu_valid_i),
			CORE_SIG(u_IFU__DOT__u_icache__DOT__state)
		));
	}
}

static void record_lsu_difftest_skip() {
#ifdef SOC
	bool mem_output_fire = CORE_SIG(u_LSU__DOT__output_fire) &
		(CORE_SIG(u_LSU__DOT__input_is_load) | CORE_SIG(u_LSU__DOT__input_is_store));

	if (mem_output_fire && !difftest_addr_is_pmem(CORE_SIG(u_LSU__DOT__lsu_addr))) {
		pending_difftest_skip.pc = get_wide_bits(CORE_SIG(lsu_data_i).data(), 168, 137);
		pending_difftest_skip.valid = true;
	}
#endif
}

static commit_info_t get_commit_info() {
	commit_info_t info;

	info.pc = get_wbu_pc();
	info.inst = get_wbu_inst();

	if (CORE_SIG(wbu_flush)) {
		info.next_pc = CORE_SIG(wbu_pc_target);
	} else if (pending_redirect.valid && pending_redirect.pc == info.pc) {
		info.next_pc = pending_redirect.target;
		pending_redirect.valid = false;
	} else {
		info.next_pc = info.pc + 4;
	}

	return info;
}

static bool take_difftest_skip(uint32_t pc) {
	bool skip = pending_difftest_skip.valid && pending_difftest_skip.pc == pc;

	if (skip) {
		pending_difftest_skip.valid = false;
	}

	return skip;
}

static void record_performance_cycle() {
	IFDEF(PERFORMANCE_COUNTER, PerformanceCounter_record_cycle(
		CORE_SIG(u_IFU__DOT__pc_r),
		CORE_SIG(wbu_valid_i),
		get_wbu_pc(),
		CORE_SIG(u_IFU__DOT__ic_req_valid),
		CORE_SIG(u_IFU__DOT__ic_req_ready),
		CORE_SIG(u_IFU__DOT__ic_resp_valid),
		CORE_SIG(u_IFU__DOT__ic_resp_ready),
		CORE_SIG(u_IFU__DOT__flush_i),
		CORE_SIG(u_IFU__DOT__u_icache__DOT__req_hit),
		CORE_SIG(u_IFU__DOT__u_icache__DOT__req_miss),
		CORE_SIG(u_IFU__DOT__u_icache__DOT__state),
		CORE_SIG(u_IFU__DOT__u_icache__DOT__refill_resp_fire) & CORE_SIG(u_IFU__DOT__u_icache__DOT__drop_refill),
		CORE_SIG(u_IFU__DOT__inval_icache_i),
		CORE_SIG(u_LSU__DOT__mem_req_fire),
		CORE_SIG(u_LSU__DOT__input_is_load),
		CORE_SIG(u_LSU__DOT__input_is_store),
		CORE_SIG(u_LSU__DOT__state_busy),
		CORE_SIG(hazard_valid),
		CORE_SIG(u_hazard_unit__DOT__rs1_block_ex),
		CORE_SIG(u_hazard_unit__DOT__rs2_block_ex),
		CORE_SIG(u_hazard_unit__DOT__rs1_block_ls),
		CORE_SIG(u_hazard_unit__DOT__rs2_block_ls),
		CORE_SIG(ex_is_load),
		CORE_SIG(ex_is_csr),
		CORE_SIG(ls_is_csr),
		CORE_SIG(ls_can_wb),
		CORE_SIG(idu_valid_i),
		CORE_SIG(fwd_rs1_sel),
		CORE_SIG(fwd_rs2_sel),
		CORE_SIG(u_WBU__DOT__u_registerfile__DOT__rs1_bypass),
		CORE_SIG(u_WBU__DOT__u_registerfile__DOT__rs2_bypass)
	));
}

static void exec_one_cycle() {
	record_performance_cycle();
	cycle;
	cycle_times++;
}

void halt() {
    cpu_state = IDLE;

	Log("Get 'ebreak' instruction, program over.");
	
    printf(ANSI_FG_CYAN "\n\nTotal cycle times = %lu, Total dynamic_insts = %lu\n\n" ANSI_NONE, cycle_times, dynamic_insts);
	IFDEF(PERFORMANCE_COUNTER, PerformanceCounter_display());
    if (cpu.registerFile[10] != 0) {
        printf(ANSI_FG_RED "Hit bad trap" ANSI_NONE " at pc = 0x%08x\n", cpu.pc);
        return;
    } else {
        printf(ANSI_FG_GREEN "Hit good trap" ANSI_NONE " at pc = 0x%08x\n", cpu.pc);
        return;
    }
}

#ifdef NVBOARD

#include "nvboard.h"

#endif

void cpu_exec_one() {

	uint64_t retire_cycles = 0;

	while (1) {
		record_lsu_redirect();
		record_wbu_redirect();
		record_lsu_difftest_skip();

		if (CORE_SIG(wbu_valid_i)) {
			commit_info_t commit_info = get_commit_info();
			current_difftest_skip = take_difftest_skip(commit_info.pc);

			exec_one_cycle();
			retire_cycles++;
		
			for (int i = 0; i < RF_NUM; i++) {
				cpu.registerFile[i] = CORE_SIG(u_WBU__DOT__u_registerfile__DOT__register_file)[i];
			}
			cpu.pc = commit_info.next_pc;
			current_inst = commit_info.inst;
			current_pc = commit_info.pc;
			dynamic_insts++;
			IFDEF(PERFORMANCE_COUNTER, PerformanceCounter_record_commit(current_pc, current_inst, retire_cycles));
			if (current_inst == ebreak) {
				halt();
			}
			return;
		}

		exec_one_cycle();
		retire_cycles++;
	
	}
}

void cpu_exec(uint32_t n) {
    if (cpu_state == IDLE) {
        Log("Program has over, if you want to restart, please enter 'q' and then restart again.");
        return;
    }

    for (int i = 0; i < n; ++i) {

        // 执行一次
        cpu_exec_one();

        if (n < min_num_to_disasm) {
            char p[64];
            printf("0x%08x: ", current_pc);
            for(int j = 3; j >= 0; j--) {
                printf("%02x ", ((uint8_t *)&current_inst)[j]);
            }
            disassemble(p, sizeof(p), current_pc, (uint8_t *)&current_inst, 4);
            printf("        %s\n", p);
        }


        IFDEF(CONFIG_ITRACE, iringbuf_load(current_pc, current_inst));

        IFDEF(CONFIG_FTRACE, FTRACE_RECORD);
        IFDEF(CONFIG_WATCHPOINT, diff_wp(current_pc));
#ifdef CONFIG_DIFFTEST
		if (current_difftest_skip) difftest_skip_ref();
		if (cpu_state != IDLE) difftest_step(current_pc);
#endif
        IFDEF(CONFIG_DEVICE, device_update());
		IFDEF(NVBOARD, nvboard_update());

        if (cpu_state != RUNNING) {
            switch (cpu_state) {
                case IDLE:
                    IFDEF(CONFIG_ITRACE, iringbuf_display());
                    return;
                case STOPPED:
                    return;
                case QUIT:
                    return;
            }
        }
    }
}
