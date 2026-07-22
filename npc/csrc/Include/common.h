#ifndef COMMON_H
#define COMMON_H

#include "macro.h"
#include "config.h"
#include <stdint.h>

#define		RF_NUM			    MUXDEF(CONFIG_RVE, 16, 32)
#define     CPU_RESET_VECTOR    (MUXDEF(SOC, 0x30000000u, 0x80000000u) + CONFIG_PC_RST_OFFSET)

void wave_dump();

#define cycle  \
do { \
    dut.clock = 0;    \
    dut.eval();     \
	IFDEF(CONFIG_WAVE, wave_dump()); \
    dut.clock = 1;    \
    dut.eval();     \
	IFDEF(CONFIG_WAVE, wave_dump()); \
} while(0) \


#ifdef SOC

#define cpu_rst \
do {    \
    dut.reset = 1;    \
    for(int i = 0; i < 10; i++) cycle;\
    dut.reset = 0;    \
	for(int i = 0; i < 10; i++) cycle;\
    cpu.pc = CPU_RESET_VECTOR;  \
} while(0) \

#else

#define cpu_rst \
do {    \
    dut.reset = 1;    \
    for(int i = 0; i < 10; i++) cycle;\
    dut.reset = 0;    \
    cpu.pc = CPU_RESET_VECTOR;  \
} while(0) \

#endif


typedef MUXDEF(ISA64, uint64_t, uint32_t)   word_t;


#endif
