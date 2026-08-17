// exu (Execution Unit)
// 非访存指令执行；访存由 LSU 处理
// CSR：此处只准备 csr_src 写入 ROB.result，真正读写 CSR / 写 rd 在 commit 点（对齐五级 WBU）
// ecall/mret/fence.i：只打 redirect 标记，目标在 commit 用 CSR.mtvec/mepc 或 pc+4 确定

`include "./include/pipeline_pkt_pkg.sv"

module exu
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    input               valid_i,
    input   issue2ex_pkt_t data_i,
    output              ready_o,

    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,
    output logic [31:0] complete_data_o,
    output logic        complete_exception_o,
    output logic [3:0]  complete_cause_o,
    output logic        complete_redirect_valid_o,
    output logic [31:0] complete_redirect_addr_o,

    output logic        wakeup_en_o,
    output logic [5:0]  wakeup_preg_o,

    output logic        redirect_valid_o,
    output logic [31:0] redirect_addr_o,

    output logic        bpu_update_valid_o,
    output logic        bpu_update_btb_type_o,
    output logic        bpu_update_taken_o,
    output logic [31:0] bpu_update_pc_o,
    output logic [31:0] bpu_update_target_o
);

wire is_mem  = (data_i.mem.cmd != MEM_NONE);
wire ex_fire = valid_i & ~is_mem;

wire [31:0] seq_pc = data_i.pc + 32'd4;

// ── ALU 输入 ──
logic [31:0] alu_src1, alu_src2;

always_comb begin
    case (data_i.ex.alu_src)
        ALU_SRC_RS1_RS2: begin alu_src1 = data_i.rs1_data; alu_src2 = data_i.rs2_data; end
        ALU_SRC_RS1_IMM: begin alu_src1 = data_i.rs1_data; alu_src2 = data_i.imm;      end
        ALU_SRC_PC_4:    begin alu_src1 = data_i.pc;       alu_src2 = 32'h4;           end
        ALU_SRC_PC_IMM:  begin alu_src1 = data_i.pc;       alu_src2 = data_i.imm;      end
        default: begin alu_src1 = 32'h0; alu_src2 = 32'h0; end
    endcase
end

logic [31:0] alu_result;
logic        alu_zf;

ALU u_ALU (
    .alu_op     (data_i.ex.alu_op),
    .data1      (alu_src1),
    .data2      (alu_src2),
    .result     (alu_result),
    .zero_flag  (alu_zf)
);

// ── 分支 ──
logic branch_taken;
always_comb begin
    unique case (data_i.ex.br_cond)
        BR_EQ:   branch_taken =  alu_zf;
        BR_NE:   branch_taken = ~alu_zf;
        BR_LT:   branch_taken =  alu_result[0];
        BR_GE:   branch_taken = ~alu_result[0];
    endcase
end

wire redirect_is_branch = ~data_i.ex.cfi_type[1] &  data_i.ex.cfi_type[0];
wire redirect_is_jal    =  data_i.ex.cfi_type[1] & ~data_i.ex.cfi_type[0];
wire redirect_is_jalr   = &data_i.ex.cfi_type;
wire redirect_is_jump   =  data_i.ex.cfi_type[1];
wire redirect_is_cfi    = |data_i.ex.cfi_type;
wire actual_taken       = redirect_is_jump | (redirect_is_branch & branch_taken);

wire [31:0] redirect_base  = redirect_is_jalr ? data_i.rs1_data : data_i.pc;
wire [31:0] cfi_target_sum = redirect_base + data_i.imm;
wire [31:0] cfi_target     = redirect_is_jalr ? {cfi_target_sum[31:1], 1'b0} : cfi_target_sum;
wire [31:0] redirect_target = actual_taken ? cfi_target : seq_pc;

// 分支误预测（预测方向与实际不一致）
wire br_mispred = redirect_is_cfi & (actual_taken ^ data_i.pred_taken);

// ── CSR / 系统 ──
// csr_src 进入 ROB.result，commit 时作为 CSR 写入源；rd 旧值在 commit 读出
wire        csr_valid = data_i.sys.csr_cmd != CSR_CMD_NONE;
wire        csr_imm   = data_i.inst[14];
wire [31:0] csr_src   = csr_imm ? data_i.imm : data_i.rs1_data;

wire is_priv   = data_i.sys.priv_redir != PRIV_REDIR_NONE;
wire is_fence_i = data_i.sys.fence_i;

// jal/jalr/fence.i 的链接值/重定向默认目标为 pc+4
wire        seq_result = redirect_is_jump | is_fence_i;
wire [31:0] ex_result  = csr_valid  ? csr_src :
                         seq_result ? seq_pc  :
                                      alu_result;

// ── complete → ROB ──
assign complete_en_o   = ex_fire;
assign complete_idx_o  = data_i.rob_idx;
assign complete_data_o = ex_result;

// 译码 illegal 在分配时已标 complete；此处兜底：异常指令不再 redirect
wire has_exc = data_i.exception;
assign complete_exception_o = ex_fire & has_exc;
assign complete_cause_o     = has_exc ? data_i.exception_cause : 4'b0;

// 误预测 / fence.i / ecall / mret 均在 head 提交时 flush
// ecall/mret 的最终目标由顶层用 mtvec/mepc 覆盖；此处先填 seq_pc 占位
// 异常指令不打 redirect（由 exception 路径 trap）
assign complete_redirect_valid_o = ex_fire & ~has_exc & (br_mispred | is_fence_i | is_priv);
assign complete_redirect_addr_o  = br_mispred ? redirect_target : seq_pc;

// CSR 的 rd 必须在 commit 写 PRF 后才 wakeup，避免依赖读到 csr_src
assign wakeup_en_o   = ex_fire & data_i.rd_wen & ~csr_valid & ~has_exc;
assign wakeup_preg_o = data_i.phys_rd;

// 观测用
assign redirect_valid_o = ex_fire & br_mispred;
assign redirect_addr_o  = redirect_target;

assign bpu_update_valid_o    = ex_fire & (redirect_is_branch | redirect_is_jal);
assign bpu_update_btb_type_o = redirect_is_jal;
assign bpu_update_taken_o    = actual_taken;
assign bpu_update_pc_o       = data_i.pc;
assign bpu_update_target_o   = cfi_target;

assign ready_o = 1'b1;

endmodule
