// EXU_ooo Wrapper - 将 packed struct 展平为独立信号，便于 C++ testbench 访问

`include "./include/pipeline_pkt_pkg.sv"

module exu_wrapper
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    // 展平的输入信号
    input               valid_i,
    input   [31:0]      pc_i,
    input   [31:0]      inst_i,
    input   [4:0]       rob_idx_i,
    input   [5:0]       phys_rd_i,
    input   [31:0]      rs1_data_i,
    input   [31:0]      rs2_data_i,
    input               pred_taken_i,
    input               rd_wen_i,
    // ex_ctrl_t 字段
    input   [3:0]       alu_op_i,
    input   [1:0]       alu_src_i,
    input   [1:0]       cfi_type_i,
    input   [1:0]       br_cond_i,
    // mem_ctrl_t 字段
    input   [2:0]       mem_cmd_i,
    // sys_ctrl_t 字段
    input   [1:0]       csr_cmd_i,
    input   [1:0]       priv_redir_i,
    input               fence_i_i,
    input   [31:0]      imm_i,

    output              ready_o,

    // 输出信号（保持原样）
    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,
    output logic [31:0] complete_data_o,
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

// 组装 issue2ex_pkt_t
issue2ex_pkt_t data_packed;

assign data_packed.pc                 = pc_i;
assign data_packed.funct3             = (cfi_type_i == CFI_BRANCH)
                                     ? {br_cond_i[1], 1'b0, br_cond_i[0]}
                                     : inst_i[14:12];
assign data_packed.rob_idx            = rob_idx_i;
assign data_packed.phys_rd            = phys_rd_i;
assign data_packed.rs1_data           = rs1_data_i;
assign data_packed.rs2_data           = rs2_data_i;
assign data_packed.pred_taken         = pred_taken_i;
assign data_packed.rd_wen             = rd_wen_i;
assign data_packed.ex.alu_op          = alu_op_i;
assign data_packed.ex.alu_src         = alu_src_i;
assign data_packed.ex.cfi_type        = cfi_type_i;
assign data_packed.mem.cmd            = mem_cmd_i;
assign data_packed.sys.csr_cmd        = csr_cmd_i;
assign data_packed.sys.priv_redir     = priv_redir_i;
assign data_packed.sys.fence_i        = fence_i_i;
assign data_packed.imm                = imm_i;

// 实例化真正的 EXU_ooo
exu u_exu (
    .clk                            (clk),
    .rst                            (rst),
    .valid_i                        (valid_i),
    .data_i                         (data_packed),
    .ready_o                        (ready_o),
    .complete_en_o                  (complete_en_o),
    .complete_idx_o                 (complete_idx_o),
    .complete_data_o                (complete_data_o),
    .complete_redirect_valid_o      (complete_redirect_valid_o),
    .complete_redirect_addr_o       (complete_redirect_addr_o),
    .wakeup_en_o                    (wakeup_en_o),
    .wakeup_preg_o                  (wakeup_preg_o),
    .redirect_valid_o               (redirect_valid_o),
    .redirect_addr_o                (redirect_addr_o),
    .bpu_update_valid_o             (bpu_update_valid_o),
    .bpu_update_btb_type_o          (bpu_update_btb_type_o),
    .bpu_update_taken_o             (bpu_update_taken_o),
    .bpu_update_pc_o                (bpu_update_pc_o),
    .bpu_update_target_o            (bpu_update_target_o)
);

endmodule
