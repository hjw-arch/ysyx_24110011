// 仅仅是简单实现，并不是完整版本，即使是此版本中的寄存器设置也不完整
module CSR (
	input  						clk,
	input  						rst,
	input  						wen,
	input 						cmd,

	input  						ecall,
	input  			[11 : 0] 	addr,
	input  			[31 : 0] 	sdata,
	input 			[31 : 0]	pc,

	output 	logic	[31 : 0]	rdata,
	output 	logic	[31 : 0]	mtvec,
	output	logic	[31 : 0]	mepc
);

logic	[31:0]	new_data;

assign	new_data = cmd ? sdata : sdata & rdata;


// CSR寄存器
reg		[31 : 0]		mcause_r;
reg		[31 : 0]		mstate_r;
reg		[31 : 0]		mtvec_r;
reg		[31 : 0]		mepc_r;
logic	[31 : 0]		mvendorid;
logic	[31 : 0]		marchid;


// 标识
wire is_mcause 		= 	(addr[7 : 0] == 8'h42);
wire is_mstatus 	= 	(addr[7 : 0] == 8'h00);
wire is_mtvec 		= 	(addr[7 : 0] == 8'h05);
wire is_mepc 		= 	(addr[7 : 0] == 8'h41);

// 特殊写入操作
wire special_op	= ecall;

/******************************* 标识寄存器 ***********************************/

// mvendorid
assign mvendorid = 32'h79737978;

// mvendorid
assign marchid = 32'h016FE3BB;


/******************************* M寄存器 ***********************************/
// mcause
always_ff @(posedge clk) begin
	if (rst) begin
		mcause_r <= 32'b0;
	end else begin
		case ({special_op, wen, is_mcause})
			3'b100: mcause_r <= 32'd11;
			3'b011: mcause_r <= new_data;
			default: mcause_r <= mcause_r;
		endcase
	end
end


// mstatus
// 简单实现，无复位值
always_ff @(posedge clk) begin
	case ({special_op, wen, is_mstatus})
		3'b100: mstate_r <= 32'h1800;
		3'b011: mstate_r <= new_data;
		default: mstate_r <= mstate_r;
	endcase
end

// mtvec
// 简单实现，无复位值
always_ff @(posedge clk) begin
	mtvec_r <= (wen & is_mtvec) ? new_data : mtvec_r;
end

// mepc
// 简单实现，无复位值
always_ff @(posedge clk) begin
	unique case ({special_op, wen, is_mepc})
		3'b100: mepc_r <= pc;
		3'b011: mepc_r <= new_data;
		default: mepc_r <= mepc_r;
	endcase
end


/******************************* 读寄存器 ***********************************/
always_comb begin
	unique case(addr[7 : 0])
		8'h42: rdata = mcause_r;
		8'h00: rdata = mstate_r;
		8'h05: rdata = mtvec_r;
		8'h41: rdata = mepc_r;
		8'h11: rdata = mvendorid;
		8'h12: rdata = marchid;
		default: rdata = 32'h0;
	endcase
end

assign mtvec 	= 	mtvec_r;
assign mepc		=	mepc_r;


endmodule
