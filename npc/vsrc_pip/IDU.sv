`include "./include/pipeline_pkt_pkg.sv"
module IDU
import pipeline_pkt_pkg::*;
(
    output	[4:0] 			rs1_addr,
    output	[4:0] 			rs2_addr,
    input 	[31:0] 			rs1_data,
    input	[31:0] 			rs2_data,

	output	[4:0] 			id_rs1_addr,
	output	[4:0]			id_rs2_addr,
	output					id_rs1_used,
	output					id_rs2_used,
	input 					hazard,

    input					valid_i,
    input	if2id_pkt_t		data_i,
    output					ready_o,

	output					valid_o,
	output	id2ex_pkt_t		data_o,
	input 					ready_i
);

localparam logic [4:0] OPC_LUI      = 5'b01101;
localparam logic [4:0] OPC_AUIPC    = 5'b00101;
localparam logic [4:0] OPC_JAL      = 5'b11011;
localparam logic [4:0] OPC_JALR     = 5'b11001;
localparam logic [4:0] OPC_BRANCH   = 5'b11000;
localparam logic [4:0] OPC_LOAD     = 5'b00000;
localparam logic [4:0] OPC_STORE    = 5'b01000;
localparam logic [4:0] OPC_MISC_MEM = 5'b00011;
localparam logic [4:0] OPC_CAL_I    = 5'b00100;
localparam logic [4:0] OPC_CAL_R    = 5'b01100;
localparam logic [4:0] OPC_SYSTEM   = 5'b11100;

wire [31:0] inst    = data_i.inst;
wire [31:0] pc      = data_i.pc;
wire [4:0]  opcode  = inst[6:2];
wire [2:0]  func3   = inst[14:12];
wire        func7b5 = inst[30];

wire [4:0] rd_addr_raw  = inst[11:7];
wire [4:0] rs1_addr_raw = inst[19:15];
wire [4:0] rs2_addr_raw = inst[24:20];

wire is_lui      = opcode == OPC_LUI;
wire is_auipc    = opcode == OPC_AUIPC;
wire is_jal      = opcode == OPC_JAL;
wire is_jalr     = opcode == OPC_JALR;
wire is_branch   = opcode == OPC_BRANCH;
wire is_load     = opcode == OPC_LOAD;
wire is_store    = opcode == OPC_STORE;
wire is_misc_mem = opcode == OPC_MISC_MEM;
wire is_cal_i    = opcode == OPC_CAL_I;
wire is_cal_r    = opcode == OPC_CAL_R;
wire is_system   = opcode == OPC_SYSTEM;

// SYSTEM 指令按照 funct3 分成两类：
//   000: 特权/系统操作，例如 ecall/mret
//   001/010/011: CSR 寄存器源操作，CSRRW/CSRRS/CSRRC
//   101/110/111: CSR 立即数源操作，CSRRWI/CSRRSI/CSRRCI
//   100: 保留编码，这里不当作合法 CSR 指令处理
wire func3_is_csr = func3[1] | func3[0];
wire func3_is_sys = func3 == 3'b000;

wire is_csr      = is_system & func3_is_csr;
wire is_csr_imm  = is_csr & func3[2];
wire is_csr_reg  = is_csr & ~func3[2];
wire is_sysop    = is_system & func3_is_sys;

// ecall/mret 在 ID 阶段先解出来，避免 WBU 提交重定向路径上再做宽指令比较。
wire is_ecall    = is_sysop & (inst[31:20] == 12'h000);
wire is_mret     = is_sysop & (inst[31:20] == 12'h302);
// FENCE.I 最终也会重定向到 pc+4，但语义上是取指一致性/ICache 序列化事件，
// 因此单独保留为 fence_i，而不是混入 ecall/mret 的特权重定向编码。
wire is_fence_i  = is_misc_mem & (func3 == 3'b001);

wire is_calc     = is_cal_i | is_cal_r;
wire is_srai     = is_cal_i & (func3 == 3'b101) & func7b5;
wire calc_op3    = is_srai | (is_cal_r & func7b5);

// imm_sel 只在 ID 阶段用于生成 32 位立即数，真正进入 ID/EX 寄存器的是 imm。
// 这样 EX 阶段不再承担 inst -> imm_gen -> ALU/redirect 的组合路径。
//
// 编码：
//   IMM_I = 000, IMM_S = 001, IMM_Z = 011
//   IMM_J = 100, IMM_B = 101, IMM_U = 110
//
// 下面三条按位 assign 是配合上述编码设计的：
//   bit[2] 表示 U/J/B 这类高位布局
//   bit[1] 表示 U/Z 这类低位布局
//   bit[0] 表示 S/B/Z 这类低位布局
imm_sel_t imm_sel;
assign imm_sel[2] = is_lui | is_auipc | is_jal | is_branch;
assign imm_sel[1] = is_lui | is_auipc | is_csr_imm;
assign imm_sel[0] = is_store | is_branch | is_csr_imm;

logic [31:0] imm;
imm_gen u_imm_gen (
    .imm_sel_i (imm_sel),
    .inst_i    (inst),
    .imm_o     (imm)
);

// 这里是 hazard/forwarding 用的语义依赖，而不是简单判断 rs 字段是否存在。
// CSR 立即数形式使用 zimm，不读取 rs1。
wire rs1_used = (is_jalr | is_branch | is_load | is_store | is_cal_i | is_cal_r | is_csr_reg) & |rs1_addr_raw;
wire rs2_used = (is_branch | is_store | is_cal_r) & |rs2_addr_raw;

// rd_wen 在 ID 阶段顺手屏蔽 x0。后级如需原始 rd 字段，直接从随流水携带的 inst 中切片。
wire rd_wen = (is_lui | is_auipc | is_jal | is_jalr | is_load | is_cal_i | is_cal_r | is_csr) & |rd_addr_raw;

assign valid_o = valid_i & ~hazard;
assign ready_o = ready_i & ~hazard;

assign rs1_addr = rs1_addr_raw;
assign rs2_addr = rs2_addr_raw;

// hazard/forwarding 比较使用原始 rs 地址；used 在最后一级门控。
// 这样地址比较器不需要等待 used 解码结果，ID 阶段阻塞路径更短。
assign id_rs1_addr = rs1_addr_raw;
assign id_rs2_addr = rs2_addr_raw;
assign id_rs1_used = valid_i & rs1_used;
assign id_rs2_used = valid_i & rs2_used;

assign data_o.meta.pc   = pc;
assign data_o.meta.inst = inst;

assign data_o.ex.rs1_used = rs1_used;
assign data_o.ex.rs2_used = rs2_used;

// ALU 操作按 bit 直接生成，避免写成优先级 mux 链。
// 这部分更像一个小 PLA：
//   - LUI 使用 ALU_COPY2，即 ALU default data2 路径
//   - EQ/NE 分支使用 SUB 产生 zero_flag
//   - LT/GE 使用 SLT，LTU/GEU 使用 SLTU
//   - 普通计算指令大部分复用 funct3，op[3] 来自 funct7b5/srai
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

// mem.cmd 只告诉 LSU 是否为 load/store。访存宽度和符号扩展信息是 inst[14:12]
// 的直接切片，留到 LSU 本地解码，不重复进入流水寄存器。
assign data_o.mem.cmd = {is_store, is_load};

assign data_o.wb.rd_wen = rd_wen;

// CSR/系统控制：
//   csr_cmd    : NONE/WRITE/SET/CLEAR，由 CSR funct3[1:0] 压缩得到
//   priv_redir : ECALL/MRET 提交点重定向，编码上天然互斥
//   fence_i    : 与特权重定向分开，贴近 Rocket/Ibex 的语义分层
// CSR 地址、zimm、rd、访存宽度都能从随流水携带的 inst 直接切片，因此不额外传。
assign data_o.sys.csr_cmd    = {2{is_csr}} & func3[1:0];
assign data_o.sys.priv_redir = {is_mret, is_ecall};
assign data_o.sys.fence_i    = is_fence_i;

assign data_o.rs1_data = rs1_data;
assign data_o.rs2_data = rs2_data;
assign data_o.imm      = imm;



/************************** 性能计数器 *****************************/

// import "DPI-C" function void PerformanceCounter_idu_identify_inst(input int inst);

// always_ff @(posedge clk) begin
// 	if (idu_valid & (state != S_WAIT_READY)) PerformanceCounter_idu_identify_inst(inst);
// end

// always_ff @(posedge clk) begin
// 	if (has_new_data) $display("IDU!\n");
// end


/******************************************************************/


endmodule



module imm_gen
import pipeline_pkt_pkg::*;
(
    input  imm_sel_t    imm_sel_i,
    input  logic [31:0] inst_i,
    output logic [31:0] imm_o
);

// 按位切片的立即数生成器。
//
// 如果直接对 IMM_I/S/B/U/J/Z 写一个完整 case，综合后容易像一个 32 位宽 mux。
// 这里参考 Rocket ImmGen 的思路：按立即数的 bit 段分别生成，每段只在少数几个
// 可能来源之间选择。
//
// IDU 只会送入这些合法编码：
//   IMM_I = 000, IMM_S = 001, IMM_Z = 011
//   IMM_J = 100, IMM_B = 101, IMM_U = 110
wire sel_i  = ~|imm_sel_i;                                   // IMM_I = 000
wire sel_s  = ~imm_sel_i[2] & ~imm_sel_i[1] & imm_sel_i[0];  // IMM_S = 001
wire sel_u  =  imm_sel_i[2] &  imm_sel_i[1];                 // IMM_U = 110
wire sel_z  =  imm_sel_i[1] &  imm_sel_i[0];                 // IMM_Z = 011
wire sel_uj =  imm_sel_i[2] & ~imm_sel_i[0];                 // IMM_U/J
wire sel_j  =  imm_sel_i[2] & ~imm_sel_i[1] & ~imm_sel_i[0]; // IMM_J = 100
wire sel_b  =  imm_sel_i[2] &  imm_sel_i[0];                 // IMM_B = 101

wire sign = inst_i[31] & ~sel_z;

wire [10:0] imm_30_20 = sel_u  ? inst_i[30:20] : {11{sign}};
wire [7:0]  imm_19_12 = sel_uj ? inst_i[19:12] : {8{sign}};


// imm[11] 在 J/B/符号扩展之间来源不同，单独处理。
wire imm_11 = sel_u ? 1'b0      :
              sel_j ? inst_i[20] :
              sel_b ? inst_i[7]  :
                      sign;

wire [5:0] imm_10_5 = (sel_u | sel_z) ? 6'b0 : inst_i[30:25];

// imm[4:1] 是 IMM_* 编码这样安排的主要原因：
//   imm_sel[1:0] 可以直接选择 I/J、S/B、U、Z 四种布局。
logic [3:0] imm_4_1;
always_comb begin
    unique case (imm_sel_i[1:0])
        2'b00: imm_4_1 = inst_i[24:21]; // I/J
        2'b01: imm_4_1 = inst_i[11:8];  // S/B
        2'b10: imm_4_1 = 4'b0;          // U
        2'b11: imm_4_1 = inst_i[19:16]; // Z
        default: imm_4_1 = 4'b0;
    endcase
end

wire imm_0 = sel_i ? inst_i[20] :
             sel_s ? inst_i[7]  :
             sel_z ? inst_i[15] :
                     1'b0;

assign imm_o = {
    sign,
    imm_30_20,
    imm_19_12,
    imm_11,
    imm_10_5,
    imm_4_1,
    imm_0
};

endmodule
