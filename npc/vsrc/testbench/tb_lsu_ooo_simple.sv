// LSU_ooo 简单测试 - 只测试控制逻辑，不测试实际 AXI 交互
// 完整的 AXI 测试需要 AXI 总线模型

`timescale 1ns/1ps

`include "./include/pipeline_pkt_pkg.sv"

module tb_lsu_ooo_simple
import pipeline_pkt_pkg::*;
();

logic clk = 0, rst = 1;
always #5 clk = ~clk;

logic              valid_i = 0;
issue2ex_pkt_t     data_i = '0;
logic              ready_o;

logic        complete_en_o;
logic [4:0]  complete_idx_o;
logic [31:0] complete_data_o;
logic        complete_exception_o;
logic [3:0]  complete_cause_o;

// AXI 信号（本测试中不使用，保持悬空）
logic [31:0] ARADDR, AWADDR, WDATA, RDATA;
logic [3:0]  ARID, AWID, RID, BID, WSTRB;
logic [7:0]  ARLEN, AWLEN;
logic [2:0]  ARSIZE, AWSIZE;
logic [1:0]  ARBURST, AWBURST, RRESP, BRESP;
logic        ARVALID, ARREADY, RVALID, RLAST, RREADY;
logic        AWVALID, AWREADY, WLAST, WVALID, WREADY;
logic        BVALID, BREADY;

// 模拟 AXI 总是不就绪（本测试只验证控制逻辑）
assign ARREADY = 0;
assign RVALID = 0;
assign RLAST = 0;
assign RDATA = 0;
assign RID = 0;
assign RRESP = 0;
assign AWREADY = 0;
assign WREADY = 0;
assign BVALID = 0;
assign BID = 0;
assign BRESP = 0;

LSU_ooo dut (.*);

int pass_cnt = 0, fail_cnt = 0;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk32(input string name, input logic [31:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=0x%08x  实际=0x%08x", name, exp, act); fail_cnt++; end
endtask

task automatic tick; @(posedge clk); #1; endtask

initial begin
    // 复位
    repeat(3) @(posedge clk);
    rst = 0;
    @(posedge clk); #1;
    
    $display("\n=== LSU_ooo 简单测试 ===");
    
    // ========== 测试1: 非访存指令透传 ==========
    $display("\n[测试1] 非访存指令应该直接透传");
    valid_i = 1;
    data_i.rob_idx = 5;
    data_i.mem.cmd = MEM_NONE;  // 非访存
    data_i.rs1_data = 100;
    data_i.imm = 50;
    
    tick();
    $display("  调试: data_i.rob_idx=%d, complete_idx_o=%d", data_i.rob_idx, complete_idx_o);
    chk("complete_en (非访存透传)", 1'b1, complete_en_o);
    chk("ready (接受新输入)", 1'b1, ready_o);
    chk32("complete_idx", 5, complete_idx_o);
    
    // ========== 测试2: Load 指令进入等待状态 ==========
    $display("\n[测试2] Load 指令应该进入等待状态");
    valid_i = 1;
    data_i.rob_idx = 6;
    data_i.mem.cmd = MEM_LOAD;
    data_i.rs1_data = 32'h8000_0000;
    data_i.imm = 32'h100;
    data_i.inst[14:12] = 3'b010;  // LW
    
    tick();
    // LSU 应该发出访存请求（但因为 AXI 不响应，会卡在 WAIT_RESP）
    chk("ARVALID (发出读请求)", 1'b1, ARVALID);
    chk("ready (不接受新输入)", 1'b0, ready_o);
    chk("complete_en (未完成)", 1'b0, complete_en_o);
    
    // 保持输入，等待几个周期
    repeat(3) tick();
    chk("ready (仍在等待)", 1'b0, ready_o);
    
    // ========== 测试3: Store 指令进入等待状态 ==========
    $display("\n[测试3] Store 指令应该进入等待状态");
    // 清除之前的状态（需要复位）
    rst = 1;
    repeat(2) @(posedge clk);
    rst = 0;
    @(posedge clk); #1;
    
    valid_i = 1;
    data_i.rob_idx = 7;
    data_i.mem.cmd = MEM_STORE;
    data_i.rs1_data = 32'h8000_0000;
    data_i.rs2_data = 32'hDEADBEEF;  // store 数据
    data_i.imm = 32'h200;
    data_i.inst[14:12] = 3'b010;  // SW
    
    tick();
    chk("AWVALID (发出写地址)", 1'b1, AWVALID);
    chk("ready (不接受新输入)", 1'b0, ready_o);
    chk("complete_en (未完成)", 1'b0, complete_en_o);
    
    // ========== 测试4: 多个非访存指令连续透传 ==========
    $display("\n[测试4] 多个非访存指令连续透传");
    rst = 1;
    repeat(2) @(posedge clk);
    rst = 0;
    @(posedge clk); #1;
    
    for (int i = 0; i < 3; i++) begin
        valid_i = 1;
        data_i.rob_idx = 10 + i;
        data_i.mem.cmd = MEM_NONE;
        
        tick();
        chk($sformatf("complete_en [%0d]", i), 1'b1, complete_en_o);
        chk($sformatf("ready [%0d]", i), 1'b1, ready_o);
        chk32($sformatf("complete_idx [%0d]", i), 10 + i, complete_idx_o);
    end
    
    // 汇总
    $display("\n=== 测试汇总 ===");
    $display("通过: %0d", pass_cnt);
    $display("失败: %0d", fail_cnt);
    
    if (fail_cnt == 0) $display("\n✓ 所有测试通过！");
    else $display("\n✗ 有测试失败");
    
    $finish;
end

endmodule
