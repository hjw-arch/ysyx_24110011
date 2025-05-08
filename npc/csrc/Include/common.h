#ifndef COMMON_H
#define COMMON_H

#include "macro.h"
#include <stdint.h>

#ifdef SOC

#define PC 			dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc;
#define RF			dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__WBU_INTER__DOT__RF_INTER__DOT__register_file
#define INST		dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_inst
#define IFU_START	dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IFU__DOT__start

#else

#define PC			dut.rootp->ysyx__DOT__pc
#define RF			dut.rootp->ysyx__DOT__WBU_INTER__DOT__RF_INTER__DOT__register_file
#define INST		dut.rootp->inst
#define IFU_START	dut.rootp->ysyx__DOT__u_IFU__DOT__start

#endif

#define cycle  \
do { \
    dut.clock = 0;    \
    dut.eval();     \
    dut.clock = 1;    \
    dut.eval();     \
    cpu.pc = PC;  \
    for (int i = 0; i < 31; i++) {  \
        cpu.registerFile[i] = RF[i];    \
    }   \
} while(0) \


#ifdef SOC

#define cpu_rst \
do {    \
    dut.reset = 1;    \
    for(int i = 0; i < 10; i++) cycle;\
    dut.reset = 0;    \
	for(int i = 0; i < 10; i++) cycle;\
    cpu.pc = PC;  \
    iringbuf_load(cpu.pc, INST); \
} while(0) \

#else

#define cpu_rst \
do {    \
    dut.reset = 1;    \
    for(int i = 0; i < 10; i++) cycle;\
    dut.reset = 0;    \
    cpu.pc = PC;  \
    iringbuf_load(cpu.pc, INST); \
} while(0) \

#endif


typedef MUXDEF(ISA64, uint64_t, uint32_t)   word_t;


#endif

