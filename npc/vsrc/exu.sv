// exu (Execution Unit)
// 功能：从 issue_queue 接收非访存指令，执行后将结果写回 ROB 和唤醒等待指令
// 访存指令由顶层分流到 LSU，不进入 EXU 完成通路

`include "./include/pipeline_pkt_pkg.sv"

module exu
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    // 来自 issue_queue 的输入
    input               valid_i,
    input   issue2ex_pkt_t data_i,
    output              ready_o,

    // 完成信号 → ROB
    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,      // ROB index
    output logic [31:0] complete_data_o,
    output logic        complete_exception_o,
    output logic [3:0]  complete_cause_o,
    output logic        complete_redirect_valid_o,
    output logic [31:0] complete_redirect_addr_o,

    // 唤醒信号 → busy_table + issue_queue
    output logic        wakeup_en_o,
    output logic [5:0]  wakeup_preg_o,

    // 重定向信号 → 标记到 ROB（不直接 flush 前端；由 ROB 顺序 flush）
    output logic        redirect_valid_o,
    output logic [31:0] redirect_addr_o,

    // BPU 更新信号
    output logic        bpu_update_valid_o,
    output logic        bpu_update_btb_type_o,
    output logic        bpu_update_taken_o,
    output logic [31:0] bpu_update_target_o
);

// 双保险：即使顶层误送访存指令，也不 complete
wire is_mem = (data_i.mem.cmd != MEM_NONE);
wire ex_fire = valid_i & ~is_mem;

// ── 提取输入字段 ──
wire [31:0] seq_pc = data_i.pc + 4;

// ── ALU 输入选择 ──
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

// ── ALU ──
logic [31:0] alu_result;
logic        alu_zf;

ALU u_ALU (
    .alu_op     (data_i.ex.alu_op),
    .data1      (alu_src1),
    .data2      (alu_src2),
    .result     (alu_result),
    .zero_flag  (alu_zf)
);

// ── 分支条件判断 ──
logic branch_taken;

always_comb begin
    unique case (data_i.ex.br_cond)
        BR_EQ:   branch_taken =  alu_zf;
        BR_NE:   branch_taken = ~alu_zf;
        BR_LT:   branch_taken =  alu_result[0];
        BR_GE:   branch_taken = ~alu_result[0];
    endcase
end

// ── 控制流处理 ──
wire redirect_is_branch = ~data_i.ex.cfi_type[1] & data_i.ex.cfi_type[0];
wire redirect_is_jal    =  data_i.ex.cfi_type[1] & ~data_i.ex.cfi_type[0];
wire redirect_is_jalr   = &data_i.ex.cfi_type;
wire redirect_is_jump   = data_i.ex.cfi_type[1];
wire redirect_is_cfi    = |data_i.ex.cfi_type;
wire actual_taken       = redirect_is_jump | (redirect_is_branch & branch_taken);

wire [31:0] redirect_base   = redirect_is_jalr ? data_i.rs1_data : data_i.pc;
wire [31:0] cfi_target_sum  = redirect_base + data_i.imm;
wire [31:0] cfi_target      = redirect_is_jalr ? {cfi_target_sum[31:1], 1'b0} : cfi_target_sum;
wire [31:0] redirect_target = actual_taken ? cfi_target : seq_pc;

wire redirect_valid = redirect_is_cfi & (actual_taken ^ data_i.pred_taken);

// ── CSR 指令处理 ──
// CSR 源值先放进 result；完整 CSR 读写仍待后续 WBU/CSR 模块接入
wire        csr_valid = data_i.sys.csr_cmd != CSR_CMD_NONE;
wire        csr_imm   = data_i.inst[14];
wire [31:0] csr_src   = csr_imm ? data_i.imm : data_i.rs1_data;
wire        seq_result = redirect_is_jump | data_i.sys.fence_i;

wire [31:0] ex_result = csr_valid  ? csr_src :
                        seq_result ? seq_pc  :
                                     alu_result;

// ── 输出：完成信号 → ROB ──
assign complete_en_o   = ex_fire;
assign complete_idx_o  = data_i.rob_idx;
assign complete_data_o = ex_result;

// 系统异常/特权重定向：在 complete 时标记，等 ROB 顺序到 head 再 flush
// ecall/mret：用 priv_redir 标记 exception，flush_pc 暂用 pc+4（后续接 CSR）
wire is_priv_redir = (data_i.sys.priv_redir != PRIV_REDIR_NONE);
wire is_fence_i    = data_i.sys.fence_i;

// fence.i：当作 redirect 到 pc+4，触发前端 icache inval + redirect
// ecall/mret：exception 路径
assign complete_exception_o       = ex_fire & is_priv_redir;
assign complete_cause_o           = is_priv_redir ?
                                    (data_i.sys.priv_redir == PRIV_REDIR_ECALL ? 4'd11 : 4'd0) :
                                    4'b0;
// 分支误预测 或 fence.i 都走 redirect 标记
assign complete_redirect_valid_o  = ex_fire & (redirect_valid | is_fence_i);
assign complete_redirect_addr_o   = is_fence_i ? seq_pc : redirect_target;

// ── 输出：唤醒信号 → busy_table + issue_queue ──
assign wakeup_en_o   = ex_fire & data_i.rd_wen;
assign wakeup_preg_o = data_i.phys_rd;

// ── 输出：重定向信号（仅供观测/BPU；真正 flush 由 ROB 发起）──
assign redirect_valid_o = ex_fire & redirect_valid;
assign redirect_addr_o  = redirect_target;

// ── 输出：BPU 更新 ──
assign bpu_update_valid_o    = ex_fire & (redirect_is_branch | redirect_is_jal);
assign bpu_update_btb_type_o = redirect_is_jal;
assign bpu_update_taken_o    = actual_taken;
assign bpu_update_target_o   = cfi_target;

// ── 流水线控制 ──
assign ready_o = 1'b1;

endmodule
