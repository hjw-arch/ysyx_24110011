// lsu C++ Testbench
#include <verilated.h>
#include "Vlsu_wrapper.h"
#include <iostream>

int pass_cnt = 0, fail_cnt = 0;

void check_bit(const char* name, bool exp, bool act) {
    if (exp == act) { std::cout << "  [PASS] " << name << std::endl; pass_cnt++; }
    else { std::cout << "  [FAIL] " << name << "  期望=" << (exp?"1":"0") << "  实际=" << (act?"1":"0") << std::endl; fail_cnt++; }
}

void check_u32(const char* name, uint32_t exp, uint32_t act) {
    if (exp == act) { std::cout << "  [PASS] " << name << std::endl; pass_cnt++; }
    else { std::cout << "  [FAIL] " << name << "  期望=" << exp << "  实际=" << act << std::endl; fail_cnt++; }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vlsu_wrapper* dut = new Vlsu_wrapper;

    dut->clk = 0; dut->rst = 1; dut->valid_i = 0;
    dut->ARREADY = 0; dut->RVALID = 0; dut->RLAST = 0;
    dut->RDATA = 0;   dut->RID = 0;   dut->RRESP = 0;
    dut->AWREADY = 0; dut->WREADY = 0;
    dut->BVALID = 0;  dut->BID = 0;   dut->BRESP = 0;
    dut->eval();
    for (int i = 0; i < 3; i++) { dut->clk = 1; dut->eval(); dut->clk = 0; dut->eval(); }
    dut->rst = 0;

    std::cout << "\n=== lsu C++ 测试 ===" << std::endl;

    // ========== 测试1: 非访存指令透传 ==========
    std::cout << "\n[测试1] 非访存指令直接透传" << std::endl;
    dut->valid_i = 1; dut->rob_idx_i = 5; dut->mem_cmd_i = 0;
    dut->pc_i = 0; dut->inst_i = 0; dut->phys_rd_i = 0;
    dut->rs1_data_i = 100; dut->rs2_data_i = 0; dut->imm_i = 50;
    dut->pred_taken_i = 0; dut->rd_wen_i = 0;
    dut->alu_op_i = 0; dut->alu_src_i = 0; dut->cfi_type_i = 0; dut->br_cond_i = 0;
    dut->csr_cmd_i = 0; dut->priv_redir_i = 0; dut->fence_i_i = 0;
    dut->eval(); dut->clk = 1; dut->eval(); dut->clk = 0; dut->eval();
    check_bit("complete_en", true,  dut->complete_en_o);
    check_bit("ready",       true,  dut->ready_o);
    check_u32("complete_idx", 5,   dut->complete_idx_o);

    // ========== 测试2: Load 进入等待 ==========
    std::cout << "\n[测试2] Load 指令进入等待状态（AXI 不响应）" << std::endl;
    dut->valid_i = 1; dut->rob_idx_i = 6; dut->mem_cmd_i = 1;  // MEM_LOAD
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0x100;
    dut->inst_i = 0x00002000;  // funct3=010 → LW
    dut->eval(); dut->clk = 1; dut->eval(); dut->clk = 0; dut->eval();
    check_bit("ARVALID",     true,  dut->ARVALID);
    check_bit("ready (停)",  false, dut->ready_o);
    check_bit("complete_en", false, dut->complete_en_o);

    // ========== 测试3: 连续非访存指令 ==========
    std::cout << "\n[测试3] 连续非访存指令透传" << std::endl;
    dut->rst = 1; dut->valid_i = 0;
    for (int i = 0; i < 3; i++) { dut->clk = 1; dut->eval(); dut->clk = 0; dut->eval(); }
    dut->rst = 0; dut->eval();
    dut->clk = 1; dut->eval(); dut->clk = 0; dut->eval();

    for (int i = 0; i < 3; i++) {
        dut->valid_i = 1; dut->rob_idx_i = 10 + i; dut->mem_cmd_i = 0;
        dut->eval(); dut->clk = 1; dut->eval(); dut->clk = 0; dut->eval();
        std::string s = std::to_string(i);
        check_bit(("complete_en[" + s + "]").c_str(), true,    dut->complete_en_o);
        check_bit(("ready["      + s + "]").c_str(), true,    dut->ready_o);
        check_u32(("complete_idx[" + s + "]").c_str(), 10+i,  dut->complete_idx_o);
    }

    std::cout << "\n=== 测试汇总: " << pass_cnt << " 通过, " << fail_cnt << " 失败 ===" << std::endl;
    delete dut;
    return (fail_cnt == 0) ? 0 : 1;
}
