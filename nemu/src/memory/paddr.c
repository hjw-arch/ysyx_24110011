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
static uint8_t FLASH[FLASH_SIZE] PG_ALIGN = {};
static uint8_t SDRAM[SDRAM_SIZE] PG_ALIGN = {};
static uint8_t SRAM[SRAM_SIZE] PG_ALIGN = {};
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

#ifdef CONFIG_SOC

#define VADDR_IN_FLASH(addr)		((addr) <= FLASH_END && (addr) >= FLASH_BASE)
#define VADDR_IN_SDRAM(addr)		((addr) <= SDRAM_END && (addr) >= SDRAM_BASE)
#define VADDR_IN_SRAM(addr)			((addr) <= SRAM_END && (addr) >= SRAM_BASE)

uint8_t* guest_to_host(paddr_t paddr) {
	if (VADDR_IN_FLASH(paddr)) return FLASH + paddr - FLASH_BASE;
	if (VADDR_IN_SDRAM(paddr)) return SDRAM + paddr - SDRAM_BASE;
	if (VADDR_IN_SRAM(paddr))  return SRAM  + paddr - SRAM_BASE;
	panic("Error ADDRESS");
	return 0;
}

#define HADDR_IN_FLASH(addr)		(&FLASH[FLASH_SIZE] - (haddr) < FLASH_SIZE)
#define HADDR_IN_SDRAM(addr)		(&SDRAM[SDRAM_SIZE] - (haddr) < SDRAM_SIZE)
#define HADDR_IN_SRAM(addr)			(&SRAM[SRAM_SIZE] - (haddr) < SRAM_SIZE)

paddr_t host_to_guest(uint8_t *haddr) {
	if (HADDR_IN_FLASH(haddr)) return haddr - FLASH + FLASH_BASE;
	if (HADDR_IN_SDRAM(haddr)) return haddr - SDRAM + SDRAM_BASE;
	if (HADDR_IN_SRAM(haddr))  return haddr - SRAM  + SRAM_BASE;
	panic("Error ADDRESS");
	return 0;
}

// 接管SOC的UART

#define UART_BASE 	0x10000000
#define UART_TX		(UART_BASE + 0x00)
#define UART_RX		(UART_BASE + 0x00)
#define UART_IER	(UART_BASE + 0x01)
#define UART_IIR	(UART_BASE + 0x02)
#define UART_FCR	(UART_BASE + 0x02)
#define UART_LCR	(UART_BASE + 0x03)
#define UART_MC		(UART_BASE + 0x04)
#define	UART_LSR	(UART_BASE + 0x05)
#define UART_MS		(UART_BASE + 0x06)

#define UART_LSB	(UART_BASE + 0x00)
#define UART_MSB	(UART_BASE + 0x01)

#define UART_FIFO_EMPTY_MASK	1 << 5
#define UART_DATA_READY			1 << 0

#define IN_UART(addr)	((addr) >= UART_BASE && (addr) <= UART_BASE + 0x10)

uint32_t delay;
uint32_t delay_flag = 0;
uint32_t sim_uart_read(uint32_t addr) {
	if (!delay_flag) {
		delay_flag = 1;
		delay = rand() % 2 + 2;		// 模拟UART的延迟，大概是这么多
		return 0;
	}

	if (delay != 0) {
		delay--;
		return 0;
	}

	if (delay == 0) {
		delay_flag = 0;
		if (addr == UART_LSR) return 0xffffffff;
	}

	return 0;
}

void sim_uart_write(uint32_t addr, word_t data) {
	if (addr == UART_TX) {
		printf("%c", (uint8_t)data);
	}
}


// 接管SOC的CLINT

#define IN_CLINT(addr)	((addr) == 0x02000000 || (addr) == 0x02000004)

#define CLINT_BASE		0x02000000

uint32_t sim_clint_read(uint32_t addr) {
	uint64_t us = get_time();
	
	if (addr == CLINT_BASE)  return (uint32_t)us;
	
	if (addr == CLINT_BASE + 4)  return (uint32_t)(us >> 32);
	
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
	if (IN_UART(addr)) printf("pmem_write, %x\n", addr);
    IFDEF(CONFIG_MTRACE, mtrace_write(addr, len, data, 0));
    host_write(guest_to_host(addr), len, data);
}

static void out_of_bound(paddr_t addr) {
#ifndef CONFIG_SOC
    panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
        addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
#endif
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
	IFDEF(CONFIG_SOC, if(IN_CLINT(addr)) return sim_clint_read(addr));
	IFDEF(CONFIG_SOC, if(IN_UART(addr)) return sim_uart_read(addr));
    out_of_bound(addr);
    return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
    if (likely(in_pmem(addr))) { pmem_write(addr, len, data); return; }
    IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data); return);
	IFDEF(CONFIG_SOC, if(IN_UART(addr)) {sim_uart_write(addr, (uint8_t)data); return;});
    out_of_bound(addr);
}
