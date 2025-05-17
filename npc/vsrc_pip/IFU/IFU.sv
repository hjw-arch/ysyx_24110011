module IFU(
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
	input	[31:0] 	real_pc,			// 真正的PC值
	input			flush,				// 确认推测错误

    output 			valid_o,
    output	[63:0]	data_o,
    input 			ready_i
);

	`define HANDSHAKE 	valid_o & ready_i
	`define PC_VECTOR 	32'h80000000


	logic			state, nstate;										// 0: IDLE, 1: WAIT_READY
	logic	[31:0]	pc;

	logic	[31:0]	c2i_addr;
	logic			c2i_valid;

	logic			i2c_valid;
	logic	[31:0]	i2c_inst;



	always_ff @(posedge clk) begin								// 状态机
		state <= rst ? 1'b0 : nstate;
	end


	always_ff @(posedge clk) begin								// PC
		if (rst) begin
			pc <= `PC_VECTOR;
		end else begin
			if (`HANDSHAKE) begin
				pc <= flush ? real_pc : pc + 4;
			end
		end
	end

	// flush、ifence可能需要缓存, 设计好后续再说
	assign	valid_o		=	i2c_valid & ~flush & ~ifence | state;		//	如果icache命中且非推测执行需要纠正
	assign	data_o		=	{i2c_inst, pc};
	assign	nstate		=	valid_o & ~ready_i;

	assign	c2i_addr	=	pc;
	assign	c2i_valid	=	~state;




	icache #(
		.BLOCK_SIZE 	(16   ),
		.BLOCK_NUM  	(16  ))
	u_icache (
	    .clk        (clk        ),
	    .rst        (rst        ),

	    .addr_i		(c2i_addr   ),
	    .valid_i	(c2i_valid  ),
	    .valid_o	(i2c_valid  ),
	    .data_o		(i2c_inst   ),
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
