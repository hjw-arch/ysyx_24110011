#ifndef SDB_H
#define SDB_H

#include <stdint.h>
#include "common.h"
#include "ram.h"
#include "config.h"

#ifdef SOC

#include "VysyxSoCFull.h"
extern VysyxSoCFull dut;

#else

#include "Vysyx.h"
extern Vysyx dut;

#endif

// disasm
extern "C" void init_disasm(const char *triple);
extern "C" void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);

// reg
void isa_reg_display();
word_t isa_reg_str2val(const char *s, bool *success);

// expr
void init_regex();
word_t expr(char *e, bool *success);

// watchpoint
void init_wp_pool();
void new_wp(char *expression);
void free_wp(int NO);
int diff_wp(vaddr_t front_pc);
void diaplay_wp();

// trace
void decode_elf();
void ftrace_record(uint32_t pc, uint32_t inst);
void display_ftrace();

extern "C" void mtrace_record(uint32_t pc, uint8_t is_load, uint32_t addr,
                                uint8_t len, uint32_t data);
void display_mtrace();

void record_dtrace(const char *name, uint32_t addr, uint8_t access,
                   uint32_t data, bool is_write);
void display_dtrace();

void iringbuf_load(word_t addr, uint32_t inst);
void iringbuf_display();

// sdb
void sdb_cli_loop();
void init_sdb();

#endif
