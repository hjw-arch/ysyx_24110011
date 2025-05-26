#ifndef COMMON_H
#define COMMON_H

#include "macro.h"
#include <stdint.h>

#define		RF_NUM			16

#define cycle  \
do { \
    dut.clock = 0;    \
    dut.eval();     \
	if (cpu.pc >= 0x00000000) {IFDEF(WAVE, Verilated::timeInc(1));		\
	IFDEF(WAVE, tfp.dump(Verilated::time()));}	\
    dut.clock = 1;    \
    dut.eval();     \
	if (cpu.pc >= 0x00000000) {IFDEF(WAVE, Verilated::timeInc(1));		\
	IFDEF(WAVE, tfp.dump(Verilated::time()));}	\
} while(0) \


#ifdef SOC

#define cpu_rst \
do {    \
    dut.reset = 1;    \
    for(int i = 0; i < 10; i++) cycle;\
    dut.reset = 0;    \
	for(int i = 0; i < 10; i++) cycle;\
    cpu.pc = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IFU__DOT__pc;  \
} while(0) \

#else

#define cpu_rst \
do {    \
    dut.reset = 1;    \
    for(int i = 0; i < 10; i++) cycle;\
    dut.reset = 0;    \
    cpu.pc = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IFU__DOT__pc;  \
} while(0) \

#endif


typedef MUXDEF(ISA64, uint64_t, uint32_t)   word_t;


#endif

