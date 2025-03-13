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
    output prerequest,
    output [31:0] ARADDR,
    output ARVALID,
    output RREADY,
    output [31:0] AWADDR,
    output AWVALID,
    output [31:0] WDATA,
    output [3:0] WSTRB,
    output WVALID,
    output BREADY,

    // input declaration of module SRAM
    input ARREADY,
    input RVALID,
    input [31:0] RDATA,
    input [1:0] RRESP,
    input AWREADY,
    input WREADY,
    input BVALID,
    input [1:0] BRESP
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

assign prerequest = wbu_valid;

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




endmodule

