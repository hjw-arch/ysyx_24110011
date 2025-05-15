#include <stdio.h>
#include <VALU.h>
#include <VALU___024root.h>
#include <assert.h>
#include <stdint.h>

VALU dut;

int main() {
    dut.alu_op = 11;
    dut.left_data = 0xfffffffe;
    dut.right_data = 31;
    dut.eval();
    printf("result = 0x%08x\n", dut.result);

    return 0;
}