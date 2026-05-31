`include "./include/pipeline_pkt_pkg.sv"

module EXU
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    output  [4:0]       rd_addr_hazard,
    input   [31:0]      fwd_ls_data_i,
    input   [31:0]      fwd_wb_data_i,

    input               valid_i,
    input   id2ex_pkt_t data_i,
    output              ready_o,

    output              valid_o,
    output  ex2ls_pkt_t data_o,
    input               ready_i
);

wire [31:0] inst     = data_i.meta.inst;
wire [31:0] pc       = data_i.meta.pc;
wire [31:0] rs1_raw  = data_i.rs1_data;
wire [31:0] rs2_raw  = data_i.rs2_data;
wire [31:0] imm      = data_i.imm;

wire [4:0] rd_addr = inst[11:7];

assign valid_o = valid_i;
assign ready_o = ready_i;

// 前递选择已经在 ID 阶段算好，EX 阶段只做一个小 mux。
// LS 数据来自当前 EX/LS packet 的 result；WB 数据来自 WBU 的真实写回值，
// 因此 CSR 指令写回旧 CSR 值时也能正确前递。
logic [31:0] rs1_data;
logic [31:0] rs2_data;

always_comb begin
    unique case (data_i.ex.fwd_rs1_sel)
        FWD_SEL_LS: rs1_data = fwd_ls_data_i;
        FWD_SEL_WB: rs1_data = fwd_wb_data_i;
        default:    rs1_data = rs1_raw;
    endcase
end

always_comb begin
    unique case (data_i.ex.fwd_rs2_sel)
        FWD_SEL_LS: rs2_data = fwd_ls_data_i;
        FWD_SEL_WB: rs2_data = fwd_wb_data_i;
        default:    rs2_data = rs2_raw;
    endcase
end

// ALU 输入选择：
//   00: rs1, rs2
//   01: rs1, imm
//   10: pc,  4
//   11: pc,  imm
// IDU 已经把 fence.i 配成 pc+4，因此 EXU 不需要额外识别 fence.i。
logic [31:0] alu_src1;
logic [31:0] alu_src2;

always_comb begin
    unique case (data_i.ex.alu_src)
        ALU_SRC_RS1_RS2: begin
            alu_src1 = rs1_data;
            alu_src2 = rs2_data;
        end
        ALU_SRC_RS1_IMM: begin
            alu_src1 = rs1_data;
            alu_src2 = imm;
        end
        ALU_SRC_PC_4: begin
            alu_src1 = pc;
            alu_src2 = 32'h4;
        end
        ALU_SRC_PC_IMM: begin
            alu_src1 = pc;
            alu_src2 = imm;
        end
    endcase
end

logic [31:0] alu_result;
logic        alu_zf;

ALU u_ALU (
    .alu_op     (data_i.ex.alu_op),
    .data1      (alu_src1        ),
    .data2      (alu_src2        ),
    .result     (alu_result      ),
    .zero_flag  (alu_zf          )
);

// 分支条件复用 ALU 结果：
//   EQ/NE 使用 SUB 的 zero_flag
//   LT/GE 使用 SLT/SLTU 的 bit0
logic branch_taken;

always_comb begin
    unique case (data_i.ex.br_cond)
        BR_EQ:   branch_taken =  alu_zf;
        BR_NE:   branch_taken = ~alu_zf;
        BR_LT:   branch_taken =  alu_result[0];
        BR_GE:   branch_taken = ~alu_result[0];
    endcase
end

// 控制流目标地址只保留一个加法器：
//   branch/jal 使用 pc  + imm
//   jalr       使用 rs1 + imm，并清掉 bit0
//
// jal/jalr 的写回值 pc+4 仍由主 ALU 产生。对于 branch，主 ALU 同拍还要做比较，
// 因此若希望 EX 阶段单拍给出 redirect，额外保留一个“目标地址加法器”是必要的。
// 这里把 pc+imm 和 rs1+imm 复用到同一个加法器，避免综合出两个并行 target adder。
wire        redirect_is_jalr = data_i.ex.cfi_type == CFI_JALR;
wire [31:0] redirect_base    = redirect_is_jalr ? rs1_data : pc;
wire [31:0] redirect_sum     = redirect_base + imm;
wire [31:0] redirect_target  = redirect_is_jalr ? {redirect_sum[31:1], 1'b0} : redirect_sum;

wire redirect_is_branch = data_i.ex.cfi_type == CFI_BRANCH;
wire redirect_is_jump   = data_i.ex.cfi_type[1];
wire redirect_valid     = redirect_is_jump | (redirect_is_branch & branch_taken);

// CSR 指令的写入源在 EXU 准备好，后续 WBU 用 result 作为 csr_src。
// CSR immediate 形式使用 ID 阶段生成的 zimm immediate；寄存器形式使用 rs1_data。
wire        csr_valid = data_i.sys.csr_cmd != CSR_CMD_NONE;
wire        csr_imm   = inst[14];
wire [31:0] csr_src   = csr_imm ? imm : rs1_data;

wire [31:0] ex_result = csr_valid ? csr_src : alu_result;

assign data_o.meta       = data_i.meta;
assign data_o.mem        = data_i.mem;
assign data_o.wb         = data_i.wb;
assign data_o.sys        = data_i.sys;
assign data_o.result     = ex_result;
assign data_o.store_data = rs2_data;

// addr 在 valid=0 时无语义，直接接 target，避免额外综合出清零 mux。
assign data_o.redirect.valid = redirect_valid;
assign data_o.redirect.addr  = redirect_target;

// hazard 只关心真实会写回的指令，并且 rd=x0 已经在 IDU 的 rd_wen 中被屏蔽。
assign rd_addr_hazard = rd_addr & {5{valid_i & data_i.wb.rd_wen}};

endmodule
