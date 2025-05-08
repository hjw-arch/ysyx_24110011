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
#define CONFIG_MTRACE_START_ADDR    0x80000000
#define CONFIG_MTRACE_END_ADDR      0x87ffffff
void decode_elf();
void record_ftrace(uint32_t pc_now, uint32_t action, uint32_t pc_target);
void display_ftrace();

void mtrace_read(uint32_t addr, uint32_t len, uint32_t content, uint32_t is_record_fetch_pc);
void mtrace_write(uint32_t addr, uint32_t len, uint32_t content, uint32_t is_record_fetch_pc);

void iringbuf_load(MUXDEF(RV64, uint64_t addr, uint32_t addr), uint32_t inst);
void iringbuf_display();

// sdb
void sdb_cli_loop();
void init_sdb();

#endif
