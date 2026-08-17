// lsu C++ Testbench（Tier2：load AXI + store→SQ，不写总线）
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
    dut->sq_alloc_ready_i = 1;
    dut->sq_empty_i = 1;
    dut->drain_req_i = 0;
    dut->drain_addr_i = 0; dut->drain_data_i = 0; dut->drain_strb_i = 0; dut->drain_size_i = 0;
    dut->eval();
    for (int i = 0; i < 3; i++) tick(dut);
    dut->rst = 0; dut->eval();

    std::cout << "\n=== lsu C++ 测试 ===" << std::endl;

    // 测试1: 非访存
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

    // 测试3: Load AXI 完成
    std::cout << "\n[测试3] Load AXI 完成写回" << std::endl;
    dut->valid_i = 0;
    dut->ARREADY = 1; tick(dut);
    dut->ARREADY = 0;
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
    dut->RVALID = 0; tick(dut);

    // 测试4: flush 丢弃 in-flight load
    std::cout << "\n[测试4] flush 丢弃 in-flight 完成" << std::endl;
    dut->valid_i = 1; dut->rob_idx_i = 7; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0;
    dut->rd_wen_i = 1; dut->phys_rd_i = 41;
    dut->eval(); tick(dut);
    check_bit("entered wait", true, dut->ARVALID || !dut->ready_o);
    dut->valid_i = 0; dut->flush_i = 1; tick(dut); dut->flush_i = 0;
    dut->ARREADY = 1; tick(dut); dut->ARREADY = 0;
    for (int i = 0; i < 5; i++) {
        dut->RVALID = 1; dut->RLAST = 1; dut->RDATA = 0xdeadbeef; dut->RRESP = 0;
        tick(dut);
    }
    check_bit("flushed load no complete", false, dut->complete_en_o);
    dut->RVALID = 0; tick(dut);

    // 测试5: Store 入 SQ，不拉 AWVALID
    std::cout << "\n[测试5] Store issue 入 SQ，不发起 AXI 写" << std::endl;
    dut->sq_alloc_ready_i = 1;
    dut->valid_i = 1; dut->rob_idx_i = 8; dut->mem_cmd_i = 2; // MEM_STORE
    dut->rs1_data_i = 0x80001000; dut->imm_i = 0; dut->rs2_data_i = 0xA5A5A5A5;
    dut->inst_i = 0x00a02023; // sw
    dut->rd_wen_i = 0; dut->phys_rd_i = 0;
    dut->eval();
    check_bit("sq_alloc_en", true, dut->sq_alloc_en_o);
    check_bit("complete_en store", true, dut->complete_en_o);
    check_bit("AWVALID store issue", false, dut->AWVALID);
    tick(dut);
    dut->valid_i = 0;

    // 测试6: SQ 非空时 load 不得发 AXI
    std::cout << "\n[测试6] SQ 非空时 load 不得发 AXI" << std::endl;
    dut->sq_empty_i = 0;
    dut->valid_i = 1; dut->rob_idx_i = 9; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0;
    dut->rd_wen_i = 1; dut->phys_rd_i = 42;
    dut->eval();
    check_bit("ARVALID blocked", false, dut->ARVALID);
    check_bit("ready blocked",   false, dut->ready_o);
    check_bit("complete blocked", false, dut->complete_en_o);
    dut->valid_i = 0; dut->sq_empty_i = 1; tick(dut);

    // 测试7: drain 发起写
    std::cout << "\n[测试7] commit drain 发起 AXI 写" << std::endl;
    dut->drain_req_i = 1;
    dut->drain_addr_i = 0x80001000;
    dut->drain_data_i = 0xA5A5A5A5;
    dut->drain_strb_i = 0xF;
    dut->drain_size_i = 2;
    dut->eval();
    tick(dut);
    check_bit("drain_fire", true, dut->drain_fire_o || dut->AWVALID);
    dut->AWREADY = 1; dut->WREADY = 1;
    for (int i = 0; i < 8 && !dut->drain_done_o; i++) {
        if (dut->BREADY) { dut->BVALID = 1; dut->BRESP = 0; }
        tick(dut);
    }
    check_bit("drain_done", true, dut->drain_done_o);
    dut->drain_req_i = 0; dut->BVALID = 0;
    tick(dut);

    // 测试8: load 等待期间 data_i 被 EXU issue 覆盖时，地址/字节选取仍应稳定
    // 背景：axi4_full_master 的 ARADDR 与 rdata 选字节均直通 raddr，不锁存；
    // 顶层 iq_issue_ready 对非 mem 恒 1，LSU busy 时 EXU 仍可 issue，data_i 会变。
    std::cout << "\n[测试8] load 等待期间 data_i 变化，结果仍正确（hold）" << std::endl;
    // 整核复位，避免前序 AXI/LSU 状态机污染
    dut->rst = 1;
    dut->valid_i = 0; dut->flush_i = 0; dut->drain_req_i = 0;
    dut->ARREADY = 0; dut->RVALID = 0; dut->RLAST = 0; dut->RDATA = 0;
    dut->AWREADY = 0; dut->WREADY = 0; dut->BVALID = 0;
    dut->sq_empty_i = 1; dut->sq_alloc_ready_i = 1;
    dut->rs1_data_i = 0; dut->rs2_data_i = 0; dut->imm_i = 0;
    dut->inst_i = 0; dut->mem_cmd_i = 0; dut->rd_wen_i = 0;
    for (int i = 0; i < 4; i++) tick(dut);
    dut->rst = 0; tick(dut);

    dut->valid_i = 1; dut->rob_idx_i = 10; dut->mem_cmd_i = 1;
    // LBU addr = 0x80000001，期望取 RDATA 的 byte1 = 0x33
    dut->rs1_data_i = 0x80000001; dut->imm_i = 0;
    dut->inst_i = 0x00004003; // lbu，funct3=100
    dut->rd_wen_i = 1; dut->phys_rd_i = 43;
    dut->eval();
    check_bit("ARVALID fire", true, dut->ARVALID);
    check_u32("ARADDR fire", 0x80000001u, dut->ARADDR);
    tick(dut); // 进入 S_LOAD，hold 锁存
    check_bit("ARVALID wait ARREADY", true, dut->ARVALID);
    check_u32("ARADDR before corrupt", 0x80000001u, dut->ARADDR);

    // 模拟 IQ 在 LSU 未 ready 时发射非 mem
    dut->valid_i = 0;
    dut->rs1_data_i = 0xDEADBEE0;
    dut->imm_i = 0x10;
    dut->inst_i = 0x00000013;
    dut->mem_cmd_i = 0;
    dut->eval();
    check_u32("ARADDR after corrupt", 0x80000001u, dut->ARADDR);

    dut->ARREADY = 1; tick(dut); dut->ARREADY = 0;
    for (int i = 0; i < 6 && !dut->complete_en_o; i++) {
        dut->RVALID = 1; dut->RLAST = 1;
        dut->RDATA = 0x11223344; // byte1 = 0x33
        dut->RRESP = 0;
        tick(dut);
    }
    check_bit("complete after hold load", true, dut->complete_en_o);
    check_u32("lbu data with hold", 0x33u, dut->complete_data_o);
    dut->RVALID = 0; tick(dut);

    // 测试9: drain 进入 S_DRAIN 后，AWSIZE/WSTRB 必须保持写 size
    // master 的 AWSIZE/WSTRB/WDATA 全程直通 size；若 LSU 仅在 wen 拍选 wsize，
    // 下一拍 size 回到 issue 口的 req_size（常为 0）→ 字写变字节写。
    std::cout << "\n[测试9] drain 等待 AWREADY 期间 AWSIZE 保持" << std::endl;
    dut->rst = 1;
    dut->valid_i = 0; dut->flush_i = 0; dut->drain_req_i = 0;
    dut->ARREADY = 0; dut->RVALID = 0; dut->AWREADY = 0; dut->WREADY = 0; dut->BVALID = 0;
    dut->sq_empty_i = 1; dut->sq_alloc_ready_i = 1;
    dut->mem_cmd_i = 0; dut->inst_i = 0; dut->rs1_data_i = 0; dut->imm_i = 0;
    for (int i = 0; i < 4; i++) tick(dut);
    dut->rst = 0; tick(dut);

    dut->drain_req_i = 1;
    dut->drain_addr_i = 0x80002000;
    dut->drain_data_i = 0xA1B2C3D4;
    dut->drain_strb_i = 0xF;
    dut->drain_size_i = 2; // SW
    dut->eval();
    // 发起拍：wen=1，应看到 AWSIZE=2、满 WSTRB
    check_bit("AWVALID drain fire", true, dut->AWVALID);
    check_u32("AWSIZE fire", 2u, (uint32_t)dut->AWSIZE);
    check_u32("WSTRB fire", 0xFu, (uint32_t)dut->WSTRB);
    tick(dut); // 进入 S_DRAIN；故意保持 AWREADY=0，并污染 issue 口
    dut->inst_i = 0x00000013; // funct3=0 → 若误用 req_size 则 size=0
    dut->rs1_data_i = 0x11111111;
    dut->eval();
    check_bit("AWVALID wait", true, dut->AWVALID);
    check_u32("AWSIZE hold in S_DRAIN", 2u, (uint32_t)dut->AWSIZE);
    check_u32("WSTRB hold in S_DRAIN", 0xFu, (uint32_t)dut->WSTRB);
    check_u32("AWADDR hold", 0x80002000u, dut->AWADDR);

    dut->AWREADY = 1; dut->WREADY = 1;
    for (int i = 0; i < 8 && !dut->drain_done_o; i++) {
        if (dut->BREADY) { dut->BVALID = 1; dut->BRESP = 0; }
        tick(dut);
    }
    check_bit("drain_done size-hold", true, dut->drain_done_o);
    dut->drain_req_i = 0; dut->BVALID = 0; tick(dut);

    std::cout << "\n=== 测试汇总: " << pass_cnt << " 通过, " << fail_cnt << " 失败 ===" << std::endl;
    delete dut;
    return (fail_cnt == 0) ? 0 : 1;
}
