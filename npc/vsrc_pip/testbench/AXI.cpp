#include <stdio.h>
#include <iostream>
#include <VAXI_TEST.h>
#include <VAXI_TEST___024root.h>
#include <assert.h>

#include "VAXI_TEST__Dpi.h"

using namespace std;

VAXI_TEST dut;

void cycle() {
    dut.clk = 0; dut.eval();
    dut.clk = 1; dut.eval();
}

void rst() {
    dut.rst = 1;
    cycle();
    dut.rst = 0;
    cycle();
}

int pmem_read(int addr, int len) {
    printf("\nReceived read instruction, addr: 0x%08x, len: %d\n", addr, len);
    return addr;
}

void pmem_write(int addr, int data, int len) {
    printf("\nReceived write instruction, addr: 0x%08x, data: 0x%08x, len: %d\n", addr, data, len);
    return;
}

int main() {
    rst();

    printf("state = %06x\n\n", dut.rootp->AXI_TEST__DOT__u_axi4_lite_master__DOT__state);
    printf("w_state = %06x\n\n", dut.rootp->AXI_TEST__DOT__u_SRAM__DOT__w_state);
    printf("wdone = %d\n\n", dut.rdone);
    printf("AWVALID = %d\nAWREADY = %d\nAWADDR = 0x%08x\n\nWVALID = %d\nWREADY = %d\nWDATA = 0x%08x\n\nBVALID = %d\nBREADY = %d\nwdone = %d\n\n", dut.rootp->AXI_TEST__DOT__AWVALID, dut._AWREADY, dut.waddr, dut.rootp->AXI_TEST__DOT__WVALID, dut._WREADY, dut.wdata, dut.rootp->AXI_TEST__DOT__BVALID, dut._BREADY, dut.wdone);
    

    dut.wen = 1;
    dut.ren = 0;
    dut.raddr = 0x1234567;
    dut.waddr = 0x123456, dut.wdata = 123456;
    dut.wmask = 15;

    puts("\n\nStart\n\n");

    int a;
    while(scanf("%d", &a) == 1) {
        cycle();
        printf("state = %06x\n\n", dut.rootp->AXI_TEST__DOT__u_axi4_lite_master__DOT__state);
        printf("w_state = %06x\n\n", dut.rootp->AXI_TEST__DOT__u_SRAM__DOT__w_state);
        printf("AWVALID = %d\nAWREADY = %d\nAWADDR = 0x%08x\n\nWVALID = %d\nWREADY = %d\nWDATA = 0x%08x\n\nBVALID = %d\nBREADY = %d\n\nwdone = %d\n\n", dut.rootp->AXI_TEST__DOT__AWVALID, dut._AWREADY, dut.waddr, dut.rootp->AXI_TEST__DOT__WVALID, dut._WREADY, dut.wdata, dut.rootp->AXI_TEST__DOT__BVALID, dut._BREADY, dut.wdone);
    }

    return 0;
}
