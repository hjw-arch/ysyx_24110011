module IFU #(parameter WIDTH = 32) (
    input clk,
    input rst,

    input start,
    input [WIDTH - 1 : 0] pc,

    output ifu_valid,
    output reg [63 : 0] ifu_data,
    input idu_ready
);

import "DPI-C" function int fetch_inst(input int pc);

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

assign ifu_valid = done | (state == S_WAIT_READY);

// 模拟SRAM取指
always_ff @(posedge clk) begin
    ifu_data <= (ifu_valid & idu_ready) ? {rdata, pc} : ifu_data;
end

// AXI4-lite
// output declaration of module axi4_lite_master
wire [31:0] rdata;
wire [1:0] rresp;
wire [1:0] wresp;
wire done;
wire [31:0] ARADDR;
wire ARVALID;
wire RREADY;
wire [31:0] AWADDR;
wire AWVALID;
wire [31:0] WDATA;
wire [3:0] WSTRB;
wire WVALID;
wire BREADY;

axi4_lite_master u_axi4_lite_master(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .wen        	(1'b0        ),
    .ren        	(start       ),
    .user_ready 	(idu_ready   ),
    .wmask      	(4'b0011     ),
    .waddr      	(32'b0       ),
    .wdata      	(32'b0       ),
    .raddr      	(pc          ),
    .rdata      	(rdata       ),
    .rresp      	(rresp       ),
    .wresp      	(wresp       ),
    .done       	(done        ),
    .ARADDR     	(ARADDR      ),
    .ARVALID    	(ARVALID     ),
    .ARREADY    	(ARREADY     ),
    .RDATA      	(RDATA       ),
    .RRESP      	(RRESP       ),
    .RVALID     	(RVALID      ),
    .RREADY     	(RREADY      ),
    .AWADDR     	(AWADDR      ),
    .AWVALID    	(AWVALID     ),
    .AWREADY    	(AWREADY     ),
    .WDATA      	(WDATA       ),
    .WSTRB      	(WSTRB       ),
    .WVALID     	(WVALID      ),
    .WREADY     	(WREADY      ),
    .BRESP      	(BRESP       ),
    .BVALID     	(BVALID      ),
    .BREADY     	(BREADY      )
);

// output declaration of module SRAM
wire ARREADY;
wire RVALID;
wire [31:0] RDATA;
wire [1:0] RRESP;
wire AWREADY;
wire WREADY;
wire BVALID;
reg [1:0] BRESP;

SRAM #(
    .R_DELAY_TIME 	(1  ),
    .W_DELAY_TIME 	(1  ))
u_SRAM(
    .clk     	(clk      ),
    .rst     	(rst      ),
    .ARVALID 	(ARVALID  ),
    .ARREADY 	(ARREADY  ),
    .ARADDR  	(ARADDR   ),
    .RVALID  	(RVALID   ),
    .RREADY  	(RREADY   ),
    .RDATA   	(RDATA    ),
    .RRESP   	(RRESP    ),
    .AWVALID 	(AWVALID  ),
    .AWREADY 	(AWREADY  ),
    .AWADDR  	(AWADDR   ),
    .WVALID  	(WVALID   ),
    .WREADY  	(WREADY   ),
    .WDATA   	(WDATA    ),
    .WSTRB   	(WSTRB    ),
    .BREADY  	(BREADY   ),
    .BVALID  	(BVALID   ),
    .BRESP   	(BRESP    )
);




endmodule

