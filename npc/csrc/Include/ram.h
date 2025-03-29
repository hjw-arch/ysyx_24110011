#ifndef RAM_H
#define RAM_H

#include "config.h"
#include "common.h"
#include "macro.h"
#include <stdint.h>
#include "VysyxSoCFull.h"
#include "VysyxSoCFull__Dpi.h"
#include "VysyxSoCFull__Dpi.h"

#define RAM_START_ADDR  0x20000000
#define RAM_SIZE        0x8000000
#define RAM_END_ADDR    RAM_START_ADDR + RAM_SIZE - 1

#define RESET_VECTOR    RAM_START_ADDR + PC_RST_OFFSET

#define PAGE_SHIFT        12
#define PAGE_SIZE         (1ul << PAGE_SHIFT)
#define PAGE_MASK         (PAGE_SIZE - 1)

typedef word_t  vaddr_t;
typedef uint32_t  paddr_t;

void *guest_to_host(uint32_t addr);
int pmem_read(int addr, int len);
void pmem_write(int addr, int data, int len);

// For DPI-C
int fetch_inst(int pc);

#endif
