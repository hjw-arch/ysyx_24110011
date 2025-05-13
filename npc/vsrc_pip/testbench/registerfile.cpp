#include <stdio.h>
#include <Vregisterfile.h>
#include <Vregisterfile___024root.h>
#include <assert.h>

Vregisterfile dut;

void cycle() {
    dut.clk = 0; dut.eval();
    dut.clk = 1; dut.eval();
}

int main() {
    dut.we = 1;
    cycle();
    for (int i = 0; i < 32; i++) {
        dut.rd_addr = i;
        dut.rd_data = 32 - i;
        cycle();
    }

    dut.we = 0;
    cycle();

    for (int i = 0; i < 32; i++) {
        printf("%d\n", dut.rootp->registerfile__DOT__register_file[i]);
    }

    // for (int i = 0; i < 32; i++) {
    //     dut.rs1_addr = i;
    //     dut.rs2_addr = i;
    //     cycle();
    //     printf("reg%d: 0x%08x\n", i, dut.rs1_data);
    //     assert(i == 0 ? 1 : dut.rs1_data == 32 - i);
    //     assert(i == 0 ? 1 : dut.rs2_data == 32 - i);
    // }

    return 0;
}