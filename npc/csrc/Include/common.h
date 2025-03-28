#ifndef COMMON_H
#define COMMON_H

#include "macro.h"
#include <stdint.h>

#define cycle  \
do { \
    dut.clock = 0;    \
    dut.eval();     \
    dut.clock = 1;    \
    dut.eval();     \
    cpu.pc = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc;  \
    for (int i = 0; i < 31; i++) {  \
        cpu.registerFile[i] = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__WBU_INTER__DOT__RF_INTER__DOT__register_file[i];    \
    }   \
} while(0) \


#define cpu_rst \
do {    \
    dut.reset = 1;    \
    dut.clock = 0;    \
    dut.eval();     \
    dut.clock = 1;    \
    dut.eval();     \
    dut.reset = 0;    \
    cpu.pc = dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc;  \
    iringbuf_load(cpu.pc, dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__pc_inst); \
} while(0) \

typedef MUXDEF(ISA64, uint64_t, uint32_t)   word_t;


#endif

