// IDU (Instruction Decode Unit) - OoO 版本
// 负责：指令解码、立即数生成、控制信号生成
// 不再负责：寄存器读取（由物理寄存器堆完成）、前递（由重命名消除）

`include "./include/pipeline_pkt_pkg.sv"

module idu
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
localparam logic [4:0] OPC_SYSTEM   = 5'b11100;  // SYSTEM 类，包含 ecall、mret、CSR 指令

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
wire is_fence_i = is_misc_mem & (func3 == 3'b001);

// SYSTEM 指令按照 funct3 分成两类：
//   000: 特权/系统操作，例如 ecall/mret
//   001/010/011: CSR 寄存器源操作，CSRRW/CSRRS/CSRRC
//   101/110/111: CSR 立即数源操作，CSRRWI/CSRRSI/CSRRCI
//   100: 保留编码，不当作合法 CSR 指令
wire func3_is_csr = func3[1] | func3[0];
wire func3_is_sys = func3 == 3'b000;

wire is_csr      = is_system & func3_is_csr;
wire is_csr_imm  = is_csr & func3[2];     // csrrwi、csrrsi、csrrci
wire is_csr_reg  = is_csr & ~func3[2];    // csrrw、csrrs、csrrc
wire is_sysop    = is_system & func3_is_sys;

// ecall/mret 在 ID 阶段先解出来，避免 WBU 提交重定向路径上再做宽指令比较
wire is_ecall = is_sysop & (inst[31:20] == 12'h000);
wire is_mret  = is_sysop & (inst[31:20] == 12'h302);

// SRAI/SUB/SRA 需要设置 ALU op[3]
wire is_srai  = is_cal_i & (func3 == 3'b101) & inst[30];
wire calc_op3 = is_srai | (is_cal_r & inst[30]);

// ── 立即数生成 ──
// imm_sel 编码：I=000, S=001, Z=011, J=100, B=101, U=110
logic [2:0] imm_sel;

always_comb begin
    if (is_lui | is_auipc)
        imm_sel = 3'b110; // IMM_U
    else if (is_jal)
        imm_sel = 3'b100; // IMM_J
    else if (is_branch)
        imm_sel = 3'b101; // IMM_B
    else if (is_store)
        imm_sel = 3'b001; // IMM_S
    else if (is_csr_imm)
        imm_sel = 3'b011; // IMM_Z (zimm)
    else
        imm_sel = 3'b000; // IMM_I (默认，包括 load/cal_i/jalr)
end

logic [31:0] imm;
imm_gen u_imm_gen (
    .imm_sel_i (imm_sel),
    .inst_i    (inst),
    .imm_o     (imm)
);

// ── 源寄存器使用判断 ──
// rs1_used/rs2_used 是语义依赖判断，不是简单检查 rs 字段是否存在。
// CSR 立即数形式使用 zimm（inst[19:15]），不读取 rs1。
wire rs1_used = (is_jalr | is_branch | is_load | is_store | is_cal_i | is_cal_r | is_csr_reg) & |rs1_addr_raw;
wire rs2_used = (is_branch | is_store | is_cal_r) & |rs2_addr_raw;

// ── 目的寄存器写使能 ──
// rd_wen 在 ID 阶段顺手屏蔽 x0。后级如需原始 rd 字段，直接从随流水携带的 inst 中切片。
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
// ALU 操作按 bit 直接生成，避免写成优先级 mux 链。
//   - LUI 使用 ALU_COPY2（即 ALU 的 data2 直通路径）
//   - EQ/NE 分支使用 SUB 产生 zero_flag
//   - LT/GE 使用 SLT，LTU/GEU 使用 SLTU
//   - 普通计算指令大部分复用 funct3，op[3] 来自 funct7[5]/srai
assign data_o.ex.alu_op[3] = is_lui | (is_branch & ~func3[2]) | (is_calc & calc_op3);
assign data_o.ex.alu_op[2] = is_lui | (is_calc & func3[2]);
assign data_o.ex.alu_op[1] = (is_branch & func3[2]) | (is_calc & func3[1]);
assign data_o.ex.alu_op[0] = (is_branch & func3[2] & func3[1]) | (is_calc & func3[0]);

// ALU 输入源编码：
//   00: rs1, rs2
//   01: rs1, imm
//   10: pc,  4
//   11: pc,  imm
// FENCE.I 使用 pc+4，这样 WBU 提交时可以直接拿 result 作为重定向地址，
// 不需要在提交点再放一个 pc+4 加法器。
assign data_o.ex.alu_src[1] = is_auipc | is_jal | is_jalr | is_fence_i;
assign data_o.ex.alu_src[0] = is_lui | is_auipc | is_load | is_store | is_cal_i;

// 控制流指令类型编码：
//   00: 无控制流，01: branch，10: jal，11: jalr
assign data_o.ex.cfi_type[1] = is_jal | is_jalr;
assign data_o.ex.cfi_type[0] = is_branch | is_jalr;

assign data_o.ex.br_cond = {func3[2], func3[0]};

// OoO 不需要前递选择（在重命名阶段解决 RAW），fwd_sel 设为 RF（表示无前递）
assign data_o.ex.rs1_used = rs1_used;
assign data_o.ex.rs2_used = rs2_used;
assign data_o.ex.fwd_rs1_sel = FWD_SEL_RF;
assign data_o.ex.fwd_rs2_sel = FWD_SEL_RF;

// ── MEM 控制信号 ──
// mem.cmd 只告诉 LSU 是否为 load/store。访存宽度和符号扩展信息是 inst[14:12]
// 的直接切片，留到 LSU 本地解码，不重复进入流水寄存器。
assign data_o.mem.cmd = {is_store, is_load};

// ── SYS 控制信号 ──
// CSR/系统控制：
//   csr_cmd    : NONE/WRITE/SET/CLEAR，由 CSR funct3[1:0] 压缩得到
//   priv_redir : ECALL/MRET 提交点重定向，编码上天然互斥
//   fence_i    : 与特权重定向分开，贴近 Rocket/Ibex 的语义分层
// CSR 地址、zimm、rd、访存宽度都能从随流水携带的 inst 直接切片，因此不额外传。
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
        IMM_Z: imm_o = {27'b0, inst_i[19:15]};  // CSR zimm（零扩展）
        IMM_B: imm_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
        IMM_U: imm_o = {inst_i[31:12], 12'b0};
        IMM_J: imm_o = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
        default: imm_o = 32'b0;
    endcase
end

endmodule
