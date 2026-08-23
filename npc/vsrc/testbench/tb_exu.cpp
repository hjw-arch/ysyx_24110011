// exu C++ Testbench
#include <verilated.h>
#include "Vexu_wrapper.h"
#include <iostream>
#include <iomanip>

int pass_cnt = 0, fail_cnt = 0;

void check_u32(const char* name, uint32_t exp, uint32_t act) {
    if (exp == act) {
        std::cout << "  [PASS] " << name << std::endl;
        pass_cnt++;
    } else {
        std::cout << "  [FAIL] " << name
                  << "  期望=0x" << std::hex << std::setw(8) << std::setfill('0') << exp
                  << "  实际=0x" << std::hex << std::setw(8) << std::setfill('0') << act
                  << std::dec << std::endl;
        fail_cnt++;
    }
}

void check_bit(const char* name, bool exp, bool act) {
    if (exp == act) {
        std::cout << "  [PASS] " << name << std::endl;
        pass_cnt++;
    } else {
        std::cout << "  [FAIL] " << name
                  << "  期望=" << (exp ? "1" : "0")
                  << "  实际=" << (act ? "1" : "0") << std::endl;
        fail_cnt++;
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vexu_wrapper* dut = new Vexu_wrapper;

    dut->valid_i = 0;

    std::cout << "\n=== exu C++ Testbench ===" << std::endl;

    // ========== 测试1: ADD ==========
    std::cout << "\n[测试1] ADD: 100 + 200 = 300" << std::endl;
    dut->valid_i = 1;
    dut->pc_i = 0x80000000; dut->inst_i = 0x00000033;
    dut->rob_idx_i = 1;     dut->phys_rd_i = 10;
    dut->rs1_data_i = 100;  dut->rs2_data_i = 200; dut->imm_i = 0;
    dut->pred_taken_i = 0;  dut->rd_wen_i = 1;
    dut->alu_op_i = 0b0000; dut->alu_src_i = 0b00;
    dut->cfi_type_i = 0b00; dut->br_cond_i = 0b00;
    dut->csr_cmd_i = 0; dut->priv_redir_i = 0; dut->fence_i_i = 0;
    dut->eval();
    check_bit("complete_en", true,  dut->complete_en_o);
    check_u32("complete_data", 300, dut->complete_data_o);
    check_bit("wakeup_en",    true,  dut->wakeup_en_o);
    check_u32("wakeup_preg",  10,   dut->wakeup_preg_o);

    // ========== 测试2: SUB ==========
    std::cout << "\n[测试2] SUB: 500 - 300 = 200" << std::endl;
    dut->rs1_data_i = 500; dut->rs2_data_i = 300;
    dut->rob_idx_i = 2;    dut->phys_rd_i = 11;
    dut->alu_op_i = 0b1000;
    dut->eval();
    check_u32("complete_data", 200, dut->complete_data_o);
    check_u32("wakeup_preg",   11,  dut->wakeup_preg_o);

    // ========== 测试3: ADDI ==========
    std::cout << "\n[测试3] ADDI: 50 + 25 = 75" << std::endl;
    dut->rs1_data_i = 50; dut->imm_i = 25;
    dut->rob_idx_i = 3;   dut->phys_rd_i = 12;
    dut->alu_op_i = 0b0000; dut->alu_src_i = 0b01;
    dut->eval();
    check_u32("complete_data", 75, dut->complete_data_o);

    // ========== 测试3.1: AUIPC ==========
    std::cout << "\n[测试3.1] AUIPC: PC + imm = 0x1000 + 0x2000" << std::endl;
    dut->pc_i = 0x1000; dut->imm_i = 0x2000;
    dut->alu_op_i = 0b0000; dut->alu_src_i = 0b11;
    dut->cfi_type_i = 0b00;
    dut->eval();
    check_u32("complete_data", 0x3000, dut->complete_data_o);

    // ========== 测试4: BEQ taken ==========
    std::cout << "\n[测试4] BEQ taken: 100 == 100，预测不跳 → redirect" << std::endl;
    dut->pc_i = 0x80001000; dut->rs1_data_i = 100; dut->rs2_data_i = 100; dut->imm_i = 0x100;
    dut->pred_taken_i = 0; dut->rd_wen_i = 0;
    dut->alu_op_i = 0b1000; dut->alu_src_i = 0b00;
    dut->cfi_type_i = 0b01; dut->br_cond_i = 0b00;   // CFI_BRANCH, BEQ
    dut->eval();
    check_bit("redirect_valid", true,       dut->redirect_valid_o);
    check_u32("redirect_addr",  0x80001100, dut->redirect_addr_o);
    check_bit("bpu_update_valid", true,     dut->bpu_update_valid_o);
    check_bit("bpu_update_taken", true,     dut->bpu_update_taken_o);
    check_u32("bpu_update_pc",   0x80001000, dut->bpu_update_pc_o);

    // ========== 测试5: BEQ not taken ==========
    std::cout << "\n[测试5] BEQ not taken: 100 != 200，预测跳 → redirect" << std::endl;
    dut->rs1_data_i = 100; dut->rs2_data_i = 200; dut->pred_taken_i = 1;
    dut->eval();
    check_bit("redirect_valid",   true,       dut->redirect_valid_o);
    check_u32("redirect_addr",    0x80001004, dut->redirect_addr_o);
    check_bit("bpu_update_taken", false,      dut->bpu_update_taken_o);

    // ========== 测试6: JAL 预测正确 ==========
    std::cout << "\n[测试6] JAL: PC=0x2000, offset=0x400，预测正确 → 无 redirect" << std::endl;
    dut->pc_i = 0x2000; dut->imm_i = 0x400;
    dut->phys_rd_i = 15; dut->rd_wen_i = 1;
    dut->cfi_type_i = 0b10; dut->pred_taken_i = 1; dut->alu_src_i = 0b10;  // CFI_JAL, PC_4
    dut->eval();
    check_u32("complete_data (PC+4)",  0x2004, dut->complete_data_o);
    check_bit("redirect_valid (无)",   false,  dut->redirect_valid_o);
    check_u32("bpu_update_target",     0x2400, dut->bpu_update_target_o);

    // ========== 测试7: JALR ==========
    std::cout << "\n[测试7] JALR: rs1=0x3000, imm=100" << std::endl;
    dut->pc_i = 0x5000; dut->rs1_data_i = 0x3000; dut->imm_i = 100;
    dut->phys_rd_i = 16;
    dut->cfi_type_i = 0b11; dut->alu_src_i = 0b01;  // CFI_JALR, RS1_IMM
    dut->eval();
    check_u32("complete_data (PC+4)", 0x5004, dut->complete_data_o);
    check_u32("redirect_addr",        0x3064, dut->redirect_addr_o);

    std::cout << "\n=== 测试汇总: " << pass_cnt << " 通过, " << fail_cnt << " 失败 ===" << std::endl;
    delete dut;
    return (fail_cnt == 0) ? 0 : 1;
}
