#include <stdio.h>
#include "../Include/sdb.h"
#include "../Include/cpu_exec.h"
#include "../Include/log.h"

uint32_t is_reg_index_valid(uint32_t index) {
    Assert(index < RF_NUM, "Error reg index: %d", index);
    return cpu.registerFile[index];
}

#define R(i) is_reg_index_valid(i)

const char *regs[] = {
    "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

void isa_reg_display() {
    for (int i = 0; i < RF_NUM; i++) {
        printf("%-15s0x%-20x%u\n", regs[i], R(i), R(i));
    }
    printf("%-15s0x%-20x0x%x\n", "pc", cpu.pc, cpu.pc);
}

// 根据寄存器的名称返回寄存器的值
word_t isa_reg_str2val(const char *s, bool *success) {
    if (strcmp(s, "pc") == 0) {
        return cpu.pc;
    }

    if (s[0] == 'x' || s[0] == 'X') {
        int reg_index = atoi(s+1);
        return R(reg_index);
    }

    for (int i = 0; i < RF_NUM; i++) {
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
