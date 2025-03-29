#include "../Include/sdb.h"
#include "../Include/common.h"
#include "../Include/cpu_exec.h"
#include "../Include/log.h"
#include "../Include/common.h"
#include "../Include/device.h"
#include "VysyxSoCFull___024root.h"
#include "../Include/difftest.h"

#define ebreak      0x00100073

#define min_num_to_disasm   10

#define FTRACE_RECORD     record_ftrace(old_pc, old_inst == 0x8067 ? 1 : 0, cpu.pc)

cpu_t cpu;

uint32_t cpu_state = RUNNING;

uint64_t cycle_times = 0;

void halt() {
    cpu_state = IDLE;

    printf("\n\nTotle cycle times = %lu\n\n", cycle_times);

    if (cpu.registerFile[10] != 0) {
        printf(ANSI_FG_RED "Hit bad trap" ANSI_NONE " at pc = 0x%08x\n", cpu.pc);
        return;
    } else {
        printf(ANSI_FG_GREEN "Hit good trap" ANSI_NONE " at pc = 0x%08x\n", cpu.pc);
        return;
    }
}

void cpu_exec_one() {
    
	do {
		cycle;
	} while(dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IFU__DOT__start != 1 && dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_inst != ebreak);

    cycle_times++;      // 测试CPU性能使用

    if (dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_inst == ebreak) {
        Log("Get 'ebreak' instruction, program over.");
        halt();
    }
}

void cpu_exec(uint32_t n) {
    if (cpu_state == IDLE) {
        Log("Program has over, if you want to restart, please enter 'q' and then restart again.");
        return;
    }

    for (int i = 0; i < n; ++i) {
		uint32_t old_pc = cpu.pc;

        // 执行一次
        cpu_exec_one();

        if (n < min_num_to_disasm) {
            char p[64];
            printf("0x%08x: ", old_pc);
            for(int j = 3; j >= 0; j--) {
                printf("%02x ", ((uint8_t *)&dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_inst)[j]);
            }
            disassemble(p, sizeof(p), cpu.pc, (uint8_t *)&dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_inst, 4);
            printf("        %s\n", p);
        }


        IFDEF(CONFIG_ITRACE, iringbuf_load(cpu.pc, dut.rootp->ysyx__DOT__inst));

        IFDEF(CONFIG_FTRACE, FTRACE_RECORD);
        IFDEF(CONFIG_WATCHPOINT, diff_wp(old_pc));
		if (cpu_state != IDLE) IFDEF(CONFIG_DIFFTEST, difftest_step(cpu.pc));
        IFDEF(CONFIG_DEVICE, device_update());

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
