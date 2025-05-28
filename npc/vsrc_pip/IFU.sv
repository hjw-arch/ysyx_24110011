module IFU
import define_pkg::*;
(
    input			clk,
    input			rst,

    output	[31:0] 	ARADDR,
    output			ARVALID,
    output 			RREADY,
    output	[3:0] 	ARID,
    output	[7:0] 	ARLEN,
    output	[2:0] 	ARSIZE,
    output	[1:0] 	ARBURST,

    input 			ARREADY,
    input 			RVALID,
    input 			RLAST,
    input	[3:0] 	RID,
    input	[31:0] 	RDATA,
    input	[1:0] 	RRESP,


	input 			ifence,
	input	[31:0] 	pc_target,			// 真正的PC值
	input			flush,				// 确认推测错误

    output 			valid_o,
    output	[63:0]	data_o,
    input 			ready_i
);

`define PC_VECTOR 	32'h30000000

localparam		IDLE = 2'b00;
localparam		WAIT_READY = 2'b01;
localparam		FLUSHING = 2'b10;


logic	[1:0]	state, nstate;										// 00: IDLE, 01: WAIT_READY, 10: FLUSHING
logic	[31:0]	pc;

logic	[31:0]	c2i_addr;
logic			c2i_valid;

logic			i2c_valid;
logic	[31:0]	i2c_inst;
logic			i2c_in_mem;



always_ff @(posedge clk) begin								// 状态机
	state <= rst ? 2'b0 : nstate;
end


always_ff @(posedge clk) begin								// PC
	if (rst) begin
		pc <= `PC_VECTOR;
	end else begin
		pc <= flush ? pc_target : (`HANDSHAKE) ? pc + 4 : pc;
	end
end

// flush、ifence可能需要缓存, 设计好后续再说
assign	valid_o		=	i2c_valid & ~flush & ~ifence & ~state[1] | state[0];		//	如果icache命中且非flush
assign	data_o		=	{i2c_inst, pc};

assign	nstate[0]	=	~state[0] & ~state[1] & valid_o & ~ready_i & ~flush | state[0] & valid_o & ~ready_i & ~flush;
assign	nstate[1]	=	flush & i2c_in_mem | state[1] & ~i2c_valid;

assign	c2i_addr	=	pc;
assign	c2i_valid	=	~state[0] & ~state[1];		// 只在IDLE时取指




icache #(
	.BLOCK_SIZE 	(16   ),
	.BLOCK_NUM  	(4  ))
u_icache (
    .clk        (clk        ),
    .rst        (rst        ),

    .addr_i		(c2i_addr   ),
    .valid_i	(c2i_valid  ),
	.flush		(flush		),
    .valid_o	(i2c_valid  ),
    .data_o		(i2c_inst   ),
	.in_mem		(i2c_in_mem ),
    .ifence		(ifence ),

    .ARADDR     (ARADDR     ),
    .ARVALID    (ARVALID    ),
    .RREADY     (RREADY     ),
    .ARID       (ARID       ),
    .ARLEN      (ARLEN      ),
    .ARSIZE     (ARSIZE     ),
    .ARBURST    (ARBURST    ),

    .ARREADY    (ARREADY    ),
    .RVALID     (RVALID     ),
    .RLAST      (RLAST      ),
    .RID        (RID        ),
    .RDATA      (RDATA      ),
    .RRESP      (RRESP      )
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
