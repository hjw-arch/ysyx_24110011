// exu 功能测试
// 覆盖：ALU 运算、分支判断、跳转、CSR、重定向检测、唤醒信号、完成信号
`timescale 1ns/1ps

`include "../include/pipeline_pkt_pkg.sv"

module tb_exu;
import pipeline_pkt_pkg::*;

logic clk = 0, rst = 1;
always #5 clk = ~clk;

logic              valid_i = 0;
issue2ex_pkt_t     data_i = '0;  // 初始化为全0
logic              ready_o;

logic        complete_en_o;
logic [4:0]  complete_idx_o;
logic [31:0] complete_data_o;
logic        complete_exception_o;
logic [3:0]  complete_cause_o;
logic        complete_redirect_valid_o;
logic [31:0] complete_redirect_addr_o;

logic        wakeup_en_o;
logic [5:0]  wakeup_preg_o;

logic        redirect_valid_o;
logic [31:0] redirect_addr_o;

logic        bpu_update_valid_o;
logic        bpu_update_btb_type_o;
logic        bpu_update_taken_o;
logic [31:0] bpu_update_target_o;

exu dut (
    .clk(clk),
    .rst(rst),
    .valid_i(valid_i),
    .data_i(data_i),
    .ready_o(ready_o),
    .complete_en_o(complete_en_o),
    .complete_idx_o(complete_idx_o),
    .complete_data_o(complete_data_o),
    .complete_exception_o(complete_exception_o),
    .complete_cause_o(complete_cause_o),
    .complete_redirect_valid_o(complete_redirect_valid_o),
    .complete_redirect_addr_o(complete_redirect_addr_o),
    .wakeup_en_o(wakeup_en_o),
    .wakeup_preg_o(wakeup_preg_o),
    .redirect_valid_o(redirect_valid_o),
    .redirect_addr_o(redirect_addr_o),
    .bpu_update_valid_o(bpu_update_valid_o),
    .bpu_update_btb_type_o(bpu_update_btb_type_o),
    .bpu_update_taken_o(bpu_update_taken_o),
    .bpu_update_target_o(bpu_update_target_o)
);
int pass_cnt = 0, fail_cnt = 0;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk32(input string name, input logic [31:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=0x%08x  实际=0x%08x", name, exp, act); fail_cnt++; end
endtask

task automatic chk5(input string name, input logic [4:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%0d  实际=%0d", name, exp, act); fail_cnt++; end
endtask

task automatic chk6(input string name, input logic [5:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%0d  实际=%0d", name, exp, act); fail_cnt++; end
endtask

task automatic tick; @(posedge clk); #1; endtask

// 辅助：设置 ALU 运算指令
task automatic set_alu(
    input [31:0] pc, rs1_val, rs2_val, imm_val,
    input [3:0] alu_op,
    input [1:0] alu_src,
    input [4:0] rob_idx,
    input [5:0] phys_rd,
    input rd_wen
);
    valid_i = 1;
    data_i.pc = pc;
    data_i.inst = 32'h0;
    data_i.rob_idx = rob_idx;
    data_i.phys_rd = phys_rd;
    data_i.rs1_data = rs1_val;
    data_i.rs2_data = rs2_val;
    data_i.imm = imm_val;
    data_i.pred_taken = 0;
    data_i.rd_wen = rd_wen;
    data_i.ex.alu_op = alu_op;
    data_i.ex.alu_src = alu_src;
    data_i.ex.cfi_type = 2'b00;
    data_i.ex.br_cond = 2'b00;
    data_i.ex.rs1_used = 0;
    data_i.ex.rs2_used = 0;
    data_i.ex.fwd_rs1_sel = 2'b00;
    data_i.ex.fwd_rs2_sel = 2'b00;
    data_i.mem.cmd = 2'b00;
    data_i.sys.csr_cmd = 2'b00;
    data_i.sys.priv_redir = 2'b00;
    data_i.sys.fence_i = 0;
    #1;  // 等待组合逻辑稳定
endtask

initial begin
    $display("\n===== exu 功能测试 =====\n");
    tick; tick; rst = 0; tick;
    
    // ── 测试1：ALU ADD ──
    $display("[TEST1] ALU ADD: 100 + 200 = 300");
    set_alu(32'h1000, 32'd100, 32'd200, 32'd0, ALU_ADD, ALU_SRC_RS1_RS2, 5'd10, 6'd32, 1'b1);
    chk("complete_en = 1", 1'b1, complete_en_o);
    chk5("complete_idx = 10", 5'd10, complete_idx_o);
    chk32("result = 300", 32'd300, complete_data_o);
    chk("wakeup_en = 1 (rd_wen=1)", 1'b1, wakeup_en_o);
    chk6("wakeup_preg = p32", 6'd32, wakeup_preg_o);
    chk("no redirect", 1'b0, redirect_valid_o);
    
    // ── 测试2：ALU SUB ──
    $display("\n[TEST2] ALU SUB: 100 - 30 = 70");
    set_alu(32'h1004, 32'd100, 32'd30, 32'd0, ALU_SUB, ALU_SRC_RS1_RS2, 5'd11, 6'd33, 1'b1);
    chk32("result = 70", 32'd70, complete_data_o);
    
    // ── 测试3：ALU 立即数 ADDI ──
    $display("\n[TEST3] ADDI: rs1 + imm = 50 + 10 = 60");
    set_alu(32'h1008, 32'd50, 32'd0, 32'd10, ALU_ADD, ALU_SRC_RS1_IMM, 5'd12, 6'd34, 1'b1);
    chk32("result = 60", 32'd60, complete_data_o);
    
    // ── 测试4：LUI (ALU_COPY2, pc+imm) ──
    $display("\n[TEST4] LUI: imm = 0x12345000");
    set_alu(32'h100c, 32'd0, 32'd0, 32'h12345000, ALU_COPY2, ALU_SRC_PC_IMM, 5'd13, 6'd35, 1'b1);
    chk32("result = 0x12345000", 32'h12345000, complete_data_o);
    
    // ── 测试5：分支 BEQ taken (rs1 == rs2) ──
    $display("\n[TEST5] BEQ taken: pc=0x2000, rs1=100, rs2=100, imm=16");
    valid_i = 1;
    data_i.pc = 32'h2000;
    data_i.rs1_data = 32'd100;
    data_i.rs2_data = 32'd100;
    data_i.imm = 32'd16;
    data_i.pred_taken = 0;  // 预测 not-taken
    data_i.rd_wen = 0;
    data_i.rob_idx = 5'd14;
    data_i.ex.alu_op = ALU_SUB;
    data_i.ex.alu_src = ALU_SRC_RS1_RS2;
    data_i.ex.cfi_type = 2'b01;  // branch
    data_i.ex.br_cond = BR_EQ;
    data_i.mem.cmd = 2'b00;
    data_i.sys = '0;
    #1;
    chk("branch taken", 1'b1, redirect_valid_o);
    chk32("redirect_addr = 0x2010", 32'h2010, redirect_addr_o);
    chk("complete_redirect_valid = 1", 1'b1, complete_redirect_valid_o);
    chk32("complete_redirect_addr = 0x2010", 32'h2010, complete_redirect_addr_o);
    chk("wakeup_en = 0 (branch不写寄存器)", 1'b0, wakeup_en_o);
    chk("bpu_update_valid = 1", 1'b1, bpu_update_valid_o);
    chk("bpu_update_taken = 1", 1'b1, bpu_update_taken_o);
    
    // ── 测试6：分支 BEQ not-taken (rs1 != rs2) ──
    $display("\n[TEST6] BEQ not-taken: rs1=100, rs2=50, pred_taken=0");
    data_i.rs1_data = 32'd100;
    data_i.rs2_data = 32'd50;
    data_i.pred_taken = 0;
    #1;
    chk("no redirect (预测正确)", 1'b0, redirect_valid_o);
    
    // ── 测试7：分支 BNE taken (rs1 != rs2) ──
    $display("\n[TEST7] BNE taken: rs1=100, rs2=50");
    data_i.ex.br_cond = BR_NE;
    data_i.pred_taken = 0;
    #1;
    chk("branch taken (预测错误)", 1'b1, redirect_valid_o);
    
    // ── 测试8：JAL (无条件跳转) ──
    $display("\n[TEST8] JAL: pc=0x3000, imm=2048, result=pc+4");
    data_i.pc = 32'h3000;
    data_i.imm = 32'd2048;
    data_i.pred_taken = 1;  // 预测 taken
    data_i.rd_wen = 1;
    data_i.phys_rd = 6'd40;
    data_i.ex.alu_op = ALU_ADD;
    data_i.ex.alu_src = ALU_SRC_PC_4;
    data_i.ex.cfi_type = 2'b10;  // jal
    data_i.sys.fence_i = 0;
    #1;
    chk32("result = pc+4 = 0x3004", 32'h3004, complete_data_o);
    chk("no redirect (预测正确)", 1'b0, redirect_valid_o);
    chk("wakeup_en = 1", 1'b1, wakeup_en_o);
    chk("bpu_update_valid = 1 (JAL)", 1'b1, bpu_update_valid_o);
    chk("bpu_update_btb_type = 1 (JAL)", 1'b1, bpu_update_btb_type_o);
    
    // ── 测试9：JALR (rs1+imm, 清bit0) ──
    $display("\n[TEST9] JALR: rs1=0x4001, imm=7, target=(0x4001+7)&~1=0x4008");
    data_i.pc = 32'h5000;
    data_i.rs1_data = 32'h4001;
    data_i.imm = 32'd7;
    data_i.pred_taken = 0;
    data_i.ex.cfi_type = 2'b11;  // jalr
    #1;
    chk("redirect (预测错误)", 1'b1, redirect_valid_o);
    chk32("redirect_addr = 0x4008", 32'h4008, redirect_addr_o);
    chk("bpu_update_valid = 0 (JALR不训练)", 1'b0, bpu_update_valid_o);
    
    // ── 测试10：CSR 寄存器形式 (CSRRW) ──
    $display("\n[TEST10] CSRRW: rs1_data=0xabcd1234");
    data_i.pc = 32'h6000;
    data_i.inst = 32'h30011173;  // csrrw x3, mstatus, x2
    data_i.rs1_data = 32'habcd_1234;
    data_i.imm = 32'h300;
    data_i.rd_wen = 1;
    data_i.phys_rd = 6'd41;
    data_i.ex.alu_src = ALU_SRC_RS1_RS2;
    data_i.ex.cfi_type = 2'b00;
    data_i.sys.csr_cmd = CSR_CMD_WRITE;
    #1;
    chk32("result = rs1_data", 32'habcd_1234, complete_data_o);
    chk("wakeup_en = 1", 1'b1, wakeup_en_o);
    
    // ── 测试11：CSR 立即数形式 (CSRRWI) ──
    $display("\n[TEST11] CSRRWI: zimm=5");
    data_i.inst = 32'h3002d273;  // csrrwi x4, mstatus, 5
    data_i.imm = 32'd5;
    #1;
    chk32("result = imm (zimm)", 32'd5, complete_data_o);
    
    // ── 测试12：FENCE.I (result=pc+4) ──
    $display("\n[TEST12] FENCE.I: result=pc+4");
    data_i.pc = 32'h7000;
    data_i.sys.csr_cmd = CSR_CMD_NONE;
    data_i.sys.fence_i = 1;
    #1;
    chk32("result = seq_pc = 0x7004", 32'h7004, complete_data_o);
    
    // ── 测试13：无 rd_wen 时不唤醒 ──
    $display("\n[TEST13] 无rd_wen时不唤醒");
    set_alu(32'h8000, 32'd10, 32'd20, 32'd0, ALU_ADD, ALU_SRC_RS1_RS2, 5'd20, 6'd50, 1'b0);
    chk("wakeup_en = 0", 1'b0, wakeup_en_o);
    
    // ── 测试14：ALU SLT (有符号比较) ──
    $display("\n[TEST14] SLT: -10 < 10 = 1");
    set_alu(32'h9000, 32'hffff_fff6, 32'd10, 32'd0, ALU_SLT, ALU_SRC_RS1_RS2, 5'd21, 6'd51, 1'b1);
    chk32("result = 1", 32'd1, complete_data_o);
    
    // ── 测试15：ALU SLTU (无符号比较) ──
    $display("\n[TEST15] SLTU: 0xfffffff6 > 10 (unsigned)");
    set_alu(32'ha000, 32'hffff_fff6, 32'd10, 32'd0, ALU_SLTU, ALU_SRC_RS1_RS2, 5'd22, 6'd52, 1'b1);
    chk32("result = 0", 32'd0, complete_data_o);
    
    // ── 测试16：分支 BLT (有符号 <) ──
    $display("\n[TEST16] BLT: -5 < 10, taken");
    data_i.pc = 32'hb000;
    data_i.rs1_data = 32'hffff_fffb;  // -5
    data_i.rs2_data = 32'd10;
    data_i.imm = 32'd8;
    data_i.pred_taken = 0;
    data_i.rd_wen = 0;
    data_i.ex.alu_op = ALU_SLT;
    data_i.ex.alu_src = ALU_SRC_RS1_RS2;
    data_i.ex.cfi_type = 2'b01;
    data_i.ex.br_cond = BR_LT;
    data_i.sys = '0;
    #1;
    chk("branch taken", 1'b1, redirect_valid_o);
    chk32("redirect_addr = 0xb008", 32'hb008, redirect_addr_o);
    
    // ── 测试17：分支 BGE (有符号 >=) ──
    $display("\n[TEST17] BGE: 10 >= 10, taken");
    data_i.rs1_data = 32'd10;
    data_i.rs2_data = 32'd10;
    data_i.ex.br_cond = BR_GE;
    #1;
    chk("branch taken", 1'b1, redirect_valid_o);
    
    // ── 测试18：ready_o 始终为1 (OoO特性) ──
    $display("\n[TEST18] ready_o 始终为1 (OoO不stall)");
    valid_i = 0;
    #1;
    chk("ready_o = 1", 1'b1, ready_o);
    
    tick;
    $display("\n===== exu: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
        $display("✅ 所有测试通过！");
    else
        $display("❌ 有 %0d 个测试失败，请检查！", fail_cnt);
    $finish;
end

endmodule
