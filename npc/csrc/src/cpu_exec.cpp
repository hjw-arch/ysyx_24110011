#include "../Include/sdb.h"
#include "../Include/common.h"
#include "../Include/cpu_exec.h"
#include "../Include/log.h"
#include "../Include/common.h"
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

#define FTRACE_RECORD     record_ftrace(old_pc, old_inst == 0x8067 ? 1 : 0, cpu.pc)

cpu_t cpu;
uint32_t current_pc, current_inst;

uint32_t cpu_state = RUNNING;

uint64_t cycle_times = 0;
uint64_t dynamic_insts = 0;

// pip_fifo
// 为流水线阶段做一些调整
#define PIP_LEVEL		5

typedef struct {
	uint32_t pc;
	uint32_t inst;
} pip_info_t;

static pip_info_t pip_info[PIP_LEVEL];

static uint32_t r_ptr, w_ptr;

static void load_pip_info() {
	if (dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__idu_valid_i && !dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IDU__DOT__flush) {
		pip_info[w_ptr].pc = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IDU__DOT__pc;
		pip_info[w_ptr].inst = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IDU__DOT__inst;
		w_ptr = ++w_ptr % PIP_LEVEL;
	}
}

static pip_info_t get_pip_info() {
	pip_info_t temp = pip_info[r_ptr];
	r_ptr = ++r_ptr % PIP_LEVEL;
	return temp;
}

void PerformanceCounter_display();

void halt() {
    cpu_state = IDLE;

	Log("Get 'ebreak' instruction, program over.");
	
    printf(ANSI_FG_CYAN "\n\nTotle cycle times = %lu, Total dynamic_ints = %lu\n\n" ANSI_NONE, cycle_times, dynamic_insts);
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

	while (1) {

		if (dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__wbu_valid_i) {
			cycle;

			load_pip_info();
			cycle_times++;
		
			pip_info_t temp_pip_info = get_pip_info();
			cpu.pc = pip_info[r_ptr].pc;
			for (int i = 0; i < RF_NUM; i++) {
				cpu.registerFile[i] = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_WBU__DOT__u_registerfile__DOT__register_file[i];
			}
			current_inst = temp_pip_info.inst;
			current_pc = temp_pip_info.pc;
			dynamic_insts++;
			if (current_inst == ebreak) {
				halt();
			}
			return;
		}

		cycle;

		load_pip_info();
		cycle_times++;
	
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
            disassemble(p, sizeof(p), cpu.pc, (uint8_t *)&current_inst, 4);
            printf("        %s\n", p);
        }


        IFDEF(CONFIG_ITRACE, iringbuf_load(cpu.pc, inst));

        IFDEF(CONFIG_FTRACE, FTRACE_RECORD);
        IFDEF(CONFIG_WATCHPOINT, diff_wp(cpu.pc));
		IFDEF(CONFIG_DIFFTEST, if (cpu_state != IDLE); difftest_step(cpu.pc));
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


