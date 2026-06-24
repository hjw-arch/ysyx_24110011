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

#define ebreak      0x00100073

#define min_num_to_disasm   10

#define EX2LS_PC_HI     204
#define EX2LS_PC_LO     173
#define LS2WB_PC_HI     102
#define LS2WB_PC_LO     71
#define LS2WB_INST_HI   70
#define LS2WB_INST_LO   39

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
	return get_wide_bits(CORE_SIG(ex2ls_data).data(), EX2LS_PC_HI, EX2LS_PC_LO);
}

static uint32_t get_wbu_pc() {
	return get_wide_bits(CORE_SIG(ls2wb_data).data(), LS2WB_PC_HI, LS2WB_PC_LO);
}

static uint32_t get_wbu_inst() {
	return get_wide_bits(CORE_SIG(ls2wb_data).data(), LS2WB_INST_HI, LS2WB_INST_LO);
}

static void record_lsu_redirect() {
	if (CORE_SIG(ls2wb_valid) && get_wbu_inst() == ebreak) {
		return;
	}

	if (CORE_SIG(lsu_redirect_valid)) {
		pending_redirect.pc = get_lsu_pc();
		pending_redirect.target = CORE_SIG(lsu_redirect_pc);
		pending_redirect.valid = true;
		IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_record_lsu_redirect());
	}
}

static void record_wbu_redirect() {
	if (CORE_SIG(wbu_redirect_valid)) {
		IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_record_wbu_redirect());
	}
}

static void record_lsu_difftest_skip() {
#if defined(SOC) && defined(CONFIG_DIFFTEST)
	bool mem_output_fire = CORE_SIG(u_LSU__DOT__output_fire) &
		(CORE_SIG(u_LSU__DOT__input_is_load) | CORE_SIG(u_LSU__DOT__input_is_store));

	if (mem_output_fire && !difftest_addr_is_pmem(CORE_SIG(u_LSU__DOT__lsu_addr))) {
		pending_difftest_skip.pc = get_wide_bits(CORE_SIG(ex2ls_data).data(), EX2LS_PC_HI, EX2LS_PC_LO);
		pending_difftest_skip.valid = true;
	}
#endif
}

static commit_info_t get_commit_info() {
	commit_info_t info;

	info.pc = get_wbu_pc();
	info.inst = get_wbu_inst();

	if (CORE_SIG(wbu_redirect_valid)) {
		info.next_pc = CORE_SIG(wbu_redirect_pc);
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

static void exec_one_cycle() {
	IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_record_cycle());
	cycle;
	cycle_times++;
}

void halt() {
    cpu_state = IDLE;

	Log("Get 'ebreak' instruction, program over.");
	
    printf(ANSI_FG_CYAN "\n\nTotal cycle times = %lu, Total dynamic_insts = %lu\n\n" ANSI_NONE, cycle_times, dynamic_insts);
	IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_display());
	IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_export_json());
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

		if (CORE_SIG(ls2wb_valid)) {
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
			IFDEF(CONFIG_PERFORMANCE_COUNTER, PerformanceCounter_record_commit(current_pc, current_inst, retire_cycles));
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
