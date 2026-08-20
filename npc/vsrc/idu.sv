// IDU (Instruction Decode Unit) - OoO 版本
// 纯组合数据流译码：生成寄存器使用信息、执行控制和立即数。
// 小核不做指令合法性检查；未识别编码按无副作用指令流过后端。

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
wire [31:0] pc           = data_i.pc;
wire [31:0] inst         = data_i.inst;
wire [4:0]  opc          = inst[6:2];
wire [2:0]  func3        = inst[14:12];
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

wire is_calc    = is_cal_i | is_cal_r;
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
// 3 位选择编码直接控制各字段来源，不生成 32 位宽优先选择器。
imm_sel_t imm_sel;

assign imm_sel[2] = is_lui | is_auipc | is_jal | is_branch;
assign imm_sel[1] = is_lui | is_auipc | is_csr_imm;
assign imm_sel[0] = is_branch | is_store | is_csr_imm;

wire imm_is_i  = ~|imm_sel;
wire imm_is_s  = ~imm_sel[2] & ~imm_sel[1] & imm_sel[0];
wire imm_is_u  = imm_sel[2] & imm_sel[1];
wire imm_is_z  = imm_sel[1] & imm_sel[0];
wire imm_is_uj = imm_sel[2] & ~imm_sel[0];
wire imm_is_j  = imm_sel[2] & ~imm_sel[1] & ~imm_sel[0];
wire imm_is_b  = imm_sel[2] & imm_sel[0];
wire imm_sign  = inst[31] & ~imm_is_z;

wire [10:0] imm_30_20 = ({11{ imm_is_u}} & inst[30:20])
                       | ({11{~imm_is_u}} & {11{imm_sign}});
wire [7:0]  imm_19_12 = ({8{ imm_is_uj}} & inst[19:12])
                       | ({8{~imm_is_uj}} & {8{imm_sign}});
wire        imm_11    = (imm_is_j & inst[20])
                       | (imm_is_b & inst[7])
                       | ((imm_is_i | imm_is_s) & imm_sign);
wire [5:0]  imm_10_5  = {6{~(imm_is_u | imm_is_z)}} & inst[30:25];

wire imm_sel_00 = ~imm_sel[1] & ~imm_sel[0];
wire imm_sel_01 = ~imm_sel[1] & imm_sel[0];
wire imm_sel_11 = imm_sel[1] & imm_sel[0];

wire [3:0] imm_4_1 = ({4{imm_sel_00}} & inst[24:21])
                     | ({4{imm_sel_01}} & inst[11:8])
                     | ({4{imm_sel_11}} & inst[19:16]);
wire imm_0 = (imm_is_i & inst[20])
           | (imm_is_s & inst[7])
           | (imm_is_z & inst[15]);

wire [31:0] imm = {
    imm_sign,
    imm_30_20,
    imm_19_12,
    imm_11,
    imm_10_5,
    imm_4_1,
    imm_0
};

// ── 源寄存器使用判断 ──
// rs1_used/rs2_used 是语义依赖判断，不是简单检查 rs 字段是否存在。
// CSR 立即数形式使用 zimm（inst[19:15]），不读取 rs1。
wire rs1_used = (is_jalr | is_branch | is_load | is_store
               | is_cal_i | is_cal_r | is_csr_reg)
              & (|rs1_addr_raw);
wire rs2_used = (is_branch | is_store | is_cal_r) & |rs2_addr_raw;

// ── 目的寄存器写使能 ──
// rd_wen 在 ID 阶段屏蔽 x0；未识别 opcode 的类型信号全 0。
wire rd_wen = (is_lui | is_auipc | is_jal | is_jalr
              | is_load | is_cal_i | is_cal_r | is_csr)
             & (|rd_addr_raw);

// ── 输出：decode_pkt_t ──
assign data_o.pc         = pc;
assign data_o.inst       = inst;
assign data_o.pred_taken = data_i.pred_taken;
assign data_o.rs1_used   = rs1_used;
assign data_o.rs2_used   = rs2_used;
assign data_o.rd_wen     = rd_wen;
assign data_o.imm        = imm;

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

// ── MEM 控制信号 ──
assign data_o.mem.cmd = {is_store, is_load};

// ── SYS 控制信号 ──
// CSR/系统控制：
//   csr_cmd    : NONE/WRITE/SET/CLEAR，由 CSR funct3[1:0] 压缩得到
//   priv_redir : ECALL/MRET 提交点重定向，编码上天然互斥
//   fence_i    : 与特权重定向分开，贴近 Rocket/Ibex 的语义分层
assign data_o.sys.csr_cmd    = {2{is_csr}} & func3[1:0];
assign data_o.sys.priv_redir = {is_mret, is_ecall};
assign data_o.sys.fence_i    = is_fence_i;

// ── 流水线握手 ──
assign valid_o = valid_i;
assign ready_o = ready_i;

endmodule
