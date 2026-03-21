module pip_reg #(
	parameter	WIDTH	=	64
)(
	input				clk,
	input				rst,

	input				flush,

	input				pre_valid,
	input	[WIDTH-1:0]	pre_data,
	output 				pre_ready,

	output				next_valid,
	output	[WIDTH-1:0]	next_data,
	input				next_ready
);

//   > pre_ready 表示这个级间寄存器在当前时钟边沿是否允许被上游新数据重写。
//   > 若允许重写，则下一拍 next_valid 应更新为本拍 pre_valid；
//   > 若不允许重写，则说明当前寄存器里有一条旧数据且下游未接收，因此 next_valid 必须保持。
//   > 唯一不允许重写的情况是 next_valid=1 && next_ready=0。

logic	[WIDTH-1:0]	main_data;
logic				main_valid;

assign	next_valid	=	main_valid;
assign	next_data	=	main_data;
assign	pre_ready	=	~main_valid | next_ready;

wire 				main_valid_next = pre_valid & pre_ready | main_valid & ~next_ready;
wire [WIDTH-1:0] 	main_data_next  = pre_valid & pre_ready ? pre_data : main_data;

always_ff @(posedge clk) begin
	if (rst | flush) begin
		main_valid <= 1'b0;
	end else begin
		main_valid <= main_valid_next;
	end
end

always_ff @(posedge clk) begin
	main_data <= main_data_next;
end


endmodule //pip_reg



module pip_reg_with_skid_buffer #(
	parameter	WIDTH	=	64
)(
	input				clk,
	input				rst,

	input				flush,

	input				pre_valid,
	input	[WIDTH-1:0]	pre_data,
	output 				pre_ready,

	output				next_valid,
	output	[WIDTH-1:0]	next_data,
	input				next_ready
);

logic	[WIDTH-1:0]		skid_data;
logic					skid_valid;

logic	[WIDTH-1:0]		main_data;
logic					main_valid;

assign	pre_ready	=	~skid_valid;
assign	next_valid	=	main_valid;
assign	next_data	=	main_data;

wire	main_ready	=	~main_valid | next_ready;

wire				skid_valid_next		=	pre_valid & pre_ready & ~main_ready | skid_valid & ~main_ready;		// 写成skid_valid & ~next_ready也可
wire	[WIDTH-1:0]	skid_data_next		=	pre_valid & pre_ready & ~main_ready ? pre_data : skid_data;

wire				main_valid_next		=	skid_valid & main_ready | pre_valid & main_ready | main_valid & ~next_ready;
wire	[WIDTH-1:0]	main_data_next		=	skid_valid & main_ready ? skid_data 			: 			// 互斥的，应该是一级mux
											~skid_valid & pre_valid & main_ready ? pre_data :			// 去掉~skid_valid，会变成两级mux，~skid_valid换pre_ready也可，看语义理解
											main_data;

always_ff @(posedge clk) begin
	if (rst | flush) begin
		skid_valid <= 1'b0;
	end else begin
		skid_valid <= skid_valid_next;
	end
end

always_ff @(posedge clk) begin
	skid_data <= skid_data_next;
end


always_ff @(posedge clk) begin
	if (rst | flush) begin
		main_valid <= 1'b0;
	end else begin
		main_valid <= main_valid_next;
	end
end

always_ff @(posedge clk) begin
	main_data <= main_data_next;
end


endmodule //pip_reg_with_skid_buffer



module fetch_stage_reg #(
	parameter	WIDTH	=	64
)(
	input				clk,
	input				rst,

	input				flush,

	input				pre_valid,
	input	[WIDTH-1:0]	pre_data,
	output 				pre_ready,

	output				next_valid,
	output	[WIDTH-1:0]	next_data,
	input				next_ready
);


logic	[WIDTH-1:0]	main_data;
logic				main_valid;

assign	next_valid	=	main_valid;
assign	next_data	=	main_data;
assign	pre_ready	=	~main_valid | next_ready | flush;

wire 				main_valid_next = flush ? pre_valid : pre_valid & pre_ready | main_valid & ~next_ready;
wire [WIDTH-1:0] 	main_data_next  = pre_valid & pre_ready ? pre_data : main_data;

always_ff @(posedge clk) begin
	if (rst) begin
		main_valid <= 1'b0;
	end else begin
		main_valid <= main_valid_next;
	end
end

always_ff @(posedge clk) begin
	main_data <= main_data_next;
end



	
endmodule //fetch_stage_reg




// 之前的基于脉冲的协议，也正确，但是不够解耦，需要下级流水线自己维护状态
// module pip_reg #(
// 	parameter	WIDTH	=	64
// )(
// 	input								clk,

// 	input 								pre_valid,
// 	input			[WIDTH-1:0]	pre_data,
// 	input								next_ready,

// 	output 								pre_ready,
// 	output	logic	[WIDTH-1:0]	next_data,
// 	output	logic						next_valid
// );

// always_ff @(posedge clk) begin
// 	next_data <= (pre_valid & next_ready) ? pre_data : next_data;
// end

// always_ff @(posedge clk) begin
// 	next_valid <= pre_valid & next_ready;
// end

// assign pre_ready = next_ready;

// endmodule //pip_reg
