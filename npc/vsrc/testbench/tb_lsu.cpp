// lsu C++ Testbench（Tier3-A：STLF / CAM stall / AXI load / drain）
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

static void full_rst(Vlsu_wrapper* dut) {
    dut->rst = 1;
    dut->valid_i = 0; dut->flush_i = 0; dut->drain_req_i = 0;
    dut->ARREADY = 0; dut->RVALID = 0; dut->RLAST = 0; dut->RDATA = 0;
    dut->AWREADY = 0; dut->WREADY = 0; dut->BVALID = 0;
    dut->sq_alloc_ready_i = 1;
    dut->cam_hit_i = 0; dut->cam_stall_i = 0; dut->cam_data_i = 0;
    dut->rs1_data_i = 0; dut->rs2_data_i = 0; dut->imm_i = 0;
    dut->inst_i = 0; dut->mem_cmd_i = 0; dut->rd_wen_i = 0;
    for (int i = 0; i < 4; i++) tick(dut);
    dut->rst = 0; tick(dut);
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
    dut->cam_hit_i = 0; dut->cam_stall_i = 0; dut->cam_data_i = 0;
    dut->drain_req_i = 0;
    dut->drain_addr_i = 0; dut->drain_data_i = 0; dut->drain_strb_i = 0; dut->drain_size_i = 0;
    dut->eval();
    for (int i = 0; i < 3; i++) tick(dut);
    dut->rst = 0; dut->eval();

    std::cout << "\n=== lsu C++ 测试 (Tier3-A) ===" << std::endl;

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
    dut->cam_hit_i = 0; dut->cam_stall_i = 0;
    dut->eval();
    tick(dut);
    check_bit("ARVALID",     true,  dut->ARVALID);
    check_bit("request buffer ready", true, dut->ready_o);
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
    // 请求缓冲为空，可在响应拍接受下一条访存请求。
    check_bit("request buffer ready on response", true, dut->ready_o);
    dut->RVALID = 0; tick(dut);

    // 测试4: flush 丢弃 in-flight load
    std::cout << "\n[测试4] flush 丢弃 in-flight 完成" << std::endl;
    dut->valid_i = 1; dut->rob_idx_i = 7; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0;
    dut->rd_wen_i = 1; dut->phys_rd_i = 41;
    dut->cam_hit_i = 0; dut->cam_stall_i = 0;
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
    tick(dut);
    dut->valid_i = 0;
    dut->eval();
    check_bit("sq_alloc_en", true, dut->sq_alloc_en_o);
    check_bit("complete_en store", true, dut->complete_en_o);
    check_bit("AWVALID store issue", false, dut->AWVALID);
    tick(dut);

    // 测试6: CAM stall 时 load 不得发 AXI
    std::cout << "\n[测试6] CAM stall 时 load 不得发 AXI" << std::endl;
    full_rst(dut);
    dut->cam_hit_i = 0; dut->cam_stall_i = 1; dut->cam_data_i = 0;
    dut->valid_i = 1; dut->rob_idx_i = 9; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0;
    dut->rd_wen_i = 1; dut->phys_rd_i = 42;
    dut->inst_i = 0x00002003;
    dut->eval();
    tick(dut);
    dut->valid_i = 0;
    dut->eval();
    check_bit("ARVALID blocked by stall", false, dut->ARVALID);
    check_bit("ready blocked by stall",   false, dut->ready_o);
    check_bit("complete blocked by stall", false, dut->complete_en_o);
    dut->cam_stall_i = 0; tick(dut);

    // 测试7: drain 发起写
    std::cout << "\n[测试7] commit drain 发起 AXI 写" << std::endl;
    full_rst(dut);
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

    // 测试8: load 等待期间 data_i 变化，结果仍正确（hold）
    std::cout << "\n[测试8] load 等待期间 data_i 变化，结果仍正确（hold）" << std::endl;
    full_rst(dut);
    dut->valid_i = 1; dut->rob_idx_i = 10; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000001; dut->imm_i = 0;
    dut->inst_i = 0x00004003; // lbu
    dut->rd_wen_i = 1; dut->phys_rd_i = 43;
    dut->cam_hit_i = 0; dut->cam_stall_i = 0;
    dut->eval();
    check_bit("request accepted", true, dut->ready_o);
    check_bit("ARVALID before request register", false, dut->ARVALID);
    tick(dut);
    dut->valid_i = 0;
    dut->eval();
    check_bit("ARVALID fire", true, dut->ARVALID);
    check_u32("ARADDR fire", 0x80000001u, dut->ARADDR);
    check_bit("ARVALID wait ARREADY", true, dut->ARVALID);
    check_u32("ARADDR before corrupt", 0x80000001u, dut->ARADDR);

    dut->rs1_data_i = 0xDEADBEE0;
    dut->imm_i = 0x10;
    dut->inst_i = 0x00000013;
    dut->mem_cmd_i = 0;
    dut->eval();
    check_u32("ARADDR after corrupt", 0x80000001u, dut->ARADDR);

    dut->ARREADY = 1; tick(dut); dut->ARREADY = 0;
    for (int i = 0; i < 6 && !dut->complete_en_o; i++) {
        dut->RVALID = 1; dut->RLAST = 1;
        dut->RDATA = 0x11223344;
        dut->RRESP = 0;
        tick(dut);
    }
    check_bit("complete after hold load", true, dut->complete_en_o);
    check_u32("lbu data with hold", 0x33u, dut->complete_data_o);
    dut->RVALID = 0; tick(dut);

    // 测试9: drain 等待 AWREADY 期间 AWSIZE 保持
    std::cout << "\n[测试9] drain 等待 AWREADY 期间 AWSIZE 保持" << std::endl;
    full_rst(dut);
    dut->drain_req_i = 1;
    dut->drain_addr_i = 0x80002000;
    dut->drain_data_i = 0xA1B2C3D4;
    dut->drain_strb_i = 0xF;
    dut->drain_size_i = 2;
    dut->eval();
    check_bit("AWVALID drain fire", true, dut->AWVALID);
    check_u32("AWSIZE fire", 2u, (uint32_t)dut->AWSIZE);
    check_u32("WSTRB fire", 0xFu, (uint32_t)dut->WSTRB);
    tick(dut);
    dut->inst_i = 0x00000013;
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

    // 测试10: STLF 全覆盖 — 无 ARVALID，同拍 complete
    std::cout << "\n[测试10] STLF 全覆盖：无 ARVALID，同拍 complete" << std::endl;
    full_rst(dut);
    dut->cam_hit_i = 1; dut->cam_stall_i = 0;
    dut->cam_data_i = 0x000000AAu; // 低位对齐后的字节
    dut->valid_i = 1; dut->rob_idx_i = 11; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000000; dut->imm_i = 0;
    dut->inst_i = 0x00004003; // lbu
    dut->rd_wen_i = 1; dut->phys_rd_i = 44;
    dut->eval();
    tick(dut);
    dut->valid_i = 0;
    dut->eval();
    check_bit("STLF no ARVALID", false, dut->ARVALID);
    check_bit("STLF complete", true, dut->complete_en_o);
    check_u32("STLF data", 0xAAu, dut->complete_data_o);
    check_bit("STLF ready", true, dut->ready_o);
    check_u32("STLF idx", 11u, dut->complete_idx_o);
    check_bit("STLF rd_wen", true, dut->complete_rd_wen_o);
    tick(dut);
    dut->cam_hit_i = 0;

    // 测试11: SQ 非空但不同字（cam none）→ 允许 AXI load
    std::cout << "\n[测试11] CAM none（不同字）允许 AXI load" << std::endl;
    full_rst(dut);
    dut->cam_hit_i = 0; dut->cam_stall_i = 0;
    dut->valid_i = 1; dut->rob_idx_i = 12; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80003000; dut->imm_i = 0;
    dut->inst_i = 0x00002003; // lw
    dut->rd_wen_i = 1; dut->phys_rd_i = 45;
    dut->eval();
    tick(dut);
    dut->valid_i = 0;
    dut->eval();
    check_bit("AXI load ARVALID with SQ nonempty-equivalent", true, dut->ARVALID);
    check_bit("AXI load not complete yet", false, dut->complete_en_o);
    dut->ARREADY = 1; tick(dut); dut->ARREADY = 0;
    for (int i = 0; i < 6 && !dut->complete_en_o; i++) {
        dut->RVALID = 1; dut->RLAST = 1; dut->RDATA = 0x55667788; dut->RRESP = 0;
        tick(dut);
    }
    check_bit("AXI load complete", true, dut->complete_en_o);
    check_u32("AXI load data", 0x55667788u, dut->complete_data_o);
    dut->RVALID = 0; tick(dut);

    // 测试12: STLF 可在 drain 期间完成（不占 AXI）
    std::cout << "\n[测试12] drain 期间 STLF 仍可 complete" << std::endl;
    full_rst(dut);
    // 启动 drain，保持 AWREADY=0 使 LSU 停在 S_DRAIN
    dut->drain_req_i = 1;
    dut->drain_addr_i = 0x80004000;
    dut->drain_data_i = 0x11111111;
    dut->drain_strb_i = 0xF;
    dut->drain_size_i = 2;
    dut->eval();
    tick(dut); // 进入 S_DRAIN
    check_bit("in drain AWVALID", true, dut->AWVALID);

    dut->cam_hit_i = 1; dut->cam_stall_i = 0;
    dut->cam_data_i = 0x00000055;
    dut->valid_i = 1; dut->rob_idx_i = 13; dut->mem_cmd_i = 1;
    dut->rs1_data_i = 0x80000004; dut->imm_i = 0;
    dut->inst_i = 0x00004003; // lbu
    dut->rd_wen_i = 1; dut->phys_rd_i = 46;
    dut->eval();
    tick(dut);
    dut->valid_i = 0;
    dut->eval();
    check_bit("STLF during drain no ARVALID", false, dut->ARVALID);
    check_bit("STLF during drain complete", true, dut->complete_en_o);
    check_u32("STLF during drain data", 0x55u, dut->complete_data_o);
    check_bit("STLF during drain ready", true, dut->ready_o);
    // drain 仍在进行
    check_bit("drain still AWVALID", true, dut->AWVALID);

    dut->cam_hit_i = 0;
    dut->AWREADY = 1; dut->WREADY = 1;
    for (int i = 0; i < 8 && !dut->drain_done_o; i++) {
        if (dut->BREADY) { dut->BVALID = 1; dut->BRESP = 0; }
        tick(dut);
    }
    check_bit("drain done after STLF", true, dut->drain_done_o);
    dut->drain_req_i = 0; dut->BVALID = 0; tick(dut);

    std::cout << "\n=== 测试汇总: " << pass_cnt << " 通过, " << fail_cnt << " 失败 ===" << std::endl;
    delete dut;
    return (fail_cnt == 0) ? 0 : 1;
}
