module IFU(
    input 						clk,
    input 						rst,
    input 			[31 : 0] 	br_pc,
	input 						br_valid,

    output 						valid_o,
    output	logic	[63 : 0]	data_o,
    input 						ready_i
);

logic	state, nstate;										// 0: IDLE, 1: WAIT_READY

always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : nstate;
end

assign	nstate		=	valid_o & ~ready_i;


reg start;
always_ff @(posedge clk) begin
    start <= wbu_valid | rst ? 1'b1 : 1'b0;
end

// `ifdef SOC

assign ifu_valid = i2c_valid | (state == S_WAIT_READY);


always_ff @(posedge clk) begin
    ifu_data <= (ifu_valid & idu_ready) ? {i2c_data, pc} : ifu_data;
end

assign prerequest = 1'b0;	// 需要修改，暂时为了cache妥协

// output declaration of module axi4_full_master
wire [31:0] rdata;  /* verilator lint_off UNUSEDSIGNAL */
wire rdata_valid;
wire [1:0] rresp;
wire done;

// output declaration of module icache
wire i2c_ready;
wire i2c_valid;
wire [31:0] i2c_data;
wire i2m_valid;
wire [31:0] i2m_addr;
wire i2m_ready;


// 流水线时，icache要大改
icache #(
	.BLOCK_SIZE 	(16   ),
	.BLOCK_NUM  	(16  ),
	.ADDR_WIDTH 	(32  ),
	.DATA_WIDTH 	(32  ))
u_icache(
	.clk       	(clk        ),
	.rst       	(rst        ),
	.c2i_addr  	(pc		    ),
	.c2i_valid 	(start		),
	.i2c_ready 	(i2c_ready  ),
	.i2c_valid 	(i2c_valid  ),
	.i2c_data  	(i2c_data   ),
	.c2i_ready 	(1'b1 		),
	.i2m_valid 	(i2m_valid  ),
	.i2m_addr  	(i2m_addr   ),
	.m2i_ready 	(1'b1       ),
	.m2i_data  	(rdata      ),
	.m2i_valid 	(rdata_valid),
	.m2i_done	(done		),
	.i2m_ready 	(i2m_ready  )
);



axi4_full_master u_axi4_full_master(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .wen        	(1'b0        ),
    .ren        	(i2m_valid   ),
    .user_ready 	(i2m_ready   ),
	.size			(2'b10		 ),
    .len        	(8'b11       ),
    .waddr      	(32'b0       ),
    .wdata      	(32'b0       ),
	.rdata_valid	(rdata_valid ),
    .raddr      	(i2m_addr    ),
    .rdata      	(rdata       ),
    .rresp      	(rresp       ),/* verilator lint_off PINCONNECTEMPTY */
    .wresp      	(            ),
    .done       	(done        ),
    .ARREADY    	(ARREADY     ),
    .ARVALID    	(ARVALID     ),
    .ARADDR     	(ARADDR      ),
    .ARID       	(ARID        ),
    .ARLEN      	(ARLEN       ),
    .ARSIZE     	(ARSIZE      ),
    .ARBURST    	(ARBURST     ),
    .RREADY     	(RREADY      ),
    .RVALID     	(RVALID      ),
    .RDATA      	(RDATA       ),
    .RLAST      	(RLAST       ),
    .RID        	(RID         ),
    .RRESP      	(RRESP       )/* verilator lint_off PINCONNECTEMPTY */,
    .AWADDR     	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWVALID    	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWID       	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWLEN      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWSIZE     	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWBURST    	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWREADY    	(1'b0        ),
    .WDATA      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WSTRB      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WLAST      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WVALID     	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WREADY     	(1'b0        ),
    .BRESP      	(2'b00       ),
    .BVALID     	(1'b0        ),
    .BID        	(4'b0        ),
    .BREADY     	(            )/* verilator lint_off PINCONNECTEMPTY */
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
// 	if (!rst) PerformanceCounter_inst_type_total_cycles(start, i2c_data);
// end


/******************************************************************/

	
// `else


// assign ifu_valid = done | (state == S_WAIT_READY);

// // 模拟SRAM取指
// always_ff @(posedge clk) begin
//     ifu_data <= (ifu_valid & idu_ready) ? {rdata, pc} : ifu_data;
// end

// assign prerequest = wbu_valid;

// // output declaration of module axi4_full_master
// wire [31:0] rdata;  /* verilator lint_off UNUSEDSIGNAL */
// wire rdata_valid;
// wire [1:0] rresp;
// wire done;

// // Not used


// axi4_full_master u_axi4_full_master(
//     .clk        	(clk         ),
//     .rst        	(rst         ),
//     .wen        	(1'b0        ),
//     .ren        	(start       ),
//     .user_ready 	(idu_ready   ),
//     .size        	(2'b10       ),
// 	.len			(8'b0		 ),
//     .waddr      	(32'b0       ),
//     .wdata      	(32'b0       ),
//     .raddr      	(pc          ),
// 	.rdata_valid	(rdata_valid ),
//     .rdata      	(rdata       ),
//     .rresp      	(rresp       ),/* verilator lint_off PINCONNECTEMPTY */
//     .wresp      	(            ),
//     .done       	(done        ),
//     .ARREADY    	(ARREADY     ),
//     .ARVALID    	(ARVALID     ),
//     .ARADDR     	(ARADDR      ),
//     .ARID       	(ARID        ),
//     .ARLEN      	(ARLEN       ),
//     .ARSIZE     	(ARSIZE      ),
//     .ARBURST    	(ARBURST     ),
//     .RREADY     	(RREADY      ),
//     .RVALID     	(RVALID      ),
//     .RDATA      	(RDATA       ),
//     .RLAST      	(RLAST       ),
//     .RID        	(RID         ),
//     .RRESP      	(RRESP       )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWADDR     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWVALID    	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWID       	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWLEN      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWSIZE     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWBURST    	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWREADY    	(1'b0        ),
//     .WDATA      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WSTRB      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WLAST      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WVALID     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WREADY     	(1'b0        ),
//     .BRESP      	(2'b00       ),
//     .BVALID     	(1'b0        ),
//     .BID        	(4'b0        ),
//     .BREADY     	(            )/* verilator lint_off PINCONNECTEMPTY */
// );


	
// `endif




endmodule



module PC(
	input						clk,
	input						rst,
	input			[31:0]		br_pc,
	input 						br_valid,

	output 	logic	[31:0]		pc
);



always_ff @(posedge clk) begin
	if (rst) begin
		pc <= 32'h30000000;
	end else begin
		pc <= br_valid ? br_pc : pc + 4;
	end
end



endmodule


