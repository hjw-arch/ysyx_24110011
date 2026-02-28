module LSU
import pipeline_pkt_pkg::*;
(
	input 			clk,
	input 			rst,

	// AXI
    output 	[31:0] 		ARADDR,
    output 	[3 : 0] 	ARID,
    output	[7 : 0] 	ARLEN,
    output	[2 : 0] 	ARSIZE,
    output	[1 : 0] 	ARBURST,
	output 				ARVALID,
	input 				ARREADY,

    input	[3:0] 		RID,
    input	[31:0] 		RDATA,
    input	[1:0] 		RRESP,
	input  				RVALID,
	input  				RLAST,
    output				RREADY,

    output	[31:0]		AWADDR,
    output	[7:0]		AWLEN,
    output	[2:0]		AWSIZE,
    output	[3:0]		AWID,
    output	[1:0]		AWBURST,
	output				AWVALID,
	input  				AWREADY,
	
    output	[31:0] 		WDATA,
    output				WLAST,
    output	[3:0] 		WSTRB,
    output				WVALID,
	input				WREADY,

	input	[3:0] 		BID,
    input	[1:0] 		BRESP,
	input				BVALID,
    output				BREADY,
	
	output	[4:0]		rd_addr_hazard,

	input 				valid_i,
	input	ex2ls_pkt_t data_i,
	output 				ready_o,

	output 				valid_o,
	output	ls2wb_pkt_t data_o,
	input 				ready_i
);

//================= Load Types =================//
typedef enum logic [2:0] {
  LOAD_TYPE_LB   = 3'b000,
  LOAD_TYPE_LH   = 3'b001,
  LOAD_TYPE_LW   = 3'b010,
  LOAD_TYPE_LBU  = 3'b100,
  LOAD_TYPE_LHU  = 3'b101
} load_type_e;


/*
typedef struct packed {
    logic   [31:0]  result;
    logic   [31:0]  rs2_data;
    logic           ls_store;
    logic           ls_load;
    logic   [2:0]   ls_type;
    logic   [4:0]   rd_addr;
} ex2ls_pkt_t;

*/

// 解码
wire [31:0]		lsu_addr	=	data_i.result;
wire [31:0]		lsu_wdata	=	data_i.rs2_data;
wire 			lsu_store	=	data_i.ls_store;
wire			lsu_load	=	data_i.ls_load;
wire [2:0]		lsu_type	=	data_i.ls_type;
wire [4:0]      rd_addr     =   data_i.rd_addr;
// wire [4:0]		rest_data	=	data_i[4:0];

// 内部信号
logic	[31:0]	rd_data;
logic	[31:0]	lsu_rdata;
logic	[31:0]	axi_rdata;
logic	[1:0]	axi_rresp;
logic	[1:0]	axi_bresp;
logic			axi_done;

// 状态机
logic state, nstate;			// 0: IDLE 1: BUSY		LSU无需管WBU的ready信号

always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : nstate;
end

assign nstate = valid_i & lsu_load | valid_i & lsu_store | state & ~axi_done;


always_comb begin
	case(lsu_type)
		LOAD_TYPE_LB:	lsu_rdata = {{24{axi_rdata[7]}}, axi_rdata[7:0]};
		LOAD_TYPE_LH:	lsu_rdata = {{16{axi_rdata[15]}}, axi_rdata[15:0]};
		LOAD_TYPE_LW:	lsu_rdata = axi_rdata;
		LOAD_TYPE_LBU:	lsu_rdata = {24'b0, axi_rdata[7:0]};
		LOAD_TYPE_LHU:	lsu_rdata = {16'b0, axi_rdata[15:0]};
		default:		lsu_rdata = 32'b0;
	endcase
end

assign valid_o = valid_i & ~lsu_load & ~lsu_store | state & axi_done;
assign ready_o = ~nstate;

/*
// assign data_o = {rd_data, lsu_load, rest_data};

typedef struct packed {
    logic   [31:0]  result;
    logic   [4:0]   rd_addr;
    logic           is_load;
} ls2wb_pkt_t;
*/

assign rd_data = lsu_load ? lsu_rdata : lsu_addr;
// assign data_o = {rd_data, lsu_load, rest_data};
assign data_o.result    =   rd_data;
assign data_o.rd_addr   =   data_i.rd_addr;
assign data_o.is_load   =   lsu_load;

assign rd_addr_hazard = rd_addr & {5{valid_i | state}};

// AXI

wire	wen	=	lsu_store & valid_i;
wire	ren	=	lsu_load  & valid_i;

axi4_full_master u_axi4_full_master(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .wen        	(wen		 ),
    .ren        	(ren         ),
    .user_ready 	(1'b1	     ),
    .size        	(lsu_type[1:0] ),
	.len			(8'b0 		 ),
    .waddr      	(lsu_addr    ),
    .wdata      	(lsu_wdata   ),
    .raddr      	(lsu_addr    ),
    .rdata      	(axi_rdata   ),/* verilator lint_off PINCONNECTEMPTY */
	.rdata_valid	(),
    .rresp      	(axi_rresp   ),
    .wresp      	(axi_bresp   ),
    .done       	(axi_done    ),
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



endmodule
