module LSU (
    input  clk,
    input  rst,

    input  exu_valid,
    input  [108 : 0] exu_data,
    output lsu_ready,

    output lsu_valid,
    output reg [103 : 0] lsu_data,
    input  wbu_ready,

    // 连接SRAM
    // 来自上游模块的预使能信号
    input  pre_lsu_ren,
    input  pre_lsu_wen,
    output prerequest,      // 给到总线仲裁器

    // output declaration of module axi4_lite_master
    output [31:0] ARADDR,
    output ARVALID,
    output [3 : 0] ARID,
    output [7 : 0] ARLEN,
    output [2 : 0] ARSIZE,
    output [1 : 0] ARBURST,
    output RREADY,

    output [31:0] AWADDR,
    output AWVALID,
    output [7 : 0] AWLEN,
    output [2 : 0] AWSIZE,
    output [3 : 0] AWID,
    output [1 : 0] AWBURST,
    output [31:0] WDATA,
    output WLAST,
    output [3:0] WSTRB,
    output WVALID,
    output BREADY,

    // input declaration of slave
    input  ARREADY,
    input  RVALID,
    input  RLAST,
    input  [3 : 0] RID,
    input  [31:0] RDATA,
    input  [1:0] RRESP,

    input  AWREADY,
    input  WREADY,
    input  BVALID,
    input  [3 : 0] BID,
    input  [1 : 0] BRESP
);


wire [31 : 0] lsu_addr = exu_data[108 : 77];
wire lsu_ren = exu_data[76];
wire lsu_wen = exu_data[75];
wire [2 : 0] lsu_op = exu_data[74 : 72];
wire [31 : 0] lsu_wdata = exu_data[71 : 40];
wire [39 : 0] rest_exu_data = exu_data[39 : 0];



// 五级流水线时，lsu是必经之路，但是多周期lsu可以跳过，不过我不打算跳过了
// 五级流水线时，S_WAIT_READY不需要，只要发生valid就可以，不需要这种状态机，多周期这里不更改了

// import "DPI-C" function int pmem_read(input int addr, input int len);
// import "DPI-C" function void pmem_write(input int addr, input int data, input int len);

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
// 符号扩展
wire [31 : 0] rdata_extend;
assign rdata_extend[31 : 16] =  {16{rdata[7] & ~lsu_op[2] & ~lsu_op[1] & ~lsu_op[0]}} | {16{rdata[15] & ~lsu_op[2] & ~lsu_op[1] & lsu_op[0]}} | rdata[31 : 16] & {16{lsu_op[1]}};
assign rdata_extend[15 : 8] = {8{rdata[7] & ~lsu_op[2] & ~lsu_op[1] & ~lsu_op[0]}} | rdata[15 : 8] & {8{lsu_op[0] | lsu_op[1]}};
assign rdata_extend[7 : 0] = rdata[7 : 0];

always_ff @(posedge clk) begin
    lsu_data <= (lsu_valid & wbu_ready) ? {exu_data[108 : 77], rdata_extend, rest_exu_data} : lsu_data;
end

// output declaration of module axi4_lite_master
wire wen = lsu_wen & has_new_data;
wire ren = lsu_ren & has_new_data;

// 提前通知仲裁器
assign prerequest = exu_valid & lsu_ready & pre_lsu_ren | exu_valid & lsu_ready & pre_lsu_wen;

// output declaration of module axi4_full_master
wire [31:0] rdata;  /* verilator lint_off UNUSEDSIGNAL */
wire [1:0] rresp;
wire [1:0] wresp;
wire done;


axi4_full_master u_axi4_full_master(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .wen        	(wen         ),
    .ren        	(ren         ),
    .user_ready 	(wbu_ready   ),
    .len        	(lsu_op[1:0] ),
    .waddr      	(lsu_addr    ),
    .wdata      	(lsu_wdata   ),
    .raddr      	(lsu_addr    ),
    .rdata      	(rdata       ),
    .rresp      	(rresp       ),
    .wresp      	(wresp       ),
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
    .RRESP      	(RRESP       ),
    .AWADDR     	(AWADDR      ),
    .AWVALID    	(AWVALID     ),
    .AWID       	(AWID        ),
    .AWLEN      	(AWLEN       ),
    .AWSIZE     	(AWSIZE      ),
    .AWBURST    	(AWBURST     ),
    .AWREADY    	(AWREADY     ),
    .WDATA      	(WDATA       ),
    .WSTRB      	(WSTRB       ),
    .WLAST      	(WLAST       ),
    .WVALID     	(WVALID      ),
    .WREADY     	(WREADY      ),
    .BRESP      	(BRESP       ),
    .BVALID     	(BVALID      ),
    .BID        	(BID         ),
    .BREADY     	(BREADY      )
);

always_ff @(posedge clk) begin
	if (done) begin
		if (lsu_ren) $display("Read Operation address at 0x%08x, data = 0x%08x", ARADDR, rdata);
	end
end


endmodule

