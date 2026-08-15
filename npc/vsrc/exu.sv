// exu (Execution Unit)
// 功能：从 issue_queue 接收指令，执行后将结果写回 ROB 和唤醒等待指令

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

    // 重定向信号 → Frontend (分支误预测/跳转)
    output logic        redirect_valid_o,
    output logic [31:0] redirect_addr_o,

    // BPU 更新信号
    output logic        bpu_update_valid_o,
    output logic        bpu_update_btb_type_o,
    output logic        bpu_update_taken_o,
    output logic [31:0] bpu_update_target_o
);

// ── 提取输入字段（用于可读性）──
wire [31:0] seq_pc = data_i.pc + 4;

// OoO: 不再需要前递选择，rs1/rs2_data 已经是正确的物理寄存器值
// （重命名阶段已解决 RAW）

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

// ── 控制流处理 ──
// 控制流目标地址：
//   branch/jal 使用 pc  + imm
//   jalr       使用 rs1 + imm，并清掉 bit0
//
// 注意这里不能把 branch not-taken 的恢复地址 pc+4 也塞进这个加法器。
// 否则路径会变成 branch_taken -> addend mux -> 32位加法器 -> 输出，
// 分支比较结果直接控制加法器输入，时序非常差。
// 因此 pc+4 在 ID 阶段提前算成 seq_pc；EXU 这里只计算真实 CFI target。
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
// CSR 指令的写入源在 EXU 准备好，后续 WBU 用 result 作为 csr_src。
// CSR immediate 形式使用 ID 阶段生成的 zimm immediate；寄存器形式使用 rs1_data。
wire        csr_valid = data_i.sys.csr_cmd != CSR_CMD_NONE;
wire        csr_imm   = data_i.inst[14];
wire [31:0] csr_src   = csr_imm ? data_i.imm : data_i.rs1_data;
wire        seq_result = redirect_is_jump | data_i.sys.fence_i;

wire [31:0] ex_result = csr_valid  ? csr_src :
                        seq_result ? seq_pc  :
                                     alu_result;

// ── 输出：完成信号 → ROB ──
assign complete_en_o   = valid_i;
assign complete_idx_o  = data_i.rob_idx;
assign complete_data_o = ex_result;

// OoO: EXU 不处理访存和系统指令的异常（由 LSU 和 WBU 处理）
assign complete_exception_o       = 1'b0;
assign complete_cause_o           = 4'b0;
assign complete_redirect_valid_o  = redirect_valid;
assign complete_redirect_addr_o   = redirect_target;

// ── 输出：唤醒信号 → busy_table + issue_queue ──
// 只有写寄存器的指令才需要唤醒
assign wakeup_en_o   = valid_i & data_i.rd_wen;
assign wakeup_preg_o = data_i.phys_rd;

// ── 输出：重定向信号 → Frontend ──
assign redirect_valid_o = valid_i & redirect_valid;
assign redirect_addr_o  = redirect_target;

// ── 输出：BPU 更新 ──
assign bpu_update_valid_o    = valid_i & (redirect_is_branch | redirect_is_jal);
assign bpu_update_btb_type_o = redirect_is_jal;
assign bpu_update_taken_o    = actual_taken;
assign bpu_update_target_o   = cfi_target;

// ── 流水线控制 ──
// OoO: EXU 总是可以接收（不需要 stall），因为 issue_queue 已做好调度
assign ready_o = 1'b1;

endmodule
