`include "./include/pipeline_pkt_pkg.sv"

module EXU
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    output  [4:0]       rd_addr_o,
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
wire [31:0] seq_pc   = data_i.seq_pc;
wire [31:0] rs1_raw  = data_i.rs1_data;
wire [31:0] rs2_raw  = data_i.rs2_data;
wire [31:0] imm      = data_i.imm;

wire [4:0] rd_addr = inst[11:7];

assign valid_o = valid_i;
assign ready_o = ready_i;

// 前递选择已经在 ID 阶段算好，EX 阶段只做一个小 mux。
// LS 数据来自当前 EX/LS packet 的 result；WB 数据来自 LS/WB packet 的 result。
// CSR 写回旧 CSR 值不走 EX 前递，相关性由 hazard 阻塞到 WB 后交给寄存器堆 bypass。
// fwd_sel 是 one-hot 编码：bit0 选 LS，bit1 选 WB，00 表示使用 RF 原值。
// 写成 AND/OR 结构，避免综合器按优先级 mux 处理，前递选择位到数据输出的逻辑更薄。
wire rs1_fwd_rf = ~(|data_i.ex.fwd_rs1_sel);
wire rs2_fwd_rf = ~(|data_i.ex.fwd_rs2_sel);

wire [31:0] rs1_data = ({32{data_i.ex.fwd_rs1_sel[0]}} & fwd_ls_data_i) |
                       ({32{data_i.ex.fwd_rs1_sel[1]}} & fwd_wb_data_i) |
                       ({32{rs1_fwd_rf}}                 & rs1_raw);
wire [31:0] rs2_data = ({32{data_i.ex.fwd_rs2_sel[0]}} & fwd_ls_data_i) |
                       ({32{data_i.ex.fwd_rs2_sel[1]}} & fwd_wb_data_i) |
                       ({32{rs2_fwd_rf}}                 & rs2_raw);

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

// 控制流目标地址：
//   branch/jal 使用 pc  + imm
//   jalr       使用 rs1 + imm，并清掉 bit0
//
// 注意这里不能把 branch not-taken 的恢复地址 pc+4 也塞进这个加法器。
// 否则路径会变成 branch_taken -> addend mux -> 32位加法器 -> EX/LS，
// 分支比较结果直接控制加法器输入，时序非常差。
// 因此 pc+4 在 ID 阶段提前算成 seq_pc；EXU这里只计算真实 CFI target。
wire redirect_is_branch = ~data_i.ex.cfi_type[1] & data_i.ex.cfi_type[0];
wire redirect_is_jal    =  data_i.ex.cfi_type[1] & ~data_i.ex.cfi_type[0];
wire redirect_is_jalr   = &data_i.ex.cfi_type;
wire redirect_is_jump   = data_i.ex.cfi_type[1];
wire redirect_is_cfi    = |data_i.ex.cfi_type;
wire actual_taken       = redirect_is_jump | (redirect_is_branch & branch_taken);

wire [31:0] redirect_base   = redirect_is_jalr ? rs1_data : pc;
wire [31:0] cfi_target_sum  = redirect_base + imm;
wire [31:0] cfi_target      = redirect_is_jalr ? {cfi_target_sum[31:1], 1'b0} : cfi_target_sum;
wire [31:0] redirect_target = actual_taken ? cfi_target : seq_pc;

wire redirect_valid = redirect_is_cfi & (actual_taken ^ data_i.meta.pred_taken);

// CSR 指令的写入源在 EXU 准备好，后续 WBU 用 result 作为 csr_src。
// CSR immediate 形式使用 ID 阶段生成的 zimm immediate；寄存器形式使用 rs1_data。
wire        csr_valid = data_i.sys.csr_cmd != CSR_CMD_NONE;
wire        csr_imm   = inst[14];
wire [31:0] csr_src   = csr_imm ? imm : rs1_data;
wire        seq_result = redirect_is_jump | data_i.sys.fence_i;

wire [31:0] ex_result = csr_valid  ? csr_src :
                        seq_result ? seq_pc  :
                                     alu_result;

assign data_o.meta       = data_i.meta;
assign data_o.mem        = data_i.mem;
assign data_o.wb         = data_i.wb;
assign data_o.sys        = data_i.sys;
assign data_o.result     = ex_result;
assign data_o.store_data = rs2_data;

// addr 在 valid=0 时无语义，直接接恢复地址，避免额外综合出清零 mux。
assign data_o.redirect.valid = redirect_valid;
assign data_o.redirect.addr  = redirect_target;

// BPU 只训练 direct CFI。jalr 暂不预测，后续若做 RAS 再单独处理。
assign data_o.bpu_update.valid  = redirect_is_branch | redirect_is_jal;
assign data_o.bpu_update.btb_type = redirect_is_jal;
assign data_o.bpu_update.taken  = actual_taken;
assign data_o.bpu_update.target = cfi_target;

// hazard 只关心真实会写回的指令，并且 rd=x0 已经在 IDU 的 rd_wen 中被屏蔽。
assign rd_addr_o = rd_addr & {5{valid_i & data_i.wb.rd_wen}};

endmodule
