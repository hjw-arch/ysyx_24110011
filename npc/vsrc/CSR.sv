// 仅仅是简单实现，并不是完整版本，即使是此版本中的寄存器设置也不完整
module CSR (
	input  						clk,
	input  						rst,
	input  						wen_i,

	input  						is_ecall_i,
	input  			[11 : 0] 	addr_i,
	input  			[31 : 0] 	data_i,
	input 			[31 : 0]	pc_i,

	output 	logic	[31 : 0]	data_o,
	output 	logic	[31 : 0]	mtvec_o,
	output	logic	[31 : 0]	mepc_o
);

// CSR寄存器
reg		[31 : 0]		mcause;
reg		[31 : 0]		mstatus;
reg		[31 : 0]		mtvec;
reg		[31 : 0]		mepc;
logic	[31 : 0]		mvendorid;
logic	[31 : 0]		marchid;


// 标识
wire is_mcause 		= 	(addr_i[7 : 0] == 8'h42);
wire is_mstatus 	= 	(addr_i[7 : 0] == 8'h00);
wire is_mtvec 		= 	(addr_i[7 : 0] == 8'h05);
wire is_mepc 		= 	(addr_i[7 : 0] == 8'h41);

// 特殊写入操作
wire special_op	= is_ecall_i;

/******************************* 标识寄存器 ***********************************/

// mvendorid
assign mvendorid = 32'h79737978;

// mvendorid
assign marchid = 32'h016FE3BB;


/******************************* M寄存器 ***********************************/
// mcause
always_ff @(posedge clk) begin
	if (rst) begin
		mcause <= 32'b0;
	end else begin
		case ({special_op, wen_i, is_mcause})
			3'b100: mcause <= 32'd11;
			3'b011: mcause <= data_i;
			default: mcause <= mcause;
		endcase
	end
end


// mstatus
// 简单实现，无复位值
always_ff @(posedge clk) begin
	case ({special_op, wen_i, is_mstatus})
		3'b100: mstatus <= 32'h1800;
		3'b011: mstatus <= data_i;
		default: mstatus <= mstatus;
	endcase
end

// mtvec
// 简单实现，无复位值
always_ff @(posedge clk) begin
	mtvec <= (wen_i & is_mtvec) ? data_i : mtvec;
end

// mepc
// 简单实现，无复位值
always_ff @(posedge clk) begin
	case ({special_op, wen_i, is_mepc})
		3'b100: mepc <= pc_i;
		3'b011: mepc <= data_i;
		default: mepc <= mepc;
	endcase
end


/******************************* 读寄存器 ***********************************/
always_comb begin
	case(addr_i[7 : 0])
		8'h42: data_o = mcause;
		8'h00: data_o = mstatus;
		8'h05: data_o = mtvec;
		8'h41: data_o = mepc;
		8'h11: data_o = mvendorid;
		8'h12: data_o = marchid;
		default: data_o = 32'h0;
	endcase
end

assign mtvec_o 	= 	mtvec;
assign mepc_o	=	mepc;


endmodule
