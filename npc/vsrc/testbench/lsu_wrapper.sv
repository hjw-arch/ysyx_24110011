// LSU_ooo Wrapper - 将 packed struct 展平为独立信号，便于测试

`include "./include/pipeline_pkt_pkg.sv"

module lsu_wrapper
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
    input   [3:0]       alu_op_i,
    input   [1:0]       alu_src_i,
    input   [1:0]       cfi_type_i,
    input   [2:0]       br_cond_i,
    input   [2:0]       mem_cmd_i,
    input   [1:0]       csr_cmd_i,
    input   [1:0]       priv_redir_i,
    input               fence_i_i,
    input   [31:0]      imm_i,

    input               flush_i,
    output              ready_o,

    // 输出信号
    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,
    output logic [31:0] complete_data_o,
    output logic        complete_exception_o,
    output logic [3:0]  complete_cause_o,
    output logic        complete_rd_wen_o,
    output logic [5:0]  complete_phys_rd_o,

    // AXI 接口
    output logic [31:0] ARADDR,
    output logic [3:0]  ARID,
    output logic [7:0]  ARLEN,
    output logic [2:0]  ARSIZE,
    output logic [1:0]  ARBURST,
    output logic        ARVALID,
    input               ARREADY,

    input        [3:0]  RID,
    input        [31:0] RDATA,
    input        [1:0]  RRESP,
    input               RVALID,
    input               RLAST,
    output logic        RREADY,

    output logic [31:0] AWADDR,
    output logic [7:0]  AWLEN,
    output logic [2:0]  AWSIZE,
    output logic [3:0]  AWID,
    output logic [1:0]  AWBURST,
    output logic        AWVALID,
    input               AWREADY,

    output logic [31:0] WDATA,
    output logic        WLAST,
    output logic [3:0]  WSTRB,
    output logic        WVALID,
    input               WREADY,

    input        [3:0]  BID,
    input        [1:0]  BRESP,
    input               BVALID,
    output logic        BREADY
);

// 组装 issue2ex_pkt_t
issue2ex_pkt_t data_packed;

always_comb begin
    data_packed.pc          = pc_i;
    data_packed.inst        = inst_i;
    data_packed.rob_idx     = rob_idx_i;
    data_packed.phys_rd     = phys_rd_i;
    data_packed.rs1_data    = rs1_data_i;
    data_packed.rs2_data    = rs2_data_i;
    data_packed.pred_taken  = pred_taken_i;
    data_packed.rd_wen      = rd_wen_i;
    data_packed.imm         = imm_i;

    // ex_ctrl_t
    data_packed.ex.alu_op       = alu_op_i;
    data_packed.ex.alu_src      = alu_src_i;
    data_packed.ex.cfi_type     = cfi_type_i;
    data_packed.ex.br_cond      = br_cond_i;
    data_packed.ex.fwd_rs1_sel  = 2'b00;
    data_packed.ex.fwd_rs2_sel  = 2'b00;

    // mem_ctrl_t
    data_packed.mem.cmd         = mem_cmd_i;

    // sys_ctrl_t
    data_packed.sys.csr_cmd     = csr_cmd_i;
    data_packed.sys.priv_redir  = priv_redir_i;
    data_packed.sys.fence_i     = fence_i_i;
end

// 实例化真正的 LSU_ooo
lsu u_lsu (
    .clk                    (clk),
    .rst                    (rst),
    .valid_i                (valid_i),
    .data_i                 (data_packed),
    .ready_o                (ready_o),
    .flush_i                (flush_i),
    .complete_en_o          (complete_en_o),
    .complete_idx_o         (complete_idx_o),
    .complete_data_o        (complete_data_o),
    .complete_exception_o   (complete_exception_o),
    .complete_cause_o       (complete_cause_o),
    .complete_rd_wen_o      (complete_rd_wen_o),
    .complete_phys_rd_o     (complete_phys_rd_o),
    .ARADDR                 (ARADDR),
    .ARID                   (ARID),
    .ARLEN                  (ARLEN),
    .ARSIZE                 (ARSIZE),
    .ARBURST                (ARBURST),
    .ARVALID                (ARVALID),
    .ARREADY                (ARREADY),
    .RID                    (RID),
    .RDATA                  (RDATA),
    .RRESP                  (RRESP),
    .RVALID                 (RVALID),
    .RLAST                  (RLAST),
    .RREADY                 (RREADY),
    .AWADDR                 (AWADDR),
    .AWLEN                  (AWLEN),
    .AWSIZE                 (AWSIZE),
    .AWID                   (AWID),
    .AWBURST                (AWBURST),
    .AWVALID                (AWVALID),
    .AWREADY                (AWREADY),
    .WDATA                  (WDATA),
    .WLAST                  (WLAST),
    .WSTRB                  (WSTRB),
    .WVALID                 (WVALID),
    .WREADY                 (WREADY),
    .BID                    (BID),
    .BRESP                  (BRESP),
    .BVALID                 (BVALID),
    .BREADY                 (BREADY)
);

endmodule
