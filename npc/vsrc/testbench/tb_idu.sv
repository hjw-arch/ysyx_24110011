// idu 功能测试
// 覆盖：所有指令类型、立即数格式、寄存器编号、控制信号、边界情况
`timescale 1ns/1ps

`include "../include/pipeline_pkt_pkg.sv"

module tb_idu;
import pipeline_pkt_pkg::*;

logic           valid_i = 0;
if2id_pkt_t     data_i;
logic           ready_i = 1;
logic           valid_o;
decode_pkt_t    data_o;
logic           ready_o;

idu dut (.*);

int pass_cnt = 0, fail_cnt = 0;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk2(input string name, input logic [1:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk4(input string name, input logic [3:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk5(input string name, input logic [4:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%0d  实际=%0d", name, exp, act); fail_cnt++; end
endtask

task automatic chk32(input string name, input logic [31:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=0x%08x  实际=0x%08x", name, exp, act); fail_cnt++; end
endtask

// 辅助：设置输入指令
task automatic set_inst(input [31:0] pc, inst);
    valid_i = 1;
    data_i.pc = pc;
    data_i.inst = inst;
    data_i.pred_taken = 0;
    #1; // 组合逻辑稳定
endtask

initial begin
    $display("\n===== idu 功能测试 =====\n");
    
    // ── 测试1：R 型指令（ADD x5, x3, x4）──
    $display("[TEST1] R型指令 ADD x5,x3,x4");
    set_inst(32'h1000, 32'h004182b3); // add x5, x3, x4
    chk5("rs1_arch = x3", 5'd3, data_o.rs1_arch);
    chk5("rs2_arch = x4", 5'd4, data_o.rs2_arch);
    chk5("rd_arch  = x5", 5'd5, data_o.rd_arch);
    chk("rs1_used = 1", 1'b1, data_o.rs1_used);
    chk("rs2_used = 1", 1'b1, data_o.rs2_used);
    chk("rd_wen   = 1", 1'b1, data_o.rd_wen);
    chk4("ALU_op = ADD", 4'b0000, data_o.ex.alu_op);
    chk2("ALU_src = rs1+rs2", 2'b00, data_o.ex.alu_src);
    
    // ── 测试2：I 型指令（ADDI x2, x1, 100）──
    $display("\n[TEST2] I型指令 ADDI x2,x1,100");
    set_inst(32'h1004, 32'h06408113); // addi x2, x1, 100
    chk5("rs1_arch = x1", 5'd1, data_o.rs1_arch);
    chk5("rd_arch  = x2", 5'd2, data_o.rd_arch);
    chk("rs1_used = 1", 1'b1, data_o.rs1_used);
    chk("rs2_used = 0", 1'b0, data_o.rs2_used);
    chk("rd_wen   = 1", 1'b1, data_o.rd_wen);
    chk32("imm = 100", 32'd100, data_o.imm);
    chk2("ALU_src = rs1+imm", 2'b01, data_o.ex.alu_src);
    
    // ── 测试3：S 型指令（SW x5, 8(x2)）──
    $display("\n[TEST3] S型指令 SW x5,8(x2)");
    set_inst(32'h1008, 32'h00512423); // sw x5, 8(x2)
    chk5("rs1_arch = x2 (base)", 5'd2, data_o.rs1_arch);
    chk5("rs2_arch = x5 (data)", 5'd5, data_o.rs2_arch);
    chk("rs1_used = 1", 1'b1, data_o.rs1_used);
    chk("rs2_used = 1", 1'b1, data_o.rs2_used);
    chk("rd_wen   = 0", 1'b0, data_o.rd_wen);
    chk32("imm = 8", 32'd8, data_o.imm);
    chk2("mem.cmd = STORE", 2'b10, data_o.mem.cmd);
    
    // ── 测试4：B 型指令（BEQ x3, x4, offset）──
    $display("\n[TEST4] B型指令 BEQ x3,x4,offset=16");
    set_inst(32'h100c, 32'h00418863); // beq x3, x4, 16
    chk5("rs1_arch = x3", 5'd3, data_o.rs1_arch);
    chk5("rs2_arch = x4", 5'd4, data_o.rs2_arch);
    chk("rs1_used = 1", 1'b1, data_o.rs1_used);
    chk("rs2_used = 1", 1'b1, data_o.rs2_used);
    chk("rd_wen   = 0", 1'b0, data_o.rd_wen);
    chk32("imm = 16", 32'd16, data_o.imm);
    chk2("CFI_type = BRANCH", 2'b01, data_o.ex.cfi_type);
    
    // ── 测试5：U 型指令（LUI x6, 0x12345）──
    $display("\n[TEST5] U型指令 LUI x6,0x12345");
    set_inst(32'h1010, 32'h12345337); // lui x6, 0x12345
    chk5("rd_arch = x6", 5'd6, data_o.rd_arch);
    chk("rs1_used = 0", 1'b0, data_o.rs1_used);
    chk("rs2_used = 0", 1'b0, data_o.rs2_used);
    chk("rd_wen   = 1", 1'b1, data_o.rd_wen);
    chk32("imm = 0x12345000", 32'h12345000, data_o.imm);
    chk4("ALU_op = COPY2(LUI)", 4'b1100, data_o.ex.alu_op);
    
    // ── 测试6：J 型指令（JAL x1, offset）──
    $display("\n[TEST6] J型指令 JAL x1,offset=2048");
    set_inst(32'h1014, 32'h001000ef); // jal x1, 2048
    chk5("rd_arch = x1 (ra)", 5'd1, data_o.rd_arch);
    chk("rd_wen = 1", 1'b1, data_o.rd_wen);
    chk32("imm = 2048", 32'd2048, data_o.imm);
    chk2("CFI_type = JAL", 2'b10, data_o.ex.cfi_type);
    chk2("ALU_src = pc+4", 2'b10, data_o.ex.alu_src);
    
    // ── 测试7：边界 - rd=x0 应屏蔽写使能 ──
    $display("\n[TEST7] 边界：rd=x0 屏蔽写使能");
    set_inst(32'h1018, 32'h00108013); // addi x0, x1, 1
    chk5("rd_arch = x0", 5'd0, data_o.rd_arch);
    chk("rd_wen = 0 (x0不可写)", 1'b0, data_o.rd_wen);
    
    // ── 测试8：边界 - rs1=x0, rs2=x0 ──
    $display("\n[TEST8] 边界：rs1=x0, rs2=x0");
    set_inst(32'h101c, 32'h000002b3); // add x5, x0, x0
    chk5("rs1_arch = x0", 5'd0, data_o.rs1_arch);
    chk5("rs2_arch = x0", 5'd0, data_o.rs2_arch);
    chk("rs1_used = 0 (x0恒为0)", 1'b0, data_o.rs1_used);
    chk("rs2_used = 0 (x0恒为0)", 1'b0, data_o.rs2_used);
    
    // ── 测试9：CSR 寄存器型（CSRRW x3, mstatus, x2）──
    $display("\n[TEST9] CSR寄存器型 CSRRW");
    set_inst(32'h1020, 32'h300111f3); // csrrw x3, mstatus(0x300), x2
    chk5("rs1_arch = x2", 5'd2, data_o.rs1_arch);
    chk5("rd_arch  = x3", 5'd3, data_o.rd_arch);
    chk("rs1_used = 1 (读x2)", 1'b1, data_o.rs1_used);
    chk("rs2_used = 0", 1'b0, data_o.rs2_used);
    chk("rd_wen   = 1", 1'b1, data_o.rd_wen);
    chk2("csr_cmd = WRITE", 2'b01, data_o.sys.csr_cmd);
    
    // ── 测试10：CSR 立即数型（CSRRWI x4, mstatus, 5）──
    $display("\n[TEST10] CSR立即数型 CSRRWI (zimm)");
    set_inst(32'h1024, 32'h3002d273); // csrrwi x4, mstatus, 5
    chk5("rs1_arch = 5 (zimm)", 5'd5, data_o.rs1_arch);
    chk("rs1_used = 0 (CSR zimm不读寄存器)", 1'b0, data_o.rs1_used);
    chk("rd_wen   = 1", 1'b1, data_o.rd_wen);
    chk32("imm 包含 zimm", 32'd5, data_o.imm);
    
    // ── 测试11：系统指令 ECALL ──
    $display("\n[TEST11] 系统指令 ECALL");
    set_inst(32'h1028, 32'h00000073); // ecall
    chk("rd_wen = 0", 1'b0, data_o.rd_wen);
    chk2("priv_redir = ECALL", 2'b01, data_o.sys.priv_redir);
    
    // ── 测试12：系统指令 MRET ──
    $display("\n[TEST12] 系统指令 MRET");
    set_inst(32'h102c, 32'h30200073); // mret
    chk2("priv_redir = MRET", 2'b10, data_o.sys.priv_redir);
    
    // ── 测试13：LOAD 指令（LW x7, 12(x3)）──
    $display("\n[TEST13] LOAD指令 LW");
    set_inst(32'h1030, 32'h00c1a383); // lw x7, 12(x3)
    chk5("rs1_arch = x3", 5'd3, data_o.rs1_arch);
    chk5("rd_arch  = x7", 5'd7, data_o.rd_arch);
    chk("rs1_used = 1", 1'b1, data_o.rs1_used);
    chk("rd_wen   = 1", 1'b1, data_o.rd_wen);
    chk32("imm = 12", 32'd12, data_o.imm);
    chk2("mem.cmd = LOAD", 2'b01, data_o.mem.cmd);
    
    // ── 测试14：SUB 指令（ALU op[3]=1）──
    $display("\n[TEST14] SUB指令 (ALU op[3]=1)");
    set_inst(32'h1034, 32'h40418233); // sub x4, x3, x4
    chk4("ALU_op = SUB", 4'b1000, data_o.ex.alu_op);
    
    // ── 测试15：SRAI 指令（I型但 op[3]=1）──
    $display("\n[TEST15] SRAI指令 (立即数右移算术)");
    set_inst(32'h1038, 32'h40315313); // srai x6, x2, 3
    chk4("ALU_op = SRA", 4'b1101, data_o.ex.alu_op);
    chk32("imm[11:0] 包含 func7", 32'h403, data_o.imm);  // I型立即数完整提取，EXU 会屏蔽高位
    
    // ── 测试16：流水线握手 ──
    $display("\n[TEST16] 流水线握手");
    valid_i = 1; ready_i = 1; #1;
    chk("valid_i=1, ready_i=1 → valid_o=1", 1'b1, valid_o);
    chk("valid_i=1, ready_i=1 → ready_o=1", 1'b1, ready_o);
    valid_i = 0; #1;
    chk("valid_i=0 → valid_o=0", 1'b0, valid_o);
    
    // ── 测试17：立即数符号扩展（负数）──
    $display("\n[TEST17] 立即数符号扩展（负数）");
    set_inst(32'h103c, 32'hfff10113); // addi x2, x2, -1
    chk32("imm = -1 (符号扩展)", 32'hffffffff, data_o.imm);
    
    $display("\n===== idu: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    if (fail_cnt == 0)
        $display("✅ 所有测试通过！");
    else
        $display("❌ 有 %0d 个测试失败，请检查！", fail_cnt);
    $finish;
end

endmodule
