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

wire reading = in_penable && in_psel && ~in_pwrite && in_paddr[2:0] == 3'b0;
assign in_pready = reading;
assign in_pslverr = 1'b0;

reg [8:0] buffer;
reg [3:0] counter;
reg active;

reg [2:0] ps2_clk_sync;

always @(posedge clock) begin
    ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
end

wire ps2_falling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

// 写
always_ff @(posedge clock) begin
	if (reset) active <= 1'b0;
	else begin
		if (ps2_falling) begin
			if (counter == 4'd9) active <= 1'b0;
			else if (!active && ps2_data) active <= 1'b1;
			else active <= active;
		end
	end
end

always_ff @(posedge clock) begin
	if (reset) counter <= 4'd0;
	else if (ps2_falling) begin
		if (counter == 4'd9) counter <= 4'd0;
		else if (active) counter <= counter + 1;
		else counter <= 4'd0;
	end else begin
		counter <= counter;
	end
end

always_ff @(posedge clock) begin
	if (ps2_falling) begin
		if (active) buffer <= {ps2_data, buffer[8:1]};
		else buffer <= buffer;
	end else begin
		buffer <= buffer;
	end
end


logic wen;
logic ren;
always_comb begin
	if (active && ps2_falling && counter == 4'd9 && ps2_data && ^buffer[8:0]) begin
		wen = 1'b1;
	end else begin
		wen = 1'b0;
	end
end

always_comb begin
	if (reading) begin
		ren = 1'b1;
	end else begin
		ren = 1'b0;
	end
end


logic [7:0] rdata;
logic [7:0] wdata;
logic full, empty;

assign in_prdata = empty ? 32'b0 : {24'b0, rdata};
assign wdata = buffer[7:0];

FIFO #(8, 8) fifo (
	.clk(clock),
	.rst(reset),
	.wen(wen),
	.ren(ren),
	.wdata(wdata),
	.rdata(rdata),
	.full(full),
	.empty(empty)
);


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

always_ff @(posedge clk) begin
	if (wen) begin
		$display("Get keyboard = %x", wdata);
		for (int i = 0; i < 8; i++) begin
			$display("fifo[%d] = %x", i, fifo_reg[i]);
		end
		$display("w_ptr = %d, r_ptr = %d", w_ptr, r_ptr);
	end
end


endmodule
