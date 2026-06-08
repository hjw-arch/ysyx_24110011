`include "./include/pipeline_pkt_pkg.sv"
module ysyx_24110011
import pipeline_pkt_pkg::*;
(
    input 			clock,
    input 			reset,/* verilator lint_off UNUSEDSIGNAL */
    input 			io_interrupt,

    input         	io_master_awready,
    output        	io_master_awvalid,
    output [31:0] 	io_master_awaddr,
    output [3:0]  	io_master_awid,
    output [7:0]  	io_master_awlen,
    output [2:0]  	io_master_awsize,
    output [1:0]  	io_master_awburst,

    input         	io_master_wready,
    output        	io_master_wvalid,
    output [31:0] 	io_master_wdata,
    output [3:0]  	io_master_wstrb,
    output        	io_master_wlast,

    output        	io_master_bready,
    input         	io_master_bvalid,
    input  [1:0]  	io_master_bresp,
    input  [3:0]  	io_master_bid,

    input         	io_master_arready,
    output        	io_master_arvalid,
    output [31:0] 	io_master_araddr,
    output [3:0]  	io_master_arid,
    output [7:0]  	io_master_arlen,
    output [2:0]  	io_master_arsize,
    output [1:0]  	io_master_arburst,

    output        	io_master_rready,
    input         	io_master_rvalid,
    input  [1:0]  	io_master_rresp,
    input  [31:0] 	io_master_rdata,
    input         	io_master_rlast,
    input  [3:0]  	io_master_rid,

    // AXI4 Slave 	Interface (added as per request)
    output        	io_slave_awready,
    input         	io_slave_awvalid,
    input  [31:0] 	io_slave_awaddr,
    input  [3:0]  	io_slave_awid,
    input  [7:0]  	io_slave_awlen,
    input  [2:0]  	io_slave_awsize,
    input  [1:0]  	io_slave_awburst,

    output        	io_slave_wready,
    input         	io_slave_wvalid,
    input  [31:0] 	io_slave_wdata,
    input  [3:0]  	io_slave_wstrb,
    input         	io_slave_wlast,

    input         	io_slave_bready,
    output        	io_slave_bvalid,
    output [1:0]  	io_slave_bresp,
    output [3:0]  	io_slave_bid,

    output        	io_slave_arready,
    input         	io_slave_arvalid,
    input  [31:0] 	io_slave_araddr,
    input  [3:0]  	io_slave_arid,
    input  [7:0]  	io_slave_arlen,
    input  [2:0]  	io_slave_arsize,
    input  [1:0]  	io_slave_arburst,

    input         	io_slave_rready,
    output        	io_slave_rvalid,
    output [1:0]  	io_slave_rresp,
    output [31:0] 	io_slave_rdata,
    output        	io_slave_rlast,
    output [3:0]  	io_slave_rid
);

// // 调试用
// logic [31:0] dpic_pc, dpic_inst;
// always_ff @(posedge clock) begin

// end

// 对slave接口做设置
assign io_slave_awready 	= 	1'b0;
assign io_slave_wready  	= 	1'b0;
assign io_slave_bvalid  	= 	1'b0;
assign io_slave_bresp   	= 	2'b00;
assign io_slave_bid     	= 	4'b0000;
assign io_slave_arready 	= 	1'b0;
assign io_slave_rvalid  	= 	1'b0;
assign io_slave_rresp   	= 	2'b00;
assign io_slave_rdata   	= 	32'b0;
assign io_slave_rlast   	= 	1'b0;
assign io_slave_rid     	= 	4'b0000;

// SoC/面积评估默认使用 RV32E；NPC-only 仿真可由 Makefile 传 CONFIG_RVI，
// 在 elaboration 阶段切换为 32 个通用寄存器，不引入运行时选择电路。
`ifdef CONFIG_RVI
localparam bit USE_RV32E = 1'b0;
`else
localparam bit USE_RV32E = 1'b1;
`endif


	// IF/ID
	logic 			if2id_pre_valid;
	if2id_pkt_t		if2id_pre_data;
	logic			if2id_pre_ready;
	logic 			if2id_valid;
	if2id_pkt_t		if2id_data;
	logic 			if2id_ready;

	// ID/EX
	logic 			id2ex_pre_valid;
	id2ex_pkt_t		id2ex_pre_data;
	logic			id2ex_pre_ready;
	logic			id2ex_valid;
	id2ex_pkt_t		id2ex_data;
	logic			id2ex_ready;

	// EX/LS
	logic			ex2ls_pre_valid;
	ex2ls_pkt_t		ex2ls_pre_data;
	logic			ex2ls_pre_ready;
	logic			ex2ls_valid;
	ex2ls_pkt_t		ex2ls_data;
	logic			ex2ls_ready;

	// LS/WB
	logic			ls2wb_pre_valid;
	ls2wb_pkt_t		ls2wb_pre_data;
	logic			ls2wb_pre_ready;
	logic			ls2wb_valid;
	ls2wb_pkt_t		ls2wb_data;
	logic			ls2wb_ready;
	logic [31:0]	rf_wdata;


	// RF
	logic [4:0]		rf_rs1_addr;
	logic [4:0]		rf_rs2_addr;
	logic [31:0]	rf_rs1_data;
	logic [31:0]	rf_rs2_data;

	// redirect/flush
	logic 			pipeline_flush;
	logic [31:0]	redirect_pc;
	logic			lsu_redirect_valid;
	logic [31:0]	lsu_redirect_pc;
	logic			wbu_redirect_valid;
	logic [31:0]	wbu_redirect_pc;
	logic			icache_inval;

	assign pipeline_flush = wbu_redirect_valid | lsu_redirect_valid;
	assign redirect_pc    = wbu_redirect_valid ? wbu_redirect_pc : lsu_redirect_pc;

// forward
logic [4:0]		id_rs1_addr;
logic [4:0]		id_rs2_addr;
	logic			id_rs1_used;
	logic			id_rs2_used;
	logic [4:0]		ex_rd_addr;
logic [4:0]		ls_rd_addr;
logic			ex_is_load;
logic			ex_is_csr;
logic			ls_is_csr;
logic			ls_can_wb;
fwd_sel_t		fwd_rs1_sel;
fwd_sel_t		fwd_rs2_sel;
logic			hazard_valid;


IFU u_IFU(
	.clk     	(clock        ),
	.rst     	(reset        ),
	.ARADDR  	(IFU_ARADDR   ),
	.ARVALID 	(IFU_ARVALID  ),
	.RREADY  	(IFU_RREADY   ),
	.ARID    	(IFU_ARID     ),
	.ARLEN   	(IFU_ARLEN    ),
	.ARSIZE  	(IFU_ARSIZE   ),
	.ARBURST 	(IFU_ARBURST  ),
	.ARREADY 	(IFU_ARREADY  ),
	.RVALID  	(IFU_RVALID   ),
	.RLAST   	(IFU_RLAST    ),
	.RID     	(IFU_RID      ),
	.RDATA   	(IFU_RDATA    ),
		.RRESP   	(IFU_RRESP    ),
		.icache_inval_i(icache_inval),
		.redirect_pc_i 	(redirect_pc  ),
		.redirect_valid_i(pipeline_flush),
		.valid_o 	(if2id_pre_valid),
		.data_o  	(if2id_pre_data ),
		.ready_i 	(if2id_pre_ready)
	);



pip_reg #(
	.WIDTH 	($bits(if2id_pkt_t)))
u_if2id_pip(
	.clk        	(clock       ),
		.rst        	(reset       ),
		.flush      	(pipeline_flush ),
		.pre_valid  	(if2id_pre_valid),
		.pre_data   	(if2id_pre_data ),
		.next_ready 	(if2id_ready    ),
		.pre_ready  	(if2id_pre_ready),
		.next_data  	(if2id_data     ),
		.next_valid 	(if2id_valid    )
	);




IDU u_IDU(
		.rf_rs1_addr_o(rf_rs1_addr),
		.rf_rs2_addr_o(rf_rs2_addr),
		.rf_rs1_data_i(rf_rs1_data),
		.rf_rs2_data_i(rf_rs2_data),
		.id_rs1_addr(id_rs1_addr   ),
		.id_rs2_addr(id_rs2_addr   ),
		.id_rs1_used(id_rs1_used   ),
		.id_rs2_used(id_rs2_used   ),
		.fwd_rs1_sel_i(fwd_rs1_sel ),
		.fwd_rs2_sel_i(fwd_rs2_sel ),
		.hazard_i 	(hazard_valid  ),
		.valid_i  	(if2id_valid   ),
		.data_i   	(if2id_data    ),
		.ready_o  	(if2id_ready   ),
		.valid_o  	(id2ex_pre_valid),
		.data_o   	(id2ex_pre_data ),
		.ready_i  	(id2ex_pre_ready)
);


pip_reg #(
	.WIDTH 	($bits(id2ex_pkt_t)))
u_id2ex_pip(
	.clk        	(clock       ),
		.rst        	(reset       ),
		.flush      	(pipeline_flush  ),
		.pre_valid  	(id2ex_pre_valid),
		.pre_data   	(id2ex_pre_data ),
		.next_ready 	(id2ex_ready    ),
		.pre_ready  	(id2ex_pre_ready),
		.next_data  	(id2ex_data     ),
		.next_valid 	(id2ex_valid    )
	);



	EXU u_EXU(
		.clk     	(clock	 ),
		.rst     	(reset	 ),
		.rd_addr_o  (ex_rd_addr      ),
		.fwd_ls_data_i(ex2ls_data.result),
		.fwd_wb_data_i(ls2wb_data.result),
		.valid_i 	(id2ex_valid	),
		.data_i  	(id2ex_data 	),
		.ready_o 	(id2ex_ready	),
		.valid_o 	(ex2ls_pre_valid),
		.data_o  	(ex2ls_pre_data ),
		.ready_i 	(ex2ls_pre_ready)
	);



pip_reg #(
	.WIDTH 	($bits(ex2ls_pkt_t)))
u_ex2ls_pip(
	.clk        	(clock       ),
		.rst        	(reset       ),
		.flush      	(pipeline_flush  ),
		.pre_valid  	(ex2ls_pre_valid),
		.pre_data   	(ex2ls_pre_data ),
		.next_ready 	(ex2ls_ready    ),
		.pre_ready  	(ex2ls_pre_ready),
		.next_data  	(ex2ls_data     ),
		.next_valid 	(ex2ls_valid    )
	);



LSU u_LSU(
	.clk     	(clock		  ),
	.rst     	(reset        ),
	.ARADDR  	(LSU_ARADDR   ),
	.ARID    	(LSU_ARID     ),
	.ARLEN   	(LSU_ARLEN    ),
	.ARSIZE  	(LSU_ARSIZE   ),
	.ARBURST 	(LSU_ARBURST  ),
	.ARVALID 	(LSU_ARVALID  ),
	.ARREADY 	(LSU_ARREADY  ),
	.RID     	(LSU_RID      ),
	.RDATA   	(LSU_RDATA    ),
	.RRESP   	(LSU_RRESP    ),
	.RVALID  	(LSU_RVALID   ),
	.RLAST   	(LSU_RLAST    ),
	.RREADY  	(LSU_RREADY   ),
	.AWADDR  	(LSU_AWADDR   ),
	.AWLEN   	(LSU_AWLEN    ),
	.AWSIZE  	(LSU_AWSIZE   ),
	.AWID    	(LSU_AWID     ),
	.AWBURST 	(LSU_AWBURST  ),
	.AWVALID 	(LSU_AWVALID  ),
	.AWREADY 	(LSU_AWREADY  ),
	.WDATA   	(LSU_WDATA    ),
	.WLAST   	(LSU_WLAST    ),
	.WSTRB   	(LSU_WSTRB    ),
	.WVALID  	(LSU_WVALID   ),
	.WREADY  	(LSU_WREADY   ),
	.BID     	(LSU_BID      ),
		.BRESP   	(LSU_BRESP    ),
		.BVALID  	(LSU_BVALID   ),
		.BREADY  	(LSU_BREADY   ),
		.rd_addr_o(ls_rd_addr),
		.redirect_pc_o(lsu_redirect_pc),
		.redirect_valid_o(lsu_redirect_valid),
		.kill_i		(wbu_redirect_valid),
		.valid_i 	(ex2ls_valid  ),
		.data_i  	(ex2ls_data   ),
		.ready_o 	(ex2ls_ready  ),
		.valid_o 	(ls2wb_pre_valid),
		.data_o  	(ls2wb_pre_data )
	);



pip_reg #(
	.WIDTH 	($bits(ls2wb_pkt_t)))
u_ls2wb_pip(
	.clk        	(clock       ),
		.rst        	(reset       ),
		.flush      	(wbu_redirect_valid),
		.pre_valid  	(ls2wb_pre_valid  ),
		.pre_data   	(ls2wb_pre_data   ),
		.next_ready 	(ls2wb_ready      ),
		.pre_ready  	(ls2wb_pre_ready  ),
		.next_data  	(ls2wb_data       ),
		.next_valid 	(ls2wb_valid      )
	);



WBU #(
	.RV32E		(USE_RV32E		)
	) u_WBU(
		.clk		(clock			),
		.rst		(reset			),
		.rf_rs1_addr_i(rf_rs1_addr	),
		.rf_rs2_addr_i(rf_rs2_addr	),
		.rf_rs1_data_o(rf_rs1_data	),
		.rf_rs2_data_o(rf_rs2_data	),
		.rf_wdata_o	(rf_wdata	    ),
		.redirect_valid_o(wbu_redirect_valid),
		.redirect_pc_o(wbu_redirect_pc),
		.icache_inval_o(icache_inval),
		.valid_i	(ls2wb_valid	),
		.data_i		(ls2wb_data		),
		.ready_o	(ls2wb_ready	)
	);


	assign ex_is_load	=	id2ex_valid & (id2ex_data.mem.cmd == MEM_LOAD);
	assign ex_is_csr	=	id2ex_valid & (id2ex_data.sys.csr_cmd != CSR_CMD_NONE);
	assign ls_is_csr	=	ex2ls_valid & (ex2ls_data.sys.csr_cmd != CSR_CMD_NONE);
	// WBU 固定 ready，LSU valid 即表示 LS 结果本拍可进入 WB/作为转发源。
	assign ls_can_wb	=	ls2wb_pre_valid;

hazard_unit u_hazard_unit(
	.id_rs1_addr  	(id_rs1_addr   ),
	.id_rs2_addr  	(id_rs2_addr   ),
	.id_rs1_used  	(id_rs1_used   ),
	.id_rs2_used  	(id_rs2_used   ),
	.ex_rd_addr   	(ex_rd_addr    ),
	.ex_is_load   	(ex_is_load    ),
	.ex_is_csr    	(ex_is_csr     ),
	.ls_rd_addr   	(ls_rd_addr    ),
	.ls_is_csr    	(ls_is_csr     ),
	.ls_can_wb    	(ls_can_wb     ),
	.fwd_rs1_sel  	(fwd_rs1_sel   ),
	.fwd_rs2_sel  	(fwd_rs2_sel   ),
	.hazard_valid 	(hazard_valid  )
);




// AXI

// IFU
logic 			ifu_prerequest = 1'b0;	// 权宜之计
logic	[31:0]	IFU_ARADDR;
logic			IFU_ARVALID;
logic			IFU_RREADY;
logic	[3:0] 	IFU_ARID;
logic	[7:0] 	IFU_ARLEN;
logic	[2:0] 	IFU_ARSIZE;
logic	[1:0] 	IFU_ARBURST;
logic			IFU_RLAST;
logic	[3:0] 	IFU_RID;
logic			IFU_ARREADY;
logic			IFU_RVALID;
logic	[31:0] 	IFU_RDATA;
logic	[1:0] 	IFU_RRESP;

// LSU
logic 			lsu_prerequest = 1'b0;	// 权宜之计
logic	[31:0] 	LSU_ARADDR;
logic			LSU_ARVALID;
logic	[3:0]	LSU_ARID;
logic	[7:0] 	LSU_ARLEN;
logic	[2:0] 	LSU_ARSIZE;
logic	[1:0] 	LSU_ARBURST;
logic			LSU_RREADY;
logic	[31:0]	LSU_AWADDR;
logic			LSU_AWVALID;
logic	[7:0] 	LSU_AWLEN;
logic	[2:0] 	LSU_AWSIZE;
logic	[3:0] 	LSU_AWID;
logic	[1:0] 	LSU_AWBURST;
logic	[31:0]	LSU_WDATA;
logic			LSU_WLAST;
logic	[3:0]	LSU_WSTRB;
logic			LSU_WVALID;
logic			LSU_BREADY;
logic			LSU_ARREADY;
logic			LSU_RVALID;
logic			LSU_RLAST;
logic	[3:0]	LSU_RID;
logic	[31:0]	LSU_RDATA;
logic	[1:0]	LSU_RRESP;
logic			LSU_AWREADY;
logic			LSU_WREADY;
logic			LSU_BVALID;
logic	[3:0] 	LSU_BID;
logic	[1:0] 	LSU_BRESP;

/***************************************** Declaration of ARBITER ********************************/

// input declaration of module axi4_full_arbiter
logic			m0_prerequest;
logic 	[3:0]	m0_arid;
logic 	[31:0]	m0_araddr;
logic 	[7:0] 	m0_arlen;
logic 	[2:0] 	m0_arsize;
logic 	[1:0] 	m0_arburst;
logic 			m0_arvalid;
logic 			m0_rready;
logic 	[3:0] 	m0_awid;
logic 	[31:0] 	m0_awaddr;
logic 	[7:0] 	m0_awlen;
logic 	[2:0] 	m0_awsize;
logic 	[1:0] 	m0_awburst;
logic 			m0_awvalid;
logic 	[31:0] 	m0_wdata;
logic 	[3:0] 	m0_wstrb;
logic 			m0_wlast;
logic 			m0_wvalid;
logic 			m0_bready;

logic 			m1_prerequest;
logic 	[3:0] 	m1_arid;
logic 	[31:0] 	m1_araddr;
logic 	[7:0] 	m1_arlen;
logic 	[2:0] 	m1_arsize;
logic 	[1:0] 	m1_arburst;
logic 			m1_arvalid;
logic 			m1_rready;
logic 	[3:0] 	m1_awid;
logic 	[31:0] 	m1_awaddr;
logic 	[7:0] 	m1_awlen;
logic 	[2:0] 	m1_awsize;
logic 	[1:0] 	m1_awburst;
logic 			m1_awvalid;
logic 	[31:0] 	m1_wdata;
logic 	[3:0] 	m1_wstrb;
logic 			m1_wlast;
logic 			m1_wvalid;
logic 			m1_bready;

// output declaration of module axi4_full_arbiter
logic			s_arready;
logic	[3:0]	s_rid;
logic	[31:0] 	s_rdata;
logic	[1:0] 	s_rresp;
logic			s_rlast;
logic			s_rvalid;
logic			s_awready;
logic			s_wready;
logic	[3:0]	s_bid;
logic	[1:0] 	s_bresp;
logic			s_bvalid;


logic			m0_arready;
logic	[3:0] 	m0_rid;
logic	[31:0] 	m0_rdata;
logic	[1:0]	m0_rresp;
logic			m0_rlast;
logic			m0_rvalid;

/* verilator lint_off UNUSEDSIGNAL */
logic			m0_awready;
logic			m0_wready;
logic	[3:0] 	m0_bid;
logic	[1:0] 	m0_bresp;
logic			m0_bvalid;

logic			m1_arready;
logic	[3:0] 	m1_rid;
logic	[31:0] 	m1_rdata;
logic	[1:0] 	m1_rresp;
logic			m1_rlast;
logic			m1_rvalid;
logic			m1_awready;
logic			m1_wready;
logic	[3:0] 	m1_bid;
logic	[1:0] 	m1_bresp;
logic			m1_bvalid;
logic	[3:0] 	s_arid;
logic	[31:0] 	s_araddr;
logic	[7:0] 	s_arlen;
logic	[2:0] 	s_arsize;
logic	[1:0] 	s_arburst;
logic			s_arvalid;
logic			s_rready;
logic	[3:0] 	s_awid;
logic	[31:0] 	s_awaddr;
logic	[7:0] 	s_awlen;
logic	[2:0] 	s_awsize;
logic	[1:0] 	s_awburst;
logic			s_awvalid;
logic	[31:0] 	s_wdata;
logic	[3:0] 	s_wstrb;
logic			s_wlast;
logic			s_wvalid;
logic			s_bready;

axi4_full_arbiter u_axi4_full_arbiter(
    .clk           	(clock            ),
    .rst           	(reset            ),
    .m0_prerequest 	(m0_prerequest  ),
    .m1_prerequest 	(m1_prerequest  ),
    .m0_arid       	(m0_arid        ),
    .m0_araddr     	(m0_araddr      ),
    .m0_arlen      	(m0_arlen       ),
    .m0_arsize     	(m0_arsize      ),
    .m0_arburst    	(m0_arburst     ),
    .m0_arvalid    	(m0_arvalid     ),
    .m0_arready    	(m0_arready     ),
    .m0_rid        	(m0_rid         ),
    .m0_rdata      	(m0_rdata       ),
    .m0_rresp      	(m0_rresp       ),
    .m0_rlast      	(m0_rlast       ),
    .m0_rvalid     	(m0_rvalid      ),
    .m0_rready     	(m0_rready      ),
    .m0_awid       	(m0_awid        ),
    .m0_awaddr     	(m0_awaddr      ),
    .m0_awlen      	(m0_awlen       ),
    .m0_awsize     	(m0_awsize      ),
    .m0_awburst    	(m0_awburst     ),
    .m0_awvalid    	(m0_awvalid     ),
    .m0_awready    	(m0_awready     ),
    .m0_wdata      	(m0_wdata       ),
    .m0_wstrb      	(m0_wstrb       ),
    .m0_wlast      	(m0_wlast       ),
    .m0_wvalid     	(m0_wvalid      ),
    .m0_wready     	(m0_wready      ),
    .m0_bid        	(m0_bid         ),
    .m0_bresp      	(m0_bresp       ),
    .m0_bvalid     	(m0_bvalid      ),
    .m0_bready     	(m0_bready      ),
    .m1_arid       	(m1_arid        ),
    .m1_araddr     	(m1_araddr      ),
    .m1_arlen      	(m1_arlen       ),
    .m1_arsize     	(m1_arsize      ),
    .m1_arburst    	(m1_arburst     ),
    .m1_arvalid    	(m1_arvalid     ),
    .m1_arready    	(m1_arready     ),
    .m1_rid        	(m1_rid         ),
    .m1_rdata      	(m1_rdata       ),
    .m1_rresp      	(m1_rresp       ),
    .m1_rlast      	(m1_rlast       ),
    .m1_rvalid     	(m1_rvalid      ),
    .m1_rready     	(m1_rready      ),
    .m1_awid       	(m1_awid        ),
    .m1_awaddr     	(m1_awaddr      ),
    .m1_awlen      	(m1_awlen       ),
    .m1_awsize     	(m1_awsize      ),
    .m1_awburst    	(m1_awburst     ),
    .m1_awvalid    	(m1_awvalid     ),
    .m1_awready    	(m1_awready     ),
    .m1_wdata      	(m1_wdata       ),
    .m1_wstrb      	(m1_wstrb       ),
    .m1_wlast      	(m1_wlast       ),
    .m1_wvalid     	(m1_wvalid      ),
    .m1_wready     	(m1_wready      ),
    .m1_bid        	(m1_bid         ),
    .m1_bresp      	(m1_bresp       ),
    .m1_bvalid     	(m1_bvalid      ),
    .m1_bready     	(m1_bready      ),
    .s_arid        	(s_arid         ),
    .s_araddr      	(s_araddr       ),
    .s_arlen       	(s_arlen        ),
    .s_arsize      	(s_arsize       ),
    .s_arburst     	(s_arburst      ),
    .s_arvalid     	(s_arvalid      ),
    .s_arready     	(s_arready      ),
    .s_rid         	(s_rid          ),
    .s_rdata       	(s_rdata        ),
    .s_rresp       	(s_rresp        ),
    .s_rlast       	(s_rlast        ),
    .s_rvalid      	(s_rvalid       ),
    .s_rready      	(s_rready       ),
    .s_awid        	(s_awid         ),
    .s_awaddr      	(s_awaddr       ),
    .s_awlen       	(s_awlen        ),
    .s_awsize      	(s_awsize       ),
    .s_awburst     	(s_awburst      ),
    .s_awvalid     	(s_awvalid      ),
    .s_awready     	(s_awready      ),
    .s_wdata       	(s_wdata        ),
    .s_wstrb       	(s_wstrb        ),
    .s_wlast       	(s_wlast        ),
    .s_wvalid      	(s_wvalid       ),
    .s_wready      	(s_wready       ),
    .s_bid         	(s_bid          ),
    .s_bresp       	(s_bresp        ),
    .s_bvalid      	(s_bvalid       ),
    .s_bready      	(s_bready       )
);




/*************************************** Declaration of Xbar *******************************************/
/******** M *********/
// signals declaration of module Xbar
logic	[3:0] 		m_arid;
logic	[31:0]		m_araddr;
logic	[7:0] 		m_arlen;
logic	[2:0] 		m_arsize;
logic	[1:0] 		m_arburst;
logic	      		m_arvalid;
logic	      		m_arready; // Output from Xbar, input to Arbiter

logic	[3:0]  		m_rid;   // Output from Xbar, input to Arbiter
logic	[31:0] 		m_rdata; // Output from Xbar, input to Arbiter
logic	[1:0]  		m_rresp; // Output from Xbar, input to Arbiter
logic	       		m_rlast; // Output from Xbar, input to Arbiter
logic	       		m_rvalid;// Output from Xbar, input to Arbiter
logic	       		m_rready;

logic	[3:0]  		m_awid;
logic	[31:0] 		m_awaddr;
logic	[7:0]  		m_awlen;
logic	[2:0]  		m_awsize;
logic	[1:0]  		m_awburst;
logic	       		m_awvalid;
logic	       		m_awready; // Output from Xbar, input to Arbiter

logic 	[31:0] 		m_wdata;
logic 	[3:0]  		m_wstrb;
logic 	       		m_wlast;
logic 	       		m_wvalid;
logic 	       		m_wready;  // Output from Xbar, input to Arbiter

logic	[3:0]		m_bid;    // Output from Xbar, input to Arbiter
logic	[1:0]		m_bresp;  // Output from Xbar, input to Arbiter
logic	     		m_bvalid; // Output from Xbar, input to Arbiter
logic	     		m_bready;


/************* S0 **************/
// Read Address Channel (Slave 0)
logic	[3:0] 		s0_arid;
logic	[31:0]		s0_araddr;
logic	[7:0] 		s0_arlen;
logic	[2:0] 		s0_arsize;
logic	[1:0] 		s0_arburst;
logic	      		s0_arvalid;
logic	      		s0_arready; // Input from Slave 0

// Read Data Channel (Slave 0)
logic	[3:0]  		s0_rid;     // Input from Slave 0
logic	[31:0] 		s0_rdata;   // Input from Slave 0
logic	[1:0]  		s0_rresp;   // Input from Slave 0
logic	       		s0_rlast;   // Input from Slave 0
logic	       		s0_rvalid;  // Input from Slave 0
logic	       		s0_rready;

// Write Address Channel (Slave 0)
logic	[3:0]  		s0_awid;
logic	[31:0] 		s0_awaddr;
logic	[7:0]  		s0_awlen;
logic	[2:0]  		s0_awsize;
logic	[1:0]  		s0_awburst;
logic	       		s0_awvalid;
logic	       		s0_awready; // Input from Slave 0

// Write Data Channel (Slave 0)
logic	[31:0] 		s0_wdata;
logic	[3:0]  		s0_wstrb;
logic	       		s0_wlast;
logic	       		s0_wvalid;
logic	       		s0_wready;  // Input from Slave 0

// Write Response Channel (Slave 0)
logic	[3:0]		s0_bid;     // Input from Slave 0
logic	[1:0]		s0_bresp;   // Input from Slave 0
logic	     		s0_bvalid;  // Input from Slave 0
logic	     		s0_bready;


/********* S1 **********/
// logics/Signals for Slave 1 Interface connected to Xbar
// Read Address Channel (Slave 1)
logic	[3:0] 		s1_arid;
logic	[31:0]		s1_araddr;
logic	[7:0] 		s1_arlen;
logic	[2:0] 		s1_arsize;
logic	[1:0] 		s1_arburst;
logic	      		s1_arvalid;
logic	      		s1_arready; // Input from Slave 1

// Read Data Channel (Slave 1)
logic	[3:0] 		s1_rid;     // Input from Slave 1
logic	[31:0]		s1_rdata;   // Input from Slave 1
logic	[1:0] 		s1_rresp;   // Input from Slave 1
logic	      		s1_rlast;   // Input from Slave 1
logic	      		s1_rvalid;  // Input from Slave 1
logic	      		s1_rready;

// Write Address Channel (Slave 1)
logic	[3:0]  		s1_awid;
logic	[31:0] 		s1_awaddr;
logic	[7:0]  		s1_awlen;
logic	[2:0]  		s1_awsize;
logic	[1:0]  		s1_awburst;
logic	       		s1_awvalid;
logic	       		s1_awready; // Input from Slave 1

// Write Data Channel (Slave 1)
logic	[31:0] 		s1_wdata;
logic	[3:0]  		s1_wstrb;
logic	       		s1_wlast;
logic	       		s1_wvalid;
logic	       		s1_wready;  // Input from Slave 1

// Write Response Channel (Slave 1)
logic	[3:0]		s1_bid;     // Input from Slave 1
logic	[1:0]		s1_bresp;   // Input from Slave 1
logic	     		s1_bvalid;  // Input from Slave 1
logic	     		s1_bready;

Xbar u_Xbar(
	.m_arid     	(m_arid      ),
	.m_araddr   	(m_araddr    ),
	.m_arlen    	(m_arlen     ),
	.m_arsize   	(m_arsize    ),
	.m_arburst  	(m_arburst   ),
	.m_arvalid  	(m_arvalid   ),
	.m_arready  	(m_arready   ),
	.m_rid      	(m_rid       ),
	.m_rdata    	(m_rdata     ),
	.m_rresp    	(m_rresp     ),
	.m_rlast    	(m_rlast     ),
	.m_rvalid   	(m_rvalid    ),
	.m_rready   	(m_rready    ),
	.m_awid     	(m_awid      ),
	.m_awaddr   	(m_awaddr    ),
	.m_awlen    	(m_awlen     ),
	.m_awsize   	(m_awsize    ),
	.m_awburst  	(m_awburst   ),
	.m_awvalid  	(m_awvalid   ),
	.m_awready  	(m_awready   ),
	.m_wdata    	(m_wdata     ),
	.m_wstrb    	(m_wstrb     ),
	.m_wlast    	(m_wlast     ),
	.m_wvalid   	(m_wvalid    ),
	.m_wready   	(m_wready    ),
	.m_bid      	(m_bid       ),
	.m_bresp    	(m_bresp     ),
	.m_bvalid   	(m_bvalid    ),
	.m_bready   	(m_bready    ),
	.s0_arid    	(s0_arid     ),
	.s0_araddr  	(s0_araddr   ),
	.s0_arlen   	(s0_arlen    ),
	.s0_arsize  	(s0_arsize   ),
	.s0_arburst 	(s0_arburst  ),
	.s0_arvalid 	(s0_arvalid  ),
	.s0_arready 	(s0_arready  ),
	.s0_rid     	(s0_rid      ),
	.s0_rdata   	(s0_rdata    ),
	.s0_rresp   	(s0_rresp    ),
	.s0_rlast   	(s0_rlast    ),
	.s0_rvalid  	(s0_rvalid   ),
	.s0_rready  	(s0_rready   ),
	.s0_awid    	(s0_awid     ),
	.s0_awaddr  	(s0_awaddr   ),
	.s0_awlen   	(s0_awlen    ),
	.s0_awsize  	(s0_awsize   ),
	.s0_awburst 	(s0_awburst  ),
	.s0_awvalid 	(s0_awvalid  ),
	.s0_awready 	(s0_awready  ),
	.s0_wdata   	(s0_wdata    ),
	.s0_wstrb   	(s0_wstrb    ),
	.s0_wlast   	(s0_wlast    ),
	.s0_wvalid  	(s0_wvalid   ),
	.s0_wready  	(s0_wready   ),
	.s0_bid     	(s0_bid      ),
	.s0_bresp   	(s0_bresp    ),
	.s0_bvalid  	(s0_bvalid   ),
	.s0_bready  	(s0_bready   ),
	.s1_arid    	(s1_arid     ),
	.s1_araddr  	(s1_araddr   ),
	.s1_arlen   	(s1_arlen    ),
	.s1_arsize  	(s1_arsize   ),
	.s1_arburst 	(s1_arburst  ),
	.s1_arvalid 	(s1_arvalid  ),
	.s1_arready 	(s1_arready  ),
	.s1_rid     	(s1_rid      ),
	.s1_rdata   	(s1_rdata    ),
	.s1_rresp   	(s1_rresp    ),
	.s1_rlast   	(s1_rlast    ),
	.s1_rvalid  	(s1_rvalid   ),
	.s1_rready  	(s1_rready   ),
	.s1_awid    	(s1_awid     ),
	.s1_awaddr  	(s1_awaddr   ),
	.s1_awlen   	(s1_awlen    ),
	.s1_awsize  	(s1_awsize   ),
	.s1_awburst 	(s1_awburst  ),
	.s1_awvalid 	(s1_awvalid  ),
	.s1_awready 	(s1_awready  ),
	.s1_wdata   	(s1_wdata    ),
	.s1_wstrb   	(s1_wstrb    ),
	.s1_wlast   	(s1_wlast    ),
	.s1_wvalid  	(s1_wvalid   ),
	.s1_wready  	(s1_wready   ),
	.s1_bid     	(s1_bid      ),
	.s1_bresp   	(s1_bresp    ),
	.s1_bvalid  	(s1_bvalid   ),
	.s1_bready  	(s1_bready   )
);





/***************************** Declaration of CLINT(S1) ***************************/
// Signals declaration of module CLINT
// logics/Signals for CLINT AXI Interface
// Read Address Channel
logic	[3:0] 		clint_arid;
logic	[31:0]		clint_araddr;
logic	[7:0] 		clint_arlen;
logic	[2:0] 		clint_arsize;
logic	[1:0] 		clint_arburst;
logic	      		clint_arvalid;
logic	      		clint_arready; // From CLINT

// Read Data Channel
logic	[3:0]  		clint_rid;     // From CLINT
logic	[31:0] 		clint_rdata;   // From CLINT
logic	[1:0]  		clint_rresp;   // From CLINT
logic	       		clint_rlast;   // From CLINT
logic	       		clint_rvalid;  // From CLINT
logic	       		clint_rready;

// Write Address Channel
logic	[3:0] 		clint_awid;
logic	[31:0]		clint_awaddr;
logic	[7:0] 		clint_awlen;
logic	[2:0] 		clint_awsize;
logic	[1:0] 		clint_awburst;
logic	      		clint_awvalid;
logic	      		clint_awready; // From CLINT

// Write Data Channel
logic	[31:0]		clint_wdata;
logic	[3:0] 		clint_wstrb;
logic	      		clint_wlast;
logic	      		clint_wvalid;
logic	      		clint_wready;  // From CLINT

// Write Response Channel
logic	[3:0]		clint_bid;     // From CLINT
logic	[1:0]		clint_bresp;   // From CLINT
logic	     		clint_bvalid;  // From CLINT
logic	     		clint_bready;
CLINT u_CLINT(
    .clk     (clock          ), // Assuming clk/rst are global or passed directly
    .rst     (reset          ), // Assuming clk/rst are global or passed directly
    .arid    (clint_arid     ),
    .araddr  (clint_araddr   ),
    .arlen   (clint_arlen    ),
    .arsize  (clint_arsize   ),
    .arburst (clint_arburst  ),
    .arvalid (clint_arvalid  ),
    .arready (clint_arready  ), // Output from CLINT
    .rid     (clint_rid      ), // Output from CLINT
    .rdata   (clint_rdata    ), // Output from CLINT
    .rresp   (clint_rresp    ), // Output from CLINT
    .rlast   (clint_rlast    ), // Output from CLINT
    .rvalid  (clint_rvalid   ), // Output from CLINT
    .rready  (clint_rready   ),
    .awid    (clint_awid     ),
    .awaddr  (clint_awaddr   ),
    .awlen   (clint_awlen    ),
    .awsize  (clint_awsize   ),
    .awburst (clint_awburst  ),
    .awvalid (clint_awvalid  ),
    .awready (clint_awready  ), // Output from CLINT
    .wdata   (clint_wdata    ),
    .wstrb   (clint_wstrb    ),
    .wlast   (clint_wlast    ),
    .wvalid  (clint_wvalid   ),
    .wready  (clint_wready   ), // Output from CLINT
    .bid     (clint_bid      ), // Output from CLINT
    .bresp   (clint_bresp    ), // Output from CLINT
    .bvalid  (clint_bvalid   ), // Output from CLINT
    .bready  (clint_bready   )
);




/*************************************** IFU->ARBITER LSU->ARBITER ***********************************/
// IFU (Instruction Fetch Unit) connections to m0
assign m0_prerequest 		= 		ifu_prerequest;
assign m0_arid 				= 		IFU_ARID;
assign m0_araddr 			= 		IFU_ARADDR;
assign m0_arlen 			= 		IFU_ARLEN;
assign m0_arsize 			= 		IFU_ARSIZE;
assign m0_arburst 			= 		IFU_ARBURST;
assign m0_arvalid 			= 		IFU_ARVALID;
assign m0_rready 			= 		IFU_RREADY;

assign IFU_ARREADY 			= 		m0_arready;
assign IFU_RID 				= 		m0_rid;
assign IFU_RDATA 			= 		m0_rdata;
assign IFU_RRESP 			= 		m0_rresp;
assign IFU_RLAST 			= 		m0_rlast;
assign IFU_RVALID 			= 		m0_rvalid;

// Tie off unused IFU write channels
assign m0_awid 				= 		4'b0;
assign m0_awaddr 			= 		32'b0;
assign m0_awlen 			= 		8'b0;
assign m0_awsize 			= 		3'b0;
assign m0_awburst 			= 		2'b0;
assign m0_awvalid 			= 		1'b0;
assign m0_wdata 			= 		32'b0;
assign m0_wstrb 			= 		4'b0;
assign m0_wlast 			= 		1'b0;
assign m0_wvalid 			= 		1'b0;
assign m0_bready 			= 		1'b1;

// LSU (Load Store Unit) connections to m1
assign m1_prerequest 		= 		lsu_prerequest;
assign m1_arid 				= 		LSU_ARID;
assign m1_araddr 			= 		LSU_ARADDR;
assign m1_arlen 			= 		LSU_ARLEN;
assign m1_arsize 			= 		LSU_ARSIZE;
assign m1_arburst 			=		LSU_ARBURST;
assign m1_arvalid 			= 		LSU_ARVALID;
assign m1_rready 			= 		LSU_RREADY;
assign m1_awid 				= 		LSU_AWID;
assign m1_awaddr 			= 		LSU_AWADDR;
assign m1_awlen 			= 		LSU_AWLEN;
assign m1_awsize 			= 		LSU_AWSIZE;
assign m1_awburst 			= 		LSU_AWBURST;
assign m1_awvalid 			= 		LSU_AWVALID;
assign m1_wdata 			= 		LSU_WDATA;
assign m1_wstrb 			= 		LSU_WSTRB;
assign m1_wlast 			= 		LSU_WLAST;
assign m1_wvalid 			= 		LSU_WVALID;
assign m1_bready 			= 		LSU_BREADY;

assign LSU_ARREADY 			= 		m1_arready;
assign LSU_RID 				= 		m1_rid;
assign LSU_RDATA 			= 		m1_rdata;
assign LSU_RRESP 			= 		m1_rresp;
assign LSU_RLAST 			= 		m1_rlast;
assign LSU_RVALID 			= 		m1_rvalid;
assign LSU_AWREADY 			= 		m1_awready;
assign LSU_WREADY 			= 		m1_wready;
assign LSU_BID 				= 		m1_bid;
assign LSU_BRESP 			= 		m1_bresp;
assign LSU_BVALID 			= 		m1_bvalid;



/**************************** ARBITER <---> Xbar *************************************/

// Read Address Channel (Arbiter -> Xbar)
assign m_arid     = 	s_arid;
assign m_araddr   = 	s_araddr;
assign m_arlen    = 	s_arlen;
assign m_arsize   = 	s_arsize;
assign m_arburst  = 	s_arburst;
assign m_arvalid  = 	s_arvalid;
// Read Address Channel (Xbar -> Arbiter)
assign s_arready  = 	m_arready;

// Read Data Channel (Xbar -> Arbiter)
assign s_rid      = 	m_rid;
assign s_rdata    = 	m_rdata;
assign s_rresp    = 	m_rresp;
assign s_rlast    = 	m_rlast;
assign s_rvalid   = 	m_rvalid;
// Read Data Channel (Arbiter -> Xbar)
assign m_rready   = 	s_rready;

// Write Address Channel (Arbiter -> Xbar)
assign m_awid     = 	s_awid;
assign m_awaddr   = 	s_awaddr;
assign m_awlen    = 	s_awlen;
assign m_awsize   = 	s_awsize;
assign m_awburst  = 	s_awburst;
assign m_awvalid  = 	s_awvalid;
// Write Address Channel (Xbar -> Arbiter)
assign s_awready  = 	m_awready;

// Write Data Channel (Arbiter -> Xbar)
assign m_wdata    = 	s_wdata;
assign m_wstrb    = 	s_wstrb;
assign m_wlast    = 	s_wlast;
assign m_wvalid   = 	s_wvalid;
// Write Data Channel (Xbar -> Arbiter)
assign s_wready   = 	m_wready;

// Write Response Channel (Xbar -> Arbiter)
assign s_bid      = 	m_bid;
assign s_bresp    = 	m_bresp;
assign s_bvalid   = 	m_bvalid;
// Write Response Channel (Arbiter -> Xbar)
assign m_bready   = 	s_bready;





/*************************************** Xbar->S0 *******************************/

// TO S0
// Connect arbiter slave interface to top-level AXI master signals
assign s0_awready			= 		io_master_awready;
assign io_master_awvalid	= 		s0_awvalid;
assign io_master_awaddr		= 		s0_awaddr;
assign io_master_awid		= 		s0_awid;
assign io_master_awlen		= 		s0_awlen;
assign io_master_awsize		= 		s0_awsize;
assign io_master_awburst	= 		s0_awburst;

assign s0_wready			= 		io_master_wready;
assign io_master_wvalid 	= 		s0_wvalid;
assign io_master_wdata 		= 		s0_wdata;
assign io_master_wstrb 		= 		s0_wstrb;
assign io_master_wlast 		= 		s0_wlast;

assign io_master_bready 	= 		s0_bready;
assign s0_bvalid 			= 		io_master_bvalid;
assign s0_bresp 			= 		io_master_bresp;
assign s0_bid 				= 		io_master_bid;

assign s0_arready 			= 		io_master_arready;
assign io_master_arvalid 	= 		s0_arvalid;
assign io_master_araddr 	= 		s0_araddr;
assign io_master_arid 		= 		s0_arid;
assign io_master_arlen 		= 		s0_arlen;
assign io_master_arsize 	= 		s0_arsize;
assign io_master_arburst 	= 		s0_arburst;

assign io_master_rready 	= 		s0_rready;
assign s0_rvalid 			= 		io_master_rvalid;
assign s0_rresp 			= 		io_master_rresp;
assign s0_rdata 			= 		io_master_rdata;
assign s0_rlast 			= 		io_master_rlast;
assign s0_rid 				= 		io_master_rid;

/*************************************** Xbar->S1 *******************************/
// Read Address Channel (Xbar S1 Output -> CLINT Input)
assign clint_arid    		= 		s1_arid;
assign clint_araddr  		= 		s1_araddr;
assign clint_arlen   		= 		s1_arlen;
assign clint_arsize  		= 		s1_arsize;
assign clint_arburst 		= 		s1_arburst;
assign clint_arvalid 		= 		s1_arvalid;
// Read Address Channel (CLINT Output -> Xbar S1 Input)
assign s1_arready    		= 		clint_arready;

// Read Data Channel (CLINT Output -> Xbar S1 Input)
assign s1_rid        		= 		clint_rid;
assign s1_rdata      		= 		clint_rdata;
assign s1_rresp      		= 		clint_rresp;
assign s1_rlast      		= 		clint_rlast;
assign s1_rvalid     		= 		clint_rvalid;
// Read Data Channel (Xbar S1 Output -> CLINT Input)
assign clint_rready  		= 		s1_rready;

// Write Address Channel (Xbar S1 Output -> CLINT Input)
assign clint_awid    		= 		s1_awid;
assign clint_awaddr  		= 		s1_awaddr;
assign clint_awlen   		= 		s1_awlen;
assign clint_awsize  		= 		s1_awsize;
assign clint_awburst 		= 		s1_awburst;
assign clint_awvalid 		= 		s1_awvalid;
// Write Address Channel (CLINT Output -> Xbar S1 Input)
assign s1_awready    		= 		clint_awready;

// Write Data Channel (Xbar S1 Output -> CLINT Input)
assign clint_wdata   		= 		s1_wdata;
assign clint_wstrb   		= 		s1_wstrb;
assign clint_wlast   		= 		s1_wlast;
assign clint_wvalid  		= 		s1_wvalid;
// Write Data Channel (CLINT Output -> Xbar S1 Input)
assign s1_wready     		= 		clint_wready;

// Write Response Channel (CLINT Output -> Xbar S1 Input)
assign s1_bid        		= 		clint_bid;
assign s1_bresp      		= 		clint_bresp;
assign s1_bvalid     		= 		clint_bvalid;
// Write Response Channel (Xbar S1 Output -> CLINT Input)
assign clint_bready  		= 		s1_bready;



endmodule
