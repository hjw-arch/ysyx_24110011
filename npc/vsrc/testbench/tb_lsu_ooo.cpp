// LSU_ooo C++ Testbench - 简单控制逻辑测试
#include <verilated.h>
#include "VLSU_ooo_wrapper.h"
#include <iostream>

int pass_cnt = 0, fail_cnt = 0;

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

void check_u32(const char* name, uint32_t exp, uint32_t act) {
    if (exp == act) {
        std::cout << "  [PASS] " << name << std::endl;
        pass_cnt++;
    } else {
        std::cout << "  [FAIL] " << name 
                  << "  期望=" << exp
                  << "  实际=" << act << std::endl;
        fail_cnt++;
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    VLSU_ooo_wrapper* dut = new VLSU_ooo_wrapper;

    // 初始化
    dut->clk = 0;
    dut->rst = 1;
    dut->valid_i = 0;
    
    // 模拟 AXI 不响应
    dut->ARREADY = 0;
    dut->RVALID = 0;
    dut->RLAST = 0;
    dut->RDATA = 0;
    dut->RID = 0;
    dut->RRESP = 0;
    dut->AWREADY = 0;
    dut->WREADY = 0;
    dut->BVALID = 0;
    dut->BID = 0;
    dut->BRESP = 0;
    
    dut->eval();
    
    // 复位
    for (int i = 0; i < 3; i++) {
        dut->clk = 1; dut->eval();
        dut->clk = 0; dut->eval();
    }
    dut->rst = 0;
    
    std::cout << "\n=== LSU_ooo C++ 简单测试 ===" << std::endl;

    // ========== 测试1: 非访存指令透传 ==========
    std::cout << "\n[测试1] 非访存指令应该直接透传" << std::endl;
    dut->valid_i = 1;
    dut->rob_idx_i = 5;
    dut->mem_cmd_i = 0;  // MEM_NONE
    dut->pc_i = 0;
    dut->inst_i = 0;
    dut->phys_rd_i = 0;
    dut->rs1_data_i = 100;
    dut->rs2_data_i = 0;
    dut->imm_i = 50;
    dut->pred_taken_i = 0;
    dut->rd_wen_i = 0;
    dut->alu_op_i = 0;
    dut->alu_src_i = 0;
    dut->cfi_type_i = 0;
    dut->br_cond_i = 0;
    dut->csr_cmd_i = 0;
    dut->priv_redir_i = 0;
    dut->fence_i_i = 0;
    
    dut->eval();
    dut->clk = 1; dut->eval();
    dut->clk = 0; dut->eval();
    
    check_bit("complete_en (非访存透传)", true, dut->complete_en_o);
    check_bit("ready (接受新输入)", true, dut->ready_o);
    check_u32("complete_idx", 5, dut->complete_idx_o);

    // ========== 测试2: Load 指令进入等待状态 ==========
    std::cout << "\n[测试2] Load 指令应该进入等待状态" << std::endl;
    dut->valid_i = 1;
    dut->rob_idx_i = 6;
    dut->mem_cmd_i = 1;  // MEM_LOAD
    dut->rs1_data_i = 0x80000000;
    dut->imm_i = 0x100;
    dut->inst_i = 0x00002000;  // funct3 = 010 (LW)
    
    dut->eval();
    dut->clk = 1; dut->eval();
    dut->clk = 0; dut->eval();
    
    check_bit("ARVALID (发出读请求)", true, dut->ARVALID);
    check_bit("ready (不接受新输入)", false, dut->ready_o);
    check_bit("complete_en (未完成)", false, dut->complete_en_o);

    // ========== 测试3: 多个非访存指令连续透传 ==========
    std::cout << "\n[测试3] 多个非访存指令连续透传" << std::endl;
    
    // 复位，清除之前 Load 指令的影响
    dut->rst = 1;
    dut->valid_i = 0;
    for (int i = 0; i < 3; i++) {
        dut->clk = 1; dut->eval();
        dut->clk = 0; dut->eval();
    }
    dut->rst = 0;
    dut->eval();
    dut->clk = 1; dut->eval();
    dut->clk = 0; dut->eval();
    
    for (int i = 0; i < 3; i++) {
        dut->valid_i = 1;
        dut->rob_idx_i = 10 + i;
        dut->mem_cmd_i = 0;  // MEM_NONE
        
        dut->eval();
        dut->clk = 1; dut->eval();
        dut->clk = 0; dut->eval();
        
        std::string name_en = "complete_en [" + std::to_string(i) + "]";
        std::string name_ready = "ready [" + std::to_string(i) + "]";
        std::string name_idx = "complete_idx [" + std::to_string(i) + "]";
        
        check_bit(name_en.c_str(), true, dut->complete_en_o);
        check_bit(name_ready.c_str(), true, dut->ready_o);
        check_u32(name_idx.c_str(), 10 + i, dut->complete_idx_o);
    }

    // 汇总
    std::cout << "\n=== 测试汇总 ===" << std::endl;
    std::cout << "通过: " << pass_cnt << std::endl;
    std::cout << "失败: " << fail_cnt << std::endl;
    
    delete dut;
    return (fail_cnt == 0) ? 0 : 1;
}
