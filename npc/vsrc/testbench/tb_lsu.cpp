// lsu C++ Testbench
#include <verilated.h>
#include "Vlsu_wrapper.h"
#include <iostream>
#include <string>

int pass_cnt = 0, fail_cnt = 0;

void check_bit(const char* name, bool exp, bool act) {
    if (exp == act) { std::cout << "  [PASS] " << name << std::endl; pass_cnt++; }
    else { std::cout << "  [FAIL] " << name << "  期望=" << (exp?"1":"0") << "  实际=" << (act?"1":"0") << std::endl; fail_cnt++; }
}

void check_u32(const char* name, uint32_t exp, uint32_t act) {
    if (exp == act) { std::cout << "  [PASS] " << name << std::endl; pass_cnt++; }
    else { std::cout << "  [FAIL] " << name << "  期望=" << exp << "  实际=" << act << std::endl; fail_cnt++; }
}

static void tick(Vlsu_wrapper* dut) {
    dut->clk = 1; dut->eval();
    dut->clk = 0; dut->eval();
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vlsu_wrapper* dut = new Vlsu_wrapper;

    dut->clk = 0; dut->rst = 1; dut->valid_i = 0; dut->flush_i = 0;
    dut->ARREADY = 0; dut->RVALID = 0; dut->RLAST = 0;
    dut->RDATA = 0;   dut->RID = 0;   dut->RRESP = 0;
    dut->AWREADY = 0; dut->WREADY = 0;
    dut->BVALID = 0;  dut->BID = 0;   dut->BRESP = 0;
    dut->pc_i = 0; dut->inst_i = 0; dut->phys_rd_i = 0;
    dut->rs1_data_i = 0; dut->rs2_data_i = 0; dut->imm_i = 0;
    dut->pred_taken_i = 0; dut->rd_wen_i = 0;
    dut->alu_op_i = 0; dut->alu_src_i = 0; dut->cfi_type_i = 0; dut->br_cond_i = 0;
    dut->mem_cmd_i = 0; dut->csr_cmd_i = 0; dut->priv_redir_i = 0; dut->fence_i_i = 0;
    dut->rob_idx_i = 0;
    dut->eval();
    for (int i = 0; i < 3; i++) tick(dut);
    dut->rst = 0; dut->eval();

    std::cout << "\n=== lsu C++ 测试 ===" << std::endl;

    // 测试1: 非访存 — LSU 不 complete，ready=1（由顶层分流到 EXU）
    std::cout << "\n[测试1] 非访存指令不由 LSU complete" << std::endl;
    dut->valid_i = 1; dut->rob_idx_i = 5; dut->mem_cmd_i = 0;
    dut->eval();
    check_bit("complete_en", false, dut->complete_en_o);
    check_bit("ready",       true,  dut->ready_o);
    tick(dut);
    check_bit("complete_en after tick", false, dut->complete_en_o);

    // 测试2: Load 进入等待
    std::cout << "\n[测试2] Load 指令进入等待状态（AXI 不响应）" << std::endl;
    dut->valid_i = 1; dut->rob_idx_i = 6; dut->mem_cmd_i = 1; // MEM_LOAD
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0x100;
    dut->inst_i = 0x00002003; // LW form
    dut->rd_wen_i = 1; dut->phys_rd_i = 40;
    dut->eval();
    tick(dut);
    check_bit("ARVALID",     true,  dut->ARVALID);
    check_bit("ready (停)",  false, dut->ready_o);
    check_bit("complete_en", false, dut->complete_en_o);

    // 测试3: 完成一次 load（模拟 AXI 响应）
    std::cout << "\n[测试3] Load AXI 完成写回" << std::endl;
    // 保持 valid 可随意；LSU 已锁存
    dut->valid_i = 0;
    dut->ARREADY = 1; tick(dut); // accept AR
    dut->ARREADY = 0;
    // 给 R 响应
    for (int i = 0; i < 5 && !dut->complete_en_o; i++) {
        dut->RVALID = 1; dut->RLAST = 1; dut->RDATA = 0x11223344; dut->RRESP = 0;
        tick(dut);
    }
    check_bit("complete_en after R", true, dut->complete_en_o);
    check_u32("complete_idx", 6, dut->complete_idx_o);
    check_u32("complete_data", 0x11223344u, dut->complete_data_o);
    check_bit("complete_rd_wen", true, dut->complete_rd_wen_o);
    check_u32("complete_phys_rd", 40, dut->complete_phys_rd_o);
    check_bit("ready on complete", true, dut->ready_o);

    // 清 R
    dut->RVALID = 0; dut->RLAST = 0; tick(dut);

    // 测试4: flush 丢弃 in-flight complete
    std::cout << "\n[测试4] flush 丢弃 in-flight 完成" << std::endl;
    dut->valid_i = 1; dut->rob_idx_i = 7; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0; dut->rd_wen_i = 1; dut->phys_rd_i = 41;
    dut->eval(); tick(dut);
    check_bit("entered wait", false, dut->ready_o);
    dut->valid_i = 0;
    dut->flush_i = 1; tick(dut); dut->flush_i = 0;
    // 完成 AXI
    dut->ARREADY = 1; tick(dut); dut->ARREADY = 0;
    bool saw_complete = false;
    for (int i = 0; i < 8; i++) {
        dut->RVALID = 1; dut->RLAST = 1; dut->RDATA = 0xAABBCCDD;
        if (dut->complete_en_o) saw_complete = true;
        tick(dut);
        if (dut->complete_en_o) saw_complete = true;
    }
    check_bit("flushed load no complete", false, saw_complete);

    std::cout << "\n=== 测试汇总: " << pass_cnt << " 通过, " << fail_cnt << " 失败 ===" << std::endl;
    delete dut;
    return (fail_cnt == 0) ? 0 : 1;
}
