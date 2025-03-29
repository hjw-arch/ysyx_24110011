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

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#ifdef CONFIG_MTRACE
#include "../monitor/sdb/sdb.h"
#endif

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#elif  defined(CONFIG_SOC)
static uint8_t ROM[ROM_SIZE] PG_ALIGN = {};
static uint8_t SRAM[SRAM_SIZE] PG_ALIGN = {};
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

#ifdef CONFIG_SOC

uint8_t* guest_to_host(paddr_t paddr) {
	if ((paddr & ROM_MASK) == ROM_BASE) return ROM + paddr - ROM_BASE;
	if ((paddr & SRAM_MASK) == SRAM_BASE) return SRAM + paddr - SRAM_BASE;
	panic("Error ADDRESS");
	return 0;
}

paddr_t host_to_guest(uint8_t *haddr) { 
	if (&ROM[ROM_SIZE] - haddr < ROM_SIZE) return haddr - ROM + ROM_BASE;
	if (&SRAM[SRAM_SIZE] - haddr < SRAM_SIZE) return haddr - SRAM + SRAM_BASE;
	panic("Error ADDRESS");
	return 0;
}

#else
uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

#endif
static word_t pmem_read(paddr_t addr, int len) {
    word_t ret = host_read(guest_to_host(addr), len);
    IFDEF(CONFIG_MTRACE, mtrace_read(addr, len, ret, 0));
    return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
    IFDEF(CONFIG_MTRACE, mtrace_write(addr, len, data, 0));
    host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
    panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
        addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if  defined(CONFIG_PMEM_MALLOC)
    pmem = malloc(CONFIG_MSIZE);
    assert(pmem);
#endif

#ifndef CONFIG_SOC
    IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));     // 设置pmem初始值为随机值
    Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
#endif
}

word_t paddr_read(paddr_t addr, int len) {
    if (likely(in_pmem(addr))) return pmem_read(addr, len);
    IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
    out_of_bound(addr);
    return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
    if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
    IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
    out_of_bound(addr);
}
