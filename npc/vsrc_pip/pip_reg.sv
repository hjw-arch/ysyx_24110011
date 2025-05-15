module pip_reg(
	input								clk,

	input 								pre_valid,
	input			[DATA_WAITH-1:0]	pre_data,
	input								next_ready,

	output 								pre_ready,
	output	logic	[DATA_WAITH-1:0]	next_data,
	output								next_valid
);

parameter	DATA_WAITH	=	64;

always_ff @(posedge clk) begin
	next_data <= (pre_valid & next_ready) ? pre_data : next_data;
end

always_ff @(posedge clk) begin
	next_valid <= pre_valid & next_ready;
end

assign pre_ready = next_ready;

endmodule //pip_reg
