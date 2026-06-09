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

#ifndef __SDB_H__
#define __SDB_H__

#include <common.h>

word_t expr(char *e, bool *success);

// watchpoint.c
void new_wp(char *expression);
void free_wp(int NO);
int diff_wp(vaddr_t front_pc);
void diaplay_wp();

// iringbuf
void iringbuf_load(MUXDEF(CONFIG_RV64, uint64_t addr, uint32_t addr), uint32_t inst);
void iringbuf_display();

void mtrace_load(vaddr_t addr, uint32_t len, word_t content);
void mtrace_store(vaddr_t addr, uint32_t len, word_t content);

void decode_elf();
void record_ftrace(uint32_t pc_now, uint32_t action, uint32_t pc_target);
void display_ftrace();

// dtrace
void record_dtrace(const char *name, bool isWrite);
void display_dtrace();

// etrace
void record_etrace(vaddr_t pc, uint32_t cause, uint32_t tvec);

#endif
