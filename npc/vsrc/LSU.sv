`include "./include/pipeline_pkt_pkg.sv"
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
    output  [31:0]      pc_target_o,
    output              flush_o,
	input				kill_i,

	input 				valid_i,
	input	ex2ls_pkt_t data_i,
	output 				ready_o,

	output 				valid_o,
	output	ls2wb_pkt_t data_o,
	input 				ready_i
);

	//================= Load Types =================//
	typedef enum logic [2:0] {
		LOAD_TYPE_LB  = 3'b000,
		LOAD_TYPE_LH  = 3'b001,
		LOAD_TYPE_LW  = 3'b010,
		LOAD_TYPE_LBU = 3'b100,
		LOAD_TYPE_LHU = 3'b101
	} load_type_e;

	typedef enum logic [1:0] {
		S_IDLE,
		S_BUSY,
		S_RESP
	} state_t;

	state_t state, nstate;

	logic [31:0] load_result_r;
	logic [31:0] lsu_rdata;
	logic [31:0] axi_rdata;
	logic        axi_done;

	wire input_is_load  = data_i.mem.cmd == MEM_LOAD;
	wire input_is_store = data_i.mem.cmd == MEM_STORE;
	wire input_is_mem   = input_is_load | input_is_store;

	wire state_idle = state == S_IDLE;
	wire state_busy = state == S_BUSY;
	wire state_resp = state == S_RESP;

	wire input_killed   = kill_i & state_idle;
	wire mem_req_fire   = ~input_killed & state_idle & valid_i & input_is_mem;
	wire mem_resp_valid = state_resp | (state_busy & axi_done);

	// 非访存指令直接透传到 WBU。
	// load/store 期间反压住 EX/LS 寄存器，让级间寄存器保持当前 packet，
	// LSU 内部不再额外保存整包数据，面积更小。
	assign ready_o = input_killed ? 1'b1 :
					 state_idle ? ((valid_i & input_is_mem) ? 1'b0 : ready_i) :
					 (mem_resp_valid & ready_i);

	assign valid_o = ~input_killed & (state_idle ? (valid_i & ~input_is_mem) : mem_resp_valid);

	always_comb begin
		unique case (state)
			S_IDLE: nstate = mem_req_fire ? S_BUSY : S_IDLE;
			S_BUSY: nstate = axi_done ? (ready_i ? S_IDLE : S_RESP) : S_BUSY;
			S_RESP: nstate = ready_i ? S_IDLE : S_RESP;
			default: nstate = S_IDLE;
		endcase
	end

	always_ff @(posedge clk) begin
		state <= rst ? S_IDLE : nstate;
	end

	// 如果 WBU 当拍不能接收，load 数据需要暂存在 LSU 内部。
	always_ff @(posedge clk) begin
		if (state_busy & axi_done) begin
			load_result_r <= lsu_rdata;
		end
	end

	wire [31:0] lsu_addr  = data_i.result;
	wire [31:0] lsu_wdata = data_i.store_data;
	wire [2:0]  lsu_type  = data_i.meta.inst[14:12];

	always_comb begin
		unique case (load_type_e'(lsu_type))
			LOAD_TYPE_LB:  lsu_rdata = {{24{axi_rdata[7]}},  axi_rdata[7:0]};
			LOAD_TYPE_LH:  lsu_rdata = {{16{axi_rdata[15]}}, axi_rdata[15:0]};
			LOAD_TYPE_LW:  lsu_rdata = axi_rdata;
			LOAD_TYPE_LBU: lsu_rdata = {24'b0, axi_rdata[7:0]};
			LOAD_TYPE_LHU: lsu_rdata = {16'b0, axi_rdata[15:0]};
			default:       lsu_rdata = 32'b0;
		endcase
	end

	wire [31:0] mem_result = state_resp ? load_result_r : lsu_rdata;
	wire [31:0] out_result = input_is_load ? mem_result : data_i.result;

	assign data_o.meta   = data_i.meta;
	assign data_o.wb     = data_i.wb;
	assign data_o.sys    = data_i.sys;
	assign data_o.result = out_result;

	wire [4:0] rd_addr = data_i.meta.inst[11:7];
	assign rd_addr_hazard = rd_addr & {5{valid_i & data_i.wb.rd_wen & ~input_killed}};

	// LSU 只负责普通控制流重定向；fence.i/ecall/mret 统一在 WBU 提交点处理。
	wire        out_redirect_valid = data_i.redirect.valid;
	wire [31:0] out_redirect_addr  = data_i.redirect.addr;
	wire        output_fire        = valid_o & ready_i;

	assign flush_o     = ~input_killed & output_fire & out_redirect_valid;
	assign pc_target_o = out_redirect_addr;

	// AXI
	// 这里全程发信号直到状态机回到idle，可能存在时序问题
	wire wen = mem_req_fire & input_is_store;
	wire ren = mem_req_fire & input_is_load;

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
    .rresp      	(),
    .wresp      	(),
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
