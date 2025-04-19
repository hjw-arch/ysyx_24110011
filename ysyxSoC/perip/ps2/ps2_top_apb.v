module ps2_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  input         ps2_clk,
  input         ps2_data
);

assign in_pslverr = 1'b0;
assign in_pready = 1'b1;

assign in_prdata = {24'b0, fifo_empty ? 8'b0 : fifo_rdata};

reg [3:0] cnt;				// 计数器
reg [8:0] rx_data;			// 数据

// 时钟同步
reg [2:0] ps2_clk_sync;
always_ff @(posedge clock) begin
	ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};		// 打两拍，防止亚稳态
end
wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];		// 下降沿

// 同步数据
reg ps2_data_ff1, ps2_data_ff2;
always_ff @(posedge clock) begin
	ps2_data_ff1 <= ps2_data;
	ps2_data_ff2 <= ps2_data_ff1;
end

wire ps2_data_sync = ps2_data_ff2;


// 处理数据
reg receiving;		// 接收数据中, 其实就是状态机
always_ff @(posedge clock) begin
	receiving <= reset | (cnt == 4'd9 && sampling) ? 1'b0 : 
				 (~receiving & sampling & ~ps2_data_sync) ? 1'b1 : receiving;
end

always_ff @(posedge clock) begin
	cnt <=		reset | (cnt == 4'd9 && sampling) ? 4'b0 :
				receiving & sampling ? cnt + 1 : cnt;
end

always_ff @(posedge clock) begin
	rx_data[cnt] <= receiving & sampling ? ps2_data_sync : rx_data[cnt];
end

wire fifo_wen, fifo_ren, fifo_empty, fifo_full;
wire [7:0] fifo_rdata;

assign fifo_wen = sampling && ^rx_data[8:0] && ps2_data_sync && cnt == 4'd9;
assign fifo_ren = in_psel & in_penable & ~in_pwrite;

FIFO #(8, 8) fifo (
	.clk(clock),
	.rst(reset),
	.wen(fifo_wen),
	.ren(fifo_ren),
	.wdata(rx_data[7:0]),
	.rdata(fifo_rdata),
	.empty(fifo_empty),
	.full(fifo_full)
);

always_ff @(posedge clock) begin
	if (sampling && ^rx_data[8:0] && ps2_data_sync && cnt == 4'd9) begin
		$display("receive data is %x", rx_data[7:0]);
	end
end


endmodule


// FIFO模块
module FIFO #(
	parameter DATA_WIDTH = 8,
	parameter FIFO_DEPTH = 8,
	parameter INDEX_WIDTH = $clog2(FIFO_DEPTH)
) (
	input 						clk,
	input						rst,
	input						wen,
	input 						ren,
	input 	[DATA_WIDTH-1:0]	wdata,
	output  [DATA_WIDTH-1:0]	rdata,
	output  					full,
	output 						empty
);

reg [DATA_WIDTH - 1 : 0] fifo_reg [0 : FIFO_DEPTH - 1];
reg [INDEX_WIDTH : 0] w_ptr, r_ptr;

assign empty = (w_ptr == r_ptr);
assign full  = (w_ptr[INDEX_WIDTH - 1 : 0] == r_ptr[INDEX_WIDTH - 1 : 0]) && (w_ptr[INDEX_WIDTH] != r_ptr[INDEX_WIDTH]);

// 写
always_ff @(posedge clk) begin
	w_ptr <= rst ? 0 : (wen && !full) ? w_ptr + 1 : w_ptr;
end

always_ff @(posedge clk) begin
	fifo_reg[w_ptr[INDEX_WIDTH-1:0]] <= (wen && !full) ? wdata : fifo_reg[w_ptr[INDEX_WIDTH-1:0]];
end

// 读
always_ff @(posedge clk) begin
	r_ptr <= rst ? 0 : (ren && !empty) ? r_ptr + 1 : r_ptr;
end

assign rdata = fifo_reg[r_ptr[INDEX_WIDTH-1:0]];


endmodule
