module LSU (
    input clk,
    input rst,

    input exu_valid,
    input [108 : 0] exu_data,
    output lsu_ready,

    output lsu_valid,
    output reg [103 : 0] lsu_data,
    input wbu_ready
);


wire [31 : 0] lsu_addr = exu_data[108 : 77];
wire lsu_ren = exu_data[76];
wire lsu_wen = exu_data[75];
wire [2 : 0] lsu_op = exu_data[74 : 72];
wire [31 : 0] lsu_wdata = exu_data[71 : 40];
wire [39 : 0] rest_exu_data = exu_data[39 : 0];



// 五级流水线时，lsu是必经之路，但是多周期lsu可以跳过，不过我不打算跳过了
// 五级流水线时，S_WAIT_READY不需要，只要发生valid就可以，不需要这种状态机，多周期这里不更改了

import "DPI-C" function int pmem_read(input int addr, input int len);
import "DPI-C" function void pmem_write(input int addr, input int data, input int len);

typedef enum logic { 
    S_IDLE,
    S_WAIT_READY
} lsu_state_t;

lsu_state_t state, next_state;

always_ff @(posedge clk) begin
    state <= rst ? S_IDLE : next_state;
end

always_comb begin
    case(state)
        S_IDLE:
            next_state = (lsu_valid & ~wbu_ready) ? S_WAIT_READY : S_IDLE;
        S_WAIT_READY:
            next_state = (wbu_ready) ? S_IDLE : S_WAIT_READY;
        default:
            next_state = S_IDLE;
    endcase
end

reg has_new_data;
always_ff @(posedge clk) begin
    has_new_data <= (exu_valid & lsu_ready) ? 1'b1 : 1'b0;
end

assign lsu_ready = wbu_ready;
assign lsu_valid = done & lsu_ren | done & lsu_wen | ~lsu_ren & ~lsu_wen & has_new_data | (state == S_WAIT_READY);

// 读
// wire [WIDTH - 1 : 0] rdata = pmem_read(lsu_addr, lsu_op[1:0]);

wire [31 : 0] rdata_extend;
assign rdata_extend[31 : 16] =  {16{rdata[7] & ~lsu_op[2] & ~lsu_op[1] & ~lsu_op[0]}} | {16{rdata[15] & ~lsu_op[2] & ~lsu_op[1] & lsu_op[0]}} | rdata[31 : 16] & {16{lsu_op[1]}};
assign rdata_extend[15 : 8] = {8{rdata[7] & ~lsu_op[2] & ~lsu_op[1] & ~lsu_op[0]}} | rdata[15 : 8] & {8{lsu_op[0]}};
assign rdata_extend[7 : 0] = rdata[7 : 0];

always_ff @(posedge clk) begin
    lsu_data <= (lsu_valid & wbu_ready) ? {exu_data[108 : 77], rdata_extend, rest_exu_data} : lsu_data;
end

// // 写
// always @(posedge clk) begin
//     if(lsu_wen & lsu_valid & wbu_ready) begin
//         pmem_write(lsu_addr, lsu_wdata, lsu_op[1:0]);
//     end
// end


// output declaration of module axi4_lite_master
wire [3 : 0] wmask = {2'b00, lsu_op[1 : 0]};
wire wen = lsu_wen & has_new_data;
wire ren = lsu_ren & has_new_data;
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
    .wen        	(wen         ),
    .ren        	(ren         ),
    .user_ready 	(lsu_ready   ),
    .wmask      	(wmask       ),
    .waddr      	(lsu_addr    ),
    .wdata      	(lsu_wdata   ),
    .raddr      	(lsu_addr    ),
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

