`include "./include/pipeline_pkt_pkg.sv"

module CSR
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    input               wen,
    input   csr_cmd_t   cmd,
    input   [11:0]      addr,
    input   [31:0]      wdata,

    // trap：ecall 或精确异常（illegal / access fault）
    input               trap_i,
    input   [31:0]      trap_pc_i,
    input   [31:0]      trap_cause_i,

    output  logic [31:0] rdata_o,
    output  [31:0]      mtvec_o,
    output  [31:0]      mepc_o
);

localparam logic [11:0] CSR_MSTATUS  = 12'h300;
localparam logic [11:0] CSR_MTVEC    = 12'h305;
localparam logic [11:0] CSR_MEPC     = 12'h341;
localparam logic [11:0] CSR_MCAUSE   = 12'h342;
localparam logic [11:0] CSR_MVENDORID= 12'hF11;
localparam logic [11:0] CSR_MARCHID  = 12'hF12;

localparam logic [31:0] MVENDORID_VALUE = 32'h7973_7978;
localparam logic [31:0] MARCHID_VALUE   = 32'h016f_e3bb;

logic [31:0] mstatus_r;
logic [31:0] mtvec_r;
logic [31:0] mepc_r;
logic [31:0] mcause_r;

wire is_mstatus = addr == CSR_MSTATUS;
wire is_mtvec   = addr == CSR_MTVEC;
wire is_mepc    = addr == CSR_MEPC;
wire is_mcause  = addr == CSR_MCAUSE;

// CSR 读是组合逻辑，commit 用旧值写回 rd；CSR 写在同一个时钟沿提交。
always_comb begin
    unique case (addr)
        CSR_MSTATUS:   rdata_o = mstatus_r;
        CSR_MTVEC:     rdata_o = mtvec_r;
        CSR_MEPC:      rdata_o = mepc_r;
        CSR_MCAUSE:    rdata_o = mcause_r;
        CSR_MVENDORID: rdata_o = MVENDORID_VALUE;
        CSR_MARCHID:   rdata_o = MARCHID_VALUE;
        default:       rdata_o = 32'b0;
    endcase
end

logic [31:0] csr_wdata;
always_comb begin
    unique case (cmd)
        CSR_CMD_WRITE: csr_wdata = wdata;
        CSR_CMD_SET:   csr_wdata = rdata_o | wdata;
        CSR_CMD_CLEAR: csr_wdata = rdata_o & ~wdata;
        default:       csr_wdata = rdata_o;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        mstatus_r <= 32'h0000_1800;
        mtvec_r   <= 32'b0;
        mepc_r    <= 32'b0;
        mcause_r  <= 32'b0;
    end else begin
        if (trap_i) begin
            mepc_r    <= trap_pc_i;
            mcause_r  <= trap_cause_i;
            mstatus_r <= 32'h0000_1800;
        end else if (wen) begin
            if (is_mstatus) mstatus_r <= csr_wdata;
            if (is_mtvec)   mtvec_r   <= csr_wdata;
            if (is_mepc)    mepc_r    <= csr_wdata;
            if (is_mcause)  mcause_r  <= csr_wdata;
        end
    end
end

assign mtvec_o = mtvec_r;
assign mepc_o  = mepc_r;

endmodule
