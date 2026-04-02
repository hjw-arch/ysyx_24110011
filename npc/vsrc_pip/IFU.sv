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

	input 			        invalidate_ic_i,
	input	[31:0] 	        flush_addr_i,			// 真正的PC值
	input			        flush_i,				// 确认推测错误，需要刷新流水线

    output 			        valid_o,
    output	if2id_pkt_t     data_o,
    input 			        ready_i
);

localparam  RST_PC   =   32'h30000000;

// ==========================================
// 内部信号 —— IFU ↔ ICache
// ==========================================

logic				ic_req_valid;
logic	[31:0]		ic_req_addr;
logic				ic_req_epoch;
logic				ic_req_ready;

logic				ic_resp_valid;
logic	[31:0]		ic_resp_data;
logic	[31:0]		ic_resp_addr;
logic				ic_resp_epoch;/* verilator lint_off UNUSEDSIGNAL */
logic               ic_resp_err;
logic				ic_resp_ready;



// ==========================================
// 1. PC 寄存器
// ==========================================
wire	ic_req_fire	= ic_req_valid & ic_req_ready;

logic   [31:0]  pc_r, pc_n;

assign pc_n	=	flush_i ? flush_addr_i : 
				ic_req_fire ? pc_r + 4 : 
				pc_r;

always_ff @(posedge clk) begin
    if (rst) begin
        pc_r <= RST_PC; 
    end else begin
        pc_r <= pc_n; 
    end
end


// ==========================================
// 2. Epoch 寄存器
// ==========================================
logic	epoch_r, epoch_n;		// 1/2级流水线最多一个在途请求，因此1 bit epoch已经足够
assign	epoch_n	= flush_i ? ~epoch_r : epoch_r;

always_ff @(posedge clk) begin
	if (rst) begin
		epoch_r <= 1'b0;		// 是否存在复位必要？即使不存在在逻辑上也能走通
	end else begin
		epoch_r <= epoch_n;
	end
end


// ==========================================
// 3. 对 ICache 的请求
// ==========================================
assign	ic_req_valid	=	~invalidate_ic_i;
assign	ic_req_addr		=	flush_i ? flush_addr_i : pc_r;
assign	ic_req_epoch	=	flush_i ? ~epoch_r : epoch_r;


// ==========================================
// 4. 对下游的输出
// ==========================================
wire	epoch_match	= ic_resp_epoch ~^ epoch_r;

assign	valid_o		= ic_resp_valid & epoch_match;
assign	data_o.inst = ic_resp_data;
assign	data_o.pc	= ic_resp_addr;

// ready 信号
//	epoch 匹配 -> if/id反压
//	epoch 不匹配 -> 直接消费
assign	ic_resp_ready = epoch_match ? ready_i : 1'b1;


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
    .req_epoch_i        (ic_req_epoch),
    .req_ready_o        (ic_req_ready),
    .resp_valid_o       (ic_resp_valid),
    .resp_data_o        (ic_resp_data),
    .resp_addr_o        (ic_resp_addr),
    .resp_epoch_o       (ic_resp_epoch),
    .resp_err_o         (ic_resp_err),
    .resp_ready_i       (ic_resp_ready),
    .invalidate_all_i   (invalidate_ic_i),
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

/************************** 性能计数器 *****************************/

// import "DPI-C" function void is_finish_bootloader(input int pc);
// import "DPI-C" function void PerformanceCounter_ifu_fetch();
// import "DPI-C" function void PerformanceCounter_ifu_fetch_cycles(input int start, input int finish);
// import "DPI-C" function void PerformanceCounter_inst_type_total_cycles(input int start, input int inst);

// always_ff @(posedge clk) begin
// 	if (wbu_valid) is_finish_bootloader(pc);
// end

// always_ff @(posedge clk) begin
// 	if (i2c_valid) PerformanceCounter_ifu_fetch();
// end
// /* verilator lint_off WIDTHEXPAND */
// always_ff @(posedge clk) begin
// 	if (!rst) PerformanceCounter_ifu_fetch_cycles(start, i2c_valid);
// end

// always_ff @(posedge clk) begin
// 	if (!rst) PerformanceCounter_inst_type_total_cycles(start, i2c_inst);
// end


endmodule
