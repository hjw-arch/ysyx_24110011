module IFU #(parameter WIDTH = 32) (
    input clk,
    input rst,
    input wbu_valid,
    input [WIDTH - 1 : 0] pc,

    output ifu_valid,
    output reg [63 : 0] ifu_data,
    input idu_ready,

    // 连接SRAM
    // output declaration of module axi4_lite_master
    output prerequest,      // 仅仅适用于多周期处理器
    output [31:0] ARADDR,
    output ARVALID,
    output RREADY,
    output [3 : 0] ARID,
    output [7 : 0] ARLEN,
    output [2 : 0] ARSIZE,
    output [1 : 0] ARBURST,

    // input declaration of slave
    input ARREADY,
    input RVALID,
    input RLAST,
    input [3 : 0] RID,
    input [31 : 0] RDATA,
    input [1 : 0] RRESP
);

typedef enum logic { 
    S_IDLE,
    S_WAIT_READY
} ifu_state_t;

ifu_state_t state, next_state;

always_ff @(posedge clk) begin
    state <= rst ? S_IDLE : next_state;
end

always_comb begin
    case(state)
        S_IDLE:
            next_state = (ifu_valid && !idu_ready) ? S_WAIT_READY : S_IDLE;
        S_WAIT_READY:
            next_state = (idu_ready) ? S_IDLE : S_WAIT_READY;
        default:
            next_state = state;
    endcase
end

reg start;
always_ff @(posedge clk) begin
    start <= wbu_valid | rst ? 1'b1 : 1'b0;
end

assign ifu_valid = i2c_valid | (state == S_WAIT_READY);


always_ff @(posedge clk) begin
    ifu_data <= (ifu_valid & idu_ready) ? {i2c_data, pc} : ifu_data;
end

assign prerequest = wbu_valid;

// output declaration of module axi4_full_master
wire [31:0] rdata;  /* verilator lint_off UNUSEDSIGNAL */
wire [1:0] rresp;
wire done;

// Not used

// output declaration of module icache
wire i2c_ready;
wire i2c_valid;
wire [31:0] i2c_data;
wire i2m_valid;
wire [31:0] i2m_addr;
wire i2m_ready;


// 流水线时，icache要大改
icache #(
	.BLOCK_SIZE 	(4   ),
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
	.m2i_valid 	(done       ),
	.i2m_ready 	(i2m_ready  )
);



axi4_full_master u_axi4_full_master(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .wen        	(1'b0        ),
    .ren        	(i2m_valid   ),
    .user_ready 	(i2m_ready   ),
    .len        	(2'b10       ),
    .waddr      	(32'b0       ),
    .wdata      	(32'b0       ),
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

import "DPI-C" function void is_finish_bootloader(input int pc);
import "DPI-C" function void PerformanceCounter_ifu_fetch();
import "DPI-C" function void PerformanceCounter_ifu_fetch_cycles(input int start, input int finish);
import "DPI-C" function void PerformanceCounter_inst_type_total_cycles(input int start, input int inst);

always_ff @(posedge clk) begin
	if (wbu_valid) is_finish_bootloader(pc);
end

always_ff @(posedge clk) begin
	if (done) PerformanceCounter_ifu_fetch();
end
/* verilator lint_off WIDTHEXPAND */
always_ff @(posedge clk) begin
	if (!rst) PerformanceCounter_ifu_fetch_cycles(start, done);
end

always_ff @(posedge clk) begin
	if (!rst) PerformanceCounter_inst_type_total_cycles(start, rdata);
end


/******************************************************************/




endmodule

