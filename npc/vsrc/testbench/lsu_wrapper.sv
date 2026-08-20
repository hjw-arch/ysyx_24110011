// LSU wrapper — 展平 issue 包 + SQ/CAM 口，便于 C++ TB

`include "./include/pipeline_pkt_pkg.sv"

module lsu_wrapper
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

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
    input   [1:0]       mem_cmd_i,
    input   [1:0]       csr_cmd_i,
    input   [1:0]       priv_redir_i,
    input               fence_i_i,
    input   [31:0]      imm_i,

    input               flush_i,
    output              ready_o,

    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,
    output logic [31:0] complete_data_o,
    output logic        complete_exception_o,
    output logic [3:0]  complete_cause_o,
    output logic        complete_rd_wen_o,
    output logic [5:0]  complete_phys_rd_o,

    // SQ alloc
    output logic        sq_alloc_en_o,
    output logic [4:0]  sq_alloc_rob_idx_o,
    output logic [31:0] sq_alloc_addr_o,
    output logic [31:0] sq_alloc_data_o,
    output logic [3:0]  sq_alloc_strb_o,
    output logic [1:0]  sq_alloc_size_o,
    input               sq_alloc_ready_i,

    // CAM
    output logic [31:0] cam_addr_o,
    output logic [1:0]  cam_size_o,
    input               cam_hit_i,
    input               cam_stall_i,
    input   [31:0]      cam_data_i,

    // drain
    input               drain_req_i,
    input   [31:0]      drain_addr_i,
    input   [31:0]      drain_data_i,
    input   [3:0]       drain_strb_i,
    input   [1:0]       drain_size_i,
    output logic        drain_fire_o,
    output logic        drain_done_o,
    output logic        drain_fault_o,

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

issue2ex_pkt_t data_packed;

assign data_packed.pc                 = pc_i;
assign data_packed.funct3             = inst_i[14:12];
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
    .sq_alloc_en_o          (sq_alloc_en_o),
    .sq_alloc_rob_idx_o     (sq_alloc_rob_idx_o),
    .sq_alloc_addr_o        (sq_alloc_addr_o),
    .sq_alloc_data_o        (sq_alloc_data_o),
    .sq_alloc_strb_o        (sq_alloc_strb_o),
    .sq_alloc_size_o        (sq_alloc_size_o),
    .sq_alloc_ready_i       (sq_alloc_ready_i),
    .cam_addr_o             (cam_addr_o),
    .cam_size_o             (cam_size_o),
    .cam_hit_i              (cam_hit_i),
    .cam_stall_i            (cam_stall_i),
    .cam_data_i             (cam_data_i),
    .drain_req_i            (drain_req_i),
    .drain_addr_i           (drain_addr_i),
    .drain_data_i           (drain_data_i),
    .drain_strb_i           (drain_strb_i),
    .drain_size_i           (drain_size_i),
    .drain_fire_o           (drain_fire_o),
    .drain_done_o           (drain_done_o),
    .drain_fault_o          (drain_fault_o),
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
