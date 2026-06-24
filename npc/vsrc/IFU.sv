`include "./include/pipeline_pkt_pkg.sv"
module IFU
import pipeline_pkt_pkg::*;
(
    input			        clk,
    input			        rst,

    output	[31:0] 	        ARADDR,
    output			        ARVALID,
    output 			        RREADY,
    output	[3:0] 	        ARID,
    output	[7:0] 	        ARLEN,
    output	[2:0] 	        ARSIZE,
    output	[1:0] 	        ARBURST,

    input 			        ARREADY,
    input 			        RVALID,
    input 			        RLAST,
    input	[3:0] 	        RID,
    input	[31:0] 	        RDATA,
    input	[1:0] 	        RRESP,

	input 			        icache_inval_i /* verilator public_flat_rd */, // icache 内容失效
	input	[31:0] 	        redirect_pc_i,          // 重定向后的 PC
	input			        redirect_valid_i /* verilator public_flat_rd */, // 确认推测错误，需要刷新流水线

    input                   bpu_update_valid_i,
    input                   bpu_update_type_i,
    input                   bpu_update_taken_i,
    input   [31:0]          bpu_update_pc_i,
    input   [31:0]          bpu_update_target_i,

    output 			        valid_o,
    output	if2id_pkt_t     data_o,
    input 			        ready_i
);

`ifdef SOC
localparam  RST_PC   =   32'h30000000;
`else
localparam  RST_PC   =   32'h80000000;
`endif

// ==========================================
// 内部信号 —— IFU ↔ ICache
// ==========================================

logic				ic_req_valid /* verilator public_flat_rd */;
logic	[31:0]		ic_req_addr;
logic               ic_req_pred_taken;
logic				ic_req_ready /* verilator public_flat_rd */;

logic				ic_resp_valid /* verilator public_flat_rd */;
logic	[31:0]		ic_resp_data;
logic	[31:0]		ic_resp_addr;/* verilator lint_off UNUSEDSIGNAL */
logic               ic_resp_pred_taken;
logic               ic_resp_err;
logic				ic_resp_ready /* verilator public_flat_rd */;



// ==========================================
// 1. PC 寄存器
// ==========================================
wire	ic_req_fire	= ic_req_valid & ic_req_ready;

logic   [31:0]  pc_r /* verilator public_flat_rd */;
logic   [31:0]  pc_n;
wire    [31:0]  pc_plus4;

logic           bpu_pred_taken;
logic   [31:0]  bpu_pred_pc;

assign pc_plus4 = pc_r + 32'd4;

assign pc_n	=	redirect_valid_i ? redirect_pc_i :   // 这里当前设置为重定向当拍不发请求，因为控制逻辑复杂。后续icache改成2级流水线可以考虑当拍重定向
				ic_req_fire ? (bpu_pred_taken ? bpu_pred_pc : pc_plus4) :
				pc_r;

always_ff @(posedge clk) begin
    if (rst) begin
        pc_r <= RST_PC;
    end else begin
        pc_r <= pc_n;
    end
end

// ==========================================
// 2. 对 ICache 的请求
// ==========================================
assign	ic_req_valid	=	~redirect_valid_i;
assign	ic_req_addr		=	pc_r;
assign  ic_req_pred_taken = bpu_pred_taken;


// ==========================================
// 3. 对下游的输出
// ==========================================

assign	valid_o		= ic_resp_valid & ~redirect_valid_i; // 实际上不要 ~redirect_valid_i 也行，由 icache 自己处理
assign	data_o.inst = ic_resp_data;
assign	data_o.pc	= ic_resp_addr;
assign  data_o.pred_taken = ic_resp_pred_taken;

// ready 信号
assign	ic_resp_ready = redirect_valid_i | ready_i;


// ==========================================
// 5. Refill 通道内部连线（icache ↔ adapter）
// ==========================================
logic                   refill_req_valid;
logic [31:0]            refill_req_addr;
logic                   refill_req_ready;
logic                   refill_resp_valid;
logic [127:0]           refill_resp_data;
logic                   refill_resp_err;
logic                   refill_resp_ready;


// ==========================================
// 6. ICache 例化
// ==========================================
icache #(
    .ADDR_WIDTH(32),
    .LINE_BYTES(16),
    .NUM_LINES (4)
) u_icache (
    .clk                (clk),
    .rst                (rst),
    // IFU ↔ ICache
    .req_valid_i        (ic_req_valid),
    .req_addr_i         (ic_req_addr),
    .req_pred_taken_i   (ic_req_pred_taken),
    .req_ready_o        (ic_req_ready),
    .resp_valid_o       (ic_resp_valid),
    .resp_data_o        (ic_resp_data),
    .resp_addr_o        (ic_resp_addr),
    .resp_pred_taken_o  (ic_resp_pred_taken),
    .resp_err_o         (ic_resp_err),
    .resp_ready_i       (ic_resp_ready),
    .kill_i             (redirect_valid_i),
    .inval_i            (icache_inval_i),
    // ICache ↔ Adapter
    .refill_req_valid_o (refill_req_valid),
    .refill_req_addr_o  (refill_req_addr),
    .refill_req_ready_i (refill_req_ready),
    .refill_resp_valid_i(refill_resp_valid),
    .refill_resp_data_i (refill_resp_data),
    .refill_resp_err_i  (refill_resp_err),
    .refill_resp_ready_o(refill_resp_ready)
);

// ==========================================
// 7. Branch Prediction Unit
// ==========================================
BPU #(
    .ADDR_WIDTH  (32),
    .BTB_ENTRIES (4),
    .BHT_ENTRIES (32)
) u_BPU (
    .clk                (clk),
    .rst                (rst),
    .pc_i               (pc_r),
    .pred_taken_o       (bpu_pred_taken),
    .pred_pc_o          (bpu_pred_pc),
    .update_valid_i     (bpu_update_valid_i),
    .update_type_i      (bpu_update_type_i),
    .update_taken_i     (bpu_update_taken_i),
    .update_pc_i        (bpu_update_pc_i),
    .update_target_i    (bpu_update_target_i),
    .inval_i            (icache_inval_i)
);
// ==========================================
// 7. AXI Read Adapter 例化
// ==========================================
axi_read_adapter u_axi_adapter (
    .clk                (clk),
    .rst                (rst),
    // Adapter ↔ ICache
    .req_valid_i        (refill_req_valid),
    .req_addr_i         (refill_req_addr),
    .req_ready_o        (refill_req_ready),
    .resp_valid_o       (refill_resp_valid),
    .resp_data_o        (refill_resp_data),
    .resp_err_o         (refill_resp_err),
    .resp_ready_i       (refill_resp_ready),
    // Adapter ↔ AXI Bus
    .ARADDR             (ARADDR),
    .ARVALID            (ARVALID),
    .ARLEN              (ARLEN),
    .ARSIZE             (ARSIZE),
    .ARBURST            (ARBURST),
    .ARID               (ARID),
    .ARREADY            (ARREADY),
    .RDATA              (RDATA),
    .RVALID             (RVALID),
    .RLAST              (RLAST),
    .RRESP              (RRESP),
    .RID                (RID),
    .RREADY             (RREADY)
);

endmodule
