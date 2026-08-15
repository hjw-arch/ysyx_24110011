// IDU (Instruction Decode Unit) - OoO 版本
// 负责：指令解码、立即数生成、控制信号生成
// 不再负责：寄存器读取（由物理寄存器堆完成）、前递（由重命名消除）

`include "./include/pipeline_pkt_pkg.sv"

module IDU
import pipeline_pkt_pkg::*;
(
    // 流水线握手
    input               valid_i,
    input   if2id_pkt_t data_i,
    output              ready_o,

    output              valid_o,
    output  decode_pkt_t data_o,
    input               ready_i
);

// ── 指令字段提取 ──
wire [31:0] pc   = data_i.pc;
wire [31:0] inst = data_i.inst;
wire [31:0] seq_pc = pc + 4;

wire [6:0] opcode = inst[6:0];
wire [2:0] func3  = inst[14:12];
wire [4:0] rs1_addr_raw = inst[19:15];
wire [4:0] rs2_addr_raw = inst[24:20];
wire [4:0] rd_addr_raw  = inst[11:7];

// ── Opcode 解码 ──
localparam logic [4:0] OPC_LUI      = 5'b01101;
localparam logic [4:0] OPC_AUIPC    = 5'b00101;
localparam logic [4:0] OPC_JAL      = 5'b11011;
localparam logic [4:0] OPC_JALR     = 5'b11001;
localparam logic [4:0] OPC_BRANCH   = 5'b11000;
localparam logic [4:0] OPC_LOAD     = 5'b00000;
localparam logic [4:0] OPC_STORE    = 5'b01000;
localparam logic [4:0] OPC_CAL_I    = 5'b00100;
localparam logic [4:0] OPC_CAL_R    = 5'b01100;
localparam logic [4:0] OPC_MISC_MEM = 5'b00011;
localparam logic [4:0] OPC_SYSTEM   = 5'b11100;

wire [4:0] opc = opcode[6:2];

wire is_lui      = (opc == OPC_LUI);
wire is_auipc    = (opc == OPC_AUIPC);
wire is_jal      = (opc == OPC_JAL);
wire is_jalr     = (opc == OPC_JALR);
wire is_branch   = (opc == OPC_BRANCH);
wire is_load     = (opc == OPC_LOAD);
wire is_store    = (opc == OPC_STORE);
wire is_cal_i    = (opc == OPC_CAL_I);
wire is_cal_r    = (opc == OPC_CAL_R);
wire is_misc_mem = (opc == OPC_MISC_MEM);
wire is_system   = (opc == OPC_SYSTEM);

wire is_calc  = is_cal_i | is_cal_r;
wire is_fence = is_misc_mem & (func3 == 3'b000);
wire is_fence_i = is_misc_mem & (func3 == 3'b001);

// System 子类型
wire is_priv = is_system & (func3 == 3'b000);
wire is_csr  = is_system & (func3[2] | func3[1]);

wire is_ecall = is_priv & (inst[21:20] == 2'b00);
wire is_mret  = is_priv & (inst[21:20] == 2'b10);

wire is_csr_reg = is_csr & ~func3[2];
wire is_csr_imm = is_csr &  func3[2];

// ALU op[3] 来自 funct7[5] (SRAI, SUB, SRA)
wire calc_op3 = inst[30] & (~is_cal_i | (func3 == 3'b101));

// ── 立即数生成 ──
// imm_sel: {U-type, J-type, I/S/B-type} (3位)
wire [2:0] imm_sel;
assign imm_sel[2] = is_lui | is_auipc | is_csr_imm;
assign imm_sel[1] = is_store | is_branch | is_csr_imm;
assign imm_sel[0] = 1'b0;  // 保留位

logic [31:0] imm;
imm_gen u_imm_gen (
    .imm_sel_i (imm_sel),
    .inst_i    (inst),
    .imm_o     (imm)
);

// ── 源寄存器使用判断 ──
// rs1_used: CSR 立即数形式使用 zimm，不读 rs1
wire rs1_used = (is_jalr | is_branch | is_load | is_store | is_cal_i | is_cal_r | is_csr_reg) & |rs1_addr_raw;
wire rs2_used = (is_branch | is_store | is_cal_r) & |rs2_addr_raw;

// ── 目的寄存器写使能（屏蔽 x0）──
wire rd_wen = (is_lui | is_auipc | is_jal | is_jalr | is_load | is_cal_i | is_cal_r | is_csr) & |rd_addr_raw;

// ── 输出：decode_pkt_t ──
assign data_o.pc        = pc;
assign data_o.inst      = inst;
assign data_o.rs1_arch  = rs1_addr_raw;
assign data_o.rs2_arch  = rs2_addr_raw;
assign data_o.rd_arch   = rd_addr_raw;
assign data_o.rs1_used  = rs1_used;
assign data_o.rs2_used  = rs2_used;
assign data_o.rd_wen    = rd_wen;
assign data_o.imm       = imm;

// ── EX 控制信号 ──
// ALU 操作（按 bit 生成）
assign data_o.ex.alu_op[3] = is_lui | (is_branch & ~func3[2]) | (is_calc & calc_op3);
assign data_o.ex.alu_op[2] = is_lui | (is_calc & func3[2]);
assign data_o.ex.alu_op[1] = (is_branch & func3[2]) | (is_calc & func3[1]);
assign data_o.ex.alu_op[0] = (is_branch & func3[2] & func3[1]) | (is_calc & func3[0]);

// ALU 输入源：00=rs1+rs2, 01=rs1+imm, 10=pc+4, 11=pc+imm
assign data_o.ex.alu_src[1] = is_auipc | is_jal | is_jalr | is_fence_i;
assign data_o.ex.alu_src[0] = is_lui | is_auipc | is_load | is_store | is_cal_i;

// 控制流类型：00=无, 01=branch, 10=jal, 11=jalr
assign data_o.ex.cfi_type[1] = is_jal | is_jalr;
assign data_o.ex.cfi_type[0] = is_branch | is_jalr;

assign data_o.ex.br_cond = {func3[2], func3[0]};

// OoO 不需要前递选择（在重命名阶段解决），fwd_sel 设为 RF（无前递）
assign data_o.ex.rs1_used = rs1_used;
assign data_o.ex.rs2_used = rs2_used;
assign data_o.ex.fwd_rs1_sel = FWD_SEL_RF;
assign data_o.ex.fwd_rs2_sel = FWD_SEL_RF;

// ── MEM 控制信号 ──
assign data_o.mem.cmd = {is_store, is_load};

// ── SYS 控制信号 ──
assign data_o.sys.csr_cmd    = {2{is_csr}} & func3[1:0];
assign data_o.sys.priv_redir = {is_mret, is_ecall};
assign data_o.sys.fence_i    = is_fence_i;

// ── 流水线握手 ──
assign valid_o = valid_i;
assign ready_o = ready_i;

endmodule


// ── 立即数生成器（复用原有模块）──
module imm_gen
import pipeline_pkt_pkg::*;
(
    input  imm_sel_t    imm_sel_i,
    input  logic [31:0] inst_i,
    output logic [31:0] imm_o
);

always_comb begin
    case (imm_sel_i)
        IMM_I: imm_o = {{20{inst_i[31]}}, inst_i[31:20]};
        IMM_S: imm_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
        IMM_B: imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
        IMM_U: imm_o = {inst_i[31:12], 12'b0};
        IMM_J: imm_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
        default: imm_o = 32'b0;
    endcase
end

endmodule
