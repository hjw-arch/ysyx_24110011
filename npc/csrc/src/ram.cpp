#include "../Include/ram.h"
#include "../Include/log.h"
#include "../Include/sdb.h"
#include "../Include/cpu_exec.h"
#include "../Include/device.h"
#include "Vysyx___024root.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

uint8_t pmem[RAM_SIZE];

extern Vysyx dut;

void *guest_to_host(uint32_t addr) {
    return ((uint8_t *)pmem + addr - RAM_START_ADDR);
}

int pmem_read(int addr, int len) {
    uint32_t ret = 0;
    if (len == 0) len = 1;
    else if (len == 1) len = 2;
    else if (len == 3) len = 4;
    if (addr >= RAM_START_ADDR && addr <= RAM_END_ADDR) {
        switch (len) {
            case 1: // 1
                ret = *(uint8_t *)guest_to_host(addr);
                break;

            case 2: // 2
                ret = *(uint16_t *)guest_to_host(addr);
                break;

            case 4:
                ret = *(uint32_t *)guest_to_host(addr);
                break;

            default:
                return 0;
        }

        IFDEF(CONFIG_MTRACE, mtrace_read(dut.rootp->ysyx__DOT__pc, len == 0 ? 1 : (len == 1 ? 2 : 4), ret, 0));

        return ret;
    } else {
        IFDEF(CONFIG_DEVICE, ret = mmio_read(addr, len));
    }
    return ret;
}


void pmem_write(int addr, int data, int len) {
    // Assert((addr <= RAM_END_ADDR) && (addr >= RAM_START_ADDR), "Addr 0x%08x transbordered the boundary.", addr);
    if (len == 0) len = 1;
    else if (len == 1) len = 2;
    else if (len == 3) len = 4;
    if ((addr <= RAM_END_ADDR) && (addr >= RAM_START_ADDR)) {
        IFDEF(CONFIG_MTRACE, mtrace_write(addr, len == 0 ? 1 : len == 1 ? 2 : 4, data, 0));
        switch (len) {
            case 1: // 1
                *(uint8_t *)guest_to_host(addr) = data;
                return;

            case 2: // 2
                *(uint16_t *)guest_to_host(addr) = data;
                return;

            case 4: // 4
                *(uint32_t *)guest_to_host(addr) = data;
                return;

            default:
                Assert(0, "pmem_write error, input 'len' is %d", len);
                return;
        }
    } else {
        IFDEF(CONFIG_DEVICE, mmio_write(addr, len, data));
        return;
    }
}

// For DPI-C
static int flag = 1;
int fetch_inst(int pc) {
    if (flag == 1) {
        flag = 0;
        return 0;
    }
    uint32_t inst = pmem_read(pc, 4);
    return inst;
}
