#include <stdio.h>
#include <Vadder32.h>
#include <Vadder32___024root.h>
#include <assert.h>
#include <stdint.h>

Vadder32 dut;

int main() {
    dut.a = 0;
    dut.b = 0xfffffffe;
    dut.cin = 1;
    dut.eval();
    printf("cout = %d, result = 0x%08x\n", dut.cout, dut.result);

    return 0;
}