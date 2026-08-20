// ROB 功能测试
// 覆盖：分配、乱序完成、顺序提交、ROB 满、flush、双路 complete

`include "../include/pipeline_pkt_pkg.sv"

module tb_rob;
import pipeline_pkt_pkg::*;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

logic            alloc_en_i;
rob_alloc_pkt_t  alloc_pkt_i;
logic [4:0]      alloc_idx_o;
logic            alloc_ready_o;

logic            complete_en1_i;
logic [4:0]      complete_idx1_i;
logic [31:0]     complete_data1_i;
logic            complete_exception1_i;
logic [3:0]      complete_cause1_i;
logic            complete_redirect_valid1_i;
logic [31:0]     complete_redirect_addr1_i;

logic            complete_en2_i;
logic [4:0]      complete_idx2_i;
logic [31:0]     complete_data2_i;
logic            complete_exception2_i;
logic [3:0]      complete_cause2_i;
logic            complete_redirect_valid2_i;
logic [31:0]     complete_redirect_addr2_i;

logic            store_commit_ready_i = 1'b1;
logic            store_commit_fault_i = 1'b0;
logic            store_commit_req_o;
logic [4:0]      store_commit_rob_idx_o;

logic            commit_valid_o;
rob_commit_t     commit_pkt_o;
logic            exc_commit_valid_o;
logic [3:0]      exc_commit_cause_o;
logic [31:0]     exc_commit_pc_o;
logic            flush_o;
logic [31:0]     flush_pc_o;
logic [4:0]      head_idx_o;

rob dut (.*);

int pass_cnt = 0, fail_cnt = 0;
logic [4:0] idx0, idxA, idxB;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk32(input string name, input logic [31:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=0x%08x  实际=0x%08x", name, exp, act); fail_cnt++; end
endtask

task automatic tick; @(posedge clk); #1; endtask

task automatic alloc_instr(
    input [31:0] pc,
    input [4:0]  arch_rd,
    input [5:0]  phys_rd, phys_old,
    input        rd_wen
);
    alloc_en_i = 1;
    alloc_pkt_i.pc          = pc;
    alloc_pkt_i.inst        = 32'h0000_0013;
    alloc_pkt_i.arch_rd     = arch_rd;
    alloc_pkt_i.phys_rd     = phys_rd;
    alloc_pkt_i.phys_rd_old = phys_old;
    alloc_pkt_i.rd_wen      = rd_wen;
    alloc_pkt_i.is_store    = 1'b0;
    alloc_pkt_i.sys         = '0;
    tick;
    alloc_en_i = 0;
endtask

// 默认走 complete 口 1
task automatic complete_instr(input [4:0] idx, input [31:0] data, input expt = 0);
    complete_en1_i              = 1;
    complete_idx1_i             = idx;
    complete_data1_i            = data;
    complete_exception1_i       = expt;
    complete_cause1_i           = 4'd0;
    complete_redirect_valid1_i  = 0;
    complete_redirect_addr1_i   = 0;
    tick;
    complete_en1_i = 0;
endtask

initial begin
    alloc_en_i = 0; alloc_pkt_i = '0;
    complete_en1_i = 0; complete_idx1_i = 0; complete_data1_i = 0;
    complete_exception1_i = 0; complete_cause1_i = 0;
    complete_redirect_valid1_i = 0; complete_redirect_addr1_i = 0;
    complete_en2_i = 0; complete_idx2_i = 0; complete_data2_i = 0;
    complete_exception2_i = 0; complete_cause2_i = 0;
    complete_redirect_valid2_i = 0; complete_redirect_addr2_i = 0;
    tick; tick; rst = 0; tick;

    // ── 测试1：基本分配→完成→提交 ──
    $display("\n[TEST1] 基本分配→完成→提交");
    chk("初始 alloc_ready=1", 1'b1, alloc_ready_o);
    chk("初始 commit_valid=0", 1'b0, commit_valid_o);

    alloc_en_i = 1;
    alloc_pkt_i.pc          = 32'h1000;
    alloc_pkt_i.inst        = 32'h0;
    alloc_pkt_i.arch_rd     = 5'd1;
    alloc_pkt_i.phys_rd     = 6'd32;
    alloc_pkt_i.phys_rd_old = 6'd1;
    alloc_pkt_i.rd_wen      = 1'b1;
    alloc_pkt_i.sys         = '0;
    #1;
    idx0 = alloc_idx_o;
    tick; alloc_en_i = 0;

    chk("分配后 commit_valid=0（未完成）", 1'b0, commit_valid_o);

    complete_instr(idx0, 32'hABCD_0001);
    chk("完成后 commit_valid=1", 1'b1, commit_valid_o);
    chk32("提交结果正确", 32'hABCD_0001, commit_pkt_o.result);
    tick;
    chk("提交后 commit_valid=0", 1'b0, commit_valid_o);

    // ── 测试2：乱序完成→顺序提交 ──
    $display("\n[TEST2] 乱序完成→顺序提交");
    alloc_en_i = 1;
    alloc_pkt_i.pc = 32'h1004; alloc_pkt_i.arch_rd = 5'd2;
    alloc_pkt_i.phys_rd = 6'd33; alloc_pkt_i.phys_rd_old = 6'd2;
    alloc_pkt_i.rd_wen = 1'b1;
    #1; idxA = alloc_idx_o; tick; alloc_en_i = 0;
    alloc_en_i = 1;
    alloc_pkt_i.pc = 32'h1008; alloc_pkt_i.arch_rd = 5'd3;
    alloc_pkt_i.phys_rd = 6'd34; alloc_pkt_i.phys_rd_old = 6'd3;
    alloc_pkt_i.rd_wen = 1'b1;
    #1; idxB = alloc_idx_o; tick; alloc_en_i = 0;

    // B 走口2、A 走口1，同拍也可
    complete_en2_i = 1;
    complete_idx2_i = idxB;
    complete_data2_i = 32'hBBBB_BBBB;
    tick; complete_en2_i = 0;
    chk("B先完成，头部A未完成，commit=0", 1'b0, commit_valid_o);

    complete_instr(idxA, 32'hAAAA_AAAA);
    chk("A完成后头部就绪 commit=1", 1'b1, commit_valid_o);
    chk32("先提交A的结果", 32'hAAAA_AAAA, commit_pkt_o.result);
    tick;
    chk("A提交后B轮到头部 commit=1", 1'b1, commit_valid_o);
    chk32("B的结果正确", 32'hBBBB_BBBB, commit_pkt_o.result);
    tick;

    // ── 测试3：ROB 满时 alloc_ready=0 ──
    $display("\n[TEST3] ROB 满后拒绝分配");
    for (int i = 0; i < 16; i++) begin
        if (alloc_ready_o)
            alloc_instr(32'h2000 + i*4, 5'd0, 6'd0, 6'd0, 1'b0);
        else
            tick;
    end
    chk("ROB满后 alloc_ready=0", 1'b0, alloc_ready_o);

    // ── 测试4：flush 清空 ROB ──
    $display("\n[TEST4] flush 清空 ROB");
    complete_en1_i = 1;
    complete_idx1_i = dut.rob_head;
    complete_exception1_i = 1;
    complete_cause1_i = 4'd2;
    complete_data1_i = 32'h0;
    complete_redirect_valid1_i = 0;
    tick; complete_en1_i = 0; complete_exception1_i = 0;
    chk("异常导致 flush_o=1", 1'b1, flush_o);
    tick;
    chk("flush后 alloc_ready=1", 1'b1, alloc_ready_o);
    chk("flush后 commit_valid=0", 1'b0, commit_valid_o);
    chk("flush后 flush_o=0", 1'b0, flush_o);

    tick;
    $display("\n===== rob: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
