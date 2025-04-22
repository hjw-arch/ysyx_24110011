module CLINT (
    input clk,
    input rst,

	// AXI4 从接口 - 读地址通道
    input  logic [3:0]  arid,      // 读事务ID
    input  logic [31:0] araddr,    // 读地址
    input  logic [7:0]  arlen,     // 突发长度（仅支持0）
    input  logic [2:0]  arsize,    // 突发大小
    input  logic [1:0]  arburst,   // 突发类型（仅支持FIXED）
    input  logic        arvalid,   // 读地址有效
    output logic        arready,   // 读地址准备好

    // 读数据通道
    output logic [3:0]  rid,       // 读事务ID
    output logic [31:0] rdata,     // 读数据
    output logic [1:0]  rresp,     // 读响应
    output logic        rlast,     // 读数据结束
    output logic        rvalid,    // 读数据有效
    input  logic        rready,    // 读数据准备好

    // 写地址通道
    input  logic [3:0]  awid,      // 写事务ID
    input  logic [31:0] awaddr,    // 写地址
    input  logic [7:0]  awlen,     // 突发长度（仅支持0）
    input  logic [2:0]  awsize,    // 突发大小
    input  logic [1:0]  awburst,   // 突发类型（仅支持FIXED）
    input  logic        awvalid,   // 写地址有效
    output logic        awready,   // 写地址准备好

    // 写数据通道
    input  logic [31:0] wdata,     // 写数据
    input  logic [3:0]  wstrb,     // 写选通
    input  logic        wlast,     // 写数据结束
    input  logic        wvalid,    // 写数据有效
    output logic        wready,    // 写数据准备好

    // 写响应通道
    output logic [3:0]  bid,       // 写事务ID
    output logic [1:0]  bresp,     // 写响应
    output logic        bvalid,    // 写响应有效
    input  logic        bready     // 写响应准备好
);

/*************************************** 回复无关信号 ******************************************/
// 读通道
assign rid 		= 		arid;
assign rresp 	= 		{{araddr[15:2] != 16'h0000 | araddr[15:2] != 16'h0004}, 1'b0};
assign rlast 	= 		1'b1;

// 写通道
assign bid 		= 		awid;
assign awready 	= 		1'b1;
assign wready	=		1'b1;
assign bresp	=		2'b10;
assign bvalid	=		1'b1;

/**************************************** mtime **************************************************/

reg [63 : 0] mtime;

always_ff @(posedge clk) begin
    mtime <= rst ? 64'b0 : mtime + 1;
end

/************************************** 读状态机 *******************************************************/
logic state, next_state;		// 0: IDLE      1: ACTIVE

// 状态转换
always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : next_state;
end

assign next_state = ~state & arvalid | state & ~rready;		// 这种简单的二值状态机，仅需考虑合适需要为“1”

// 依赖状态机的信号
assign arready	=	~state;		// arready = (state == IDLE)
assign rvalid 	= 	state;		// rvalid = (state == ACTIVE)


/*************************************** 地址缓存 *************************************************/
reg [31 : 0] raddr_buf;
always_ff @(posedge clk) begin
    raddr_buf <= arvalid & arready ? araddr : raddr_buf;
end

/***************************************** 读数据 **************************************************/
// 仅仅做简单判断
assign rdata = {32{~raddr_buf[2]}} & mtime[31 : 0] | {32{raddr_buf[2]}} & mtime[63 : 32];


endmodule
