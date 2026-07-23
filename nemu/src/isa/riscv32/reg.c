/***************************************************************************************
 * Copyright (c) 2014-2022 Zihao Yu, Nanjing University
 *
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#include <isa.h>
#include "local-include/reg.h"

const char *regs[] = {
    "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

#define R(i) gpr(i)

void isa_reg_display() {
    for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
        printf("%-15s0x%-20x%u\n", regs[i], R(i), R(i));
    }
    printf("%-15s0x%-20x0x%x\n", "pc", cpu.pc, cpu.pc);
    printf("%-15s0x%08x\n", "mstatus", cpu.mstatus);
    printf("%-15s0x%08x\n", "mtvec", cpu.mtvec);
    printf("%-15s0x%08x\n", "mepc", cpu.mepc);
    printf("%-15s0x%08x\n", "mcause", cpu.mcause);
}

// 根据寄存器的名称返回寄存器的值
word_t isa_reg_str2val(const char *s, bool *success) {
    if (strcmp(s, "pc") == 0) {
        return cpu.pc;
    }
    if (strcmp(s, "mstatus") == 0) return cpu.mstatus;
    if (strcmp(s, "mtvec") == 0) return cpu.mtvec;
    if (strcmp(s, "mepc") == 0) return cpu.mepc;
    if (strcmp(s, "mcause") == 0) return cpu.mcause;

    if (s[0] == 'x' || s[0] == 'X') {
        int reg_index = atoi(s+1);
        return R(reg_index);
    }

    for (int i = 0; i < MUXDEF(CONFIG_RVE, 16, 32); i++) {
        if (strcmp(s, regs[i]) == 0) {
            return R(i);
        }
    }

    printf(ANSI_FG_RED "Error, no such reg\n" ANSI_NONE);
    printf("$%s\n", s);
    printf(ANSI_FG_RED "^" ANSI_NONE);
    for (int i = 0; i < strlen(s); i++) {
        printf(ANSI_FG_RED "~" ANSI_NONE);
    }
    puts("");


    *success = false;
    return -1;
}
