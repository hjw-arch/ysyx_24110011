module ysyx_24110011 #(parameter WIDTH = 32) (
    input clock,
    input reset,/* verilator lint_off UNUSEDSIGNAL */
    input io_interrupt,

    // AXI4 Master Interface (connected to external slave)
    input         io_master_awready,
    output        io_master_awvalid,
    output [31:0] io_master_awaddr,
    output [3:0]  io_master_awid,
    output [7:0]  io_master_awlen,
    output [2:0]  io_master_awsize,
    output [1:0]  io_master_awburst,

    input         io_master_wready,
    output        io_master_wvalid,
    output [31:0] io_master_wdata,
    output [3:0]  io_master_wstrb,
    output        io_master_wlast,

    output        io_master_bready,
    input         io_master_bvalid,
    input  [1:0]  io_master_bresp,
    input  [3:0]  io_master_bid,

    input         io_master_arready,
    output        io_master_arvalid,
    output [31:0] io_master_araddr,
    output [3:0]  io_master_arid,
    output [7:0]  io_master_arlen,
    output [2:0]  io_master_arsize,
    output [1:0]  io_master_arburst,

    output        io_master_rready,
    input         io_master_rvalid,
    input  [1:0]  io_master_rresp,
    input  [31:0] io_master_rdata,
    input         io_master_rlast,
    input  [3:0]  io_master_rid,

    // AXI4 Slave Interface (added as per request)
    output        io_slave_awready,
    input         io_slave_awvalid,
    input  [31:0] io_slave_awaddr,
    input  [3:0]  io_slave_awid,
    input  [7:0]  io_slave_awlen,
    input  [2:0]  io_slave_awsize,
    input  [1:0]  io_slave_awburst,

    output        io_slave_wready,
    input         io_slave_wvalid,
    input  [31:0] io_slave_wdata,
    input  [3:0]  io_slave_wstrb,
    input         io_slave_wlast,

    input         io_slave_bready,
    output        io_slave_bvalid,
    output [1:0]  io_slave_bresp,
    output [3:0]  io_slave_bid,

    output        io_slave_arready,
    input         io_slave_arvalid,
    input  [31:0] io_slave_araddr,
    input  [3:0]  io_slave_arid,
    input  [7:0]  io_slave_arlen,
    input  [2:0]  io_slave_arsize,
    input  [1:0]  io_slave_arburst,

    input         io_slave_rready,
    output        io_slave_rvalid,
    output [1:0]  io_slave_rresp,
    output [31:0] io_slave_rdata,
    output        io_slave_rlast,
    output [3:0]  io_slave_rid
);

// 对slave接口做设置
assign io_slave_awready = 1'b0;
assign io_slave_wready  = 1'b0;
assign io_slave_bvalid  = 1'b0;
assign io_slave_bresp   = 2'b00;
assign io_slave_bid     = 4'b0000;
assign io_slave_arready = 1'b0;
assign io_slave_rvalid  = 1'b0;
assign io_slave_rresp   = 2'b00;
assign io_slave_rdata   = 32'b0;
assign io_slave_rlast   = 1'b0;
assign io_slave_rid     = 4'b0000;


// PC
// 五级流水线需要修改
wire [1 : 0] pc_sel;
wire pc_sel_for_adder_left;
wire is_branch;
wire [31 : 0] pc_imm;
wire [31 : 0] pc_inst;
wire [31 : 0] pc;


// IF
wire ifu_valid;
wire [63:0] ifu_data;
wire [4:0] rs1_addr;
wire [4:0] rs2_addr;

// ID
wire idu_ready;
wire idu_valid;
wire [191 : 0] idu_data;


// EX
wire exu_ready;
wire exu_valid;
wire [108 : 0] exu_data;
wire pre_lsu_ren;
wire pre_lsu_wen;

// LS
wire lsu_ready;
wire lsu_valid;
wire [103 : 0] lsu_data;
wire lsu_prerequest;

// WB
wire wbu_valid;
wire [31 : 0] rs1_data;
wire [31 : 0] rs2_data;


IFU #(
    .WIDTH 	(32  ))
u_IFU(
    .clk        	(clock             ),
    .rst        	(reset             ),
    .wbu_valid  	(wbu_valid       ),
    .pc         	(pc              ),
    .ifu_valid  	(ifu_valid       ),
    .ifu_data   	(ifu_data        ),
    .idu_ready  	(idu_ready       ),
    .prerequest 	(ifu_prerequest  ),
    .ARADDR     	(IFU_ARADDR      ),
    .ARVALID    	(IFU_ARVALID     ),
    .RREADY     	(IFU_RREADY     ),
    .ARID       	(IFU_ARID        ),
    .ARLEN      	(IFU_ARLEN       ),
    .ARSIZE     	(IFU_ARSIZE      ),
    .ARBURST    	(IFU_ARBURST     ),
    .ARREADY    	(IFU_ARREADY     ),
    .RVALID     	(IFU_RVALID      ),
    .RLAST      	(IFU_RLAST       ),
    .RID        	(IFU_RID         ),
    .RDATA      	(IFU_RDATA       ),
    .RRESP      	(IFU_RRESP       )
);




// ID
IDU IDU_INTER(
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),

    .clk(clock),
    .rst(reset),
    .ifu_valid(ifu_valid),
    .ifu_data(ifu_data),
    .idu_ready(idu_ready),
    .idu_valid(idu_valid),
    .idu_data(idu_data),
    .exu_ready(exu_ready),

    // PC直通，五级流水线需要修改
    .pc_sel(pc_sel),
    .pc_sel_for_adder_left(pc_sel_for_adder_left),
    .is_branch(is_branch),
    .pc_imm(pc_imm),
    .pc_inst(pc_inst)
);

// EX
EXU #(WIDTH) EXU_INTER(
    .clk(clock),
    .rst(reset),

    .idu_valid(idu_valid),
    .idu_data(idu_data),
    .exu_ready(exu_ready),

    .exu_valid(exu_valid),
    .exu_data(exu_data),
    .lsu_ready(lsu_ready),

    .pre_lsu_ren(pre_lsu_ren),
    .pre_lsu_wen(pre_lsu_wen),

    // 直通PC，五级流水线需修改
    .pc_sel(pc_sel),
    .pc_sel_for_adder_left(pc_sel_for_adder_left),
    .is_branch(is_branch),
    .imm(pc_imm),
    .inst(pc_inst),
    .pc(pc)
);

// LS
LSU u_LSU(
    .clk         	(clock            ),
    .rst         	(reset            ),
    .exu_valid   	(exu_valid    	  ),
    .exu_data    	(exu_data     	  ),
    .lsu_ready   	(lsu_ready    	  ),
    .lsu_valid   	(lsu_valid    	  ),
    .lsu_data    	(lsu_data     	  ),
    .wbu_ready   	(1'b1         	  ),        // 五级流水线需要更改
    .pre_lsu_ren 	(pre_lsu_ren  	  ),
    .pre_lsu_wen 	(pre_lsu_wen  	  ),
    .prerequest  	(lsu_prerequest	  ),
    .ARADDR      	(LSU_ARADDR       ),
    .ARVALID     	(LSU_ARVALID      ),
    .ARID        	(LSU_ARID         ),
    .ARLEN       	(LSU_ARLEN        ),
    .ARSIZE      	(LSU_ARSIZE       ),
    .ARBURST     	(LSU_ARBURST      ),
    .RREADY      	(LSU_RREADY       ),
    .AWADDR      	(LSU_AWADDR       ),
    .AWVALID     	(LSU_AWVALID      ),
    .AWLEN       	(LSU_AWLEN        ),
    .AWSIZE      	(LSU_AWSIZE       ),
    .AWID        	(LSU_AWID         ),
    .AWBURST     	(LSU_AWBURST      ),
    .WDATA       	(LSU_WDATA        ),
    .WLAST       	(LSU_WLAST        ),
    .WSTRB       	(LSU_WSTRB        ),
    .WVALID      	(LSU_WVALID       ),
    .BREADY      	(LSU_BREADY       ),
    .ARREADY     	(LSU_ARREADY      ),
    .RVALID      	(LSU_RVALID       ),
    .RLAST       	(LSU_RLAST        ),
    .RID         	(LSU_RID          ),
    .RDATA       	(LSU_RDATA        ),
    .RRESP       	(LSU_RRESP        ),
    .AWREADY     	(LSU_AWREADY      ),
    .WREADY      	(LSU_WREADY       ),
    .BVALID      	(LSU_BVALID       ),
    .BID         	(LSU_BID          ),
    .BRESP       	(LSU_BRESP        )
);



// WB
WBU #(WIDTH) WBU_INTER(
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),

    .clk(clock),
    .rst(reset),

    .lsu_valid(lsu_valid),
    .lsu_data(lsu_data),
    .wbu_valid(wbu_valid)
);



// AXI

// IFU
wire ifu_prerequest;
wire [31:0] IFU_ARADDR;
wire IFU_ARVALID;
wire IFU_RREADY;
wire [3:0] IFU_ARID;
wire [7:0] IFU_ARLEN;
wire [2:0] IFU_ARSIZE;
wire [1:0] IFU_ARBURST;
wire IFU_RLAST;
wire [3:0] IFU_RID;
wire IFU_ARREADY;
wire IFU_RVALID;
wire IFU_RLAST;
wire [3:0] IFU_RID;
wire [31:0] IFU_RDATA;
wire [1:0] IFU_RRESP;

// LSU
wire lsu_prerequest;
wire [31:0] LSU_ARADDR;
wire LSU_ARVALID;
wire [3:0] LSU_ARID;
wire [7:0] LSU_ARLEN;
wire [2:0] LSU_ARSIZE;
wire [1:0] LSU_ARBURST;
wire LSU_RREADY;
wire [31:0] LSU_AWADDR;
wire LSU_AWVALID;
wire [7:0] LSU_AWLEN;
wire [2:0] LSU_AWSIZE;
wire [3:0] LSU_AWID;
wire [1:0] LSU_AWBURST;
wire [31:0] LSU_WDATA;
wire LSU_WLAST;
wire [3:0] LSU_WSTRB;
wire LSU_WVALID;
wire LSU_BREADY;
wire LSU_ARREADY;
wire LSU_RVALID;
wire LSU_RLAST;
wire [3:0] LSU_RID;
wire [31:0] LSU_RDATA;
wire [1:0] LSU_RRESP;
wire LSU_AWREADY;
wire LSU_WREADY;
wire LSU_BVALID;
wire [3:0] LSU_BID;
wire [1:0] LSU_BRESP;

// input declaration of module axi4_full_arbiter
wire m0_prerequest;
wire [3:0] m0_arid;
wire [31:0] m0_araddr;
wire [7:0] m0_arlen;
wire [2:0] m0_arsize;
wire [1:0] m0_arburst;
wire m0_arvalid;
wire m0_rready;
wire [3:0] m0_awid;
wire [31:0] m0_awaddr;
wire [7:0] m0_awlen;
wire [2:0] m0_awsize;
wire [1:0] m0_awburst;
wire m0_awvalid;
wire [31:0] m0_wdata;
wire [3:0] m0_wstrb;
wire m0_wlast;
wire m0_wvalid;
wire m0_bready;

wire m1_prerequest;
wire [3:0] m1_arid;
wire [31:0] m1_araddr;
wire [7:0] m1_arlen;
wire [2:0] m1_arsize;
wire [1:0] m1_arburst;
wire m1_arvalid;
wire m1_rready;
wire [3:0] m1_awid;
wire [31:0] m1_awaddr;
wire [7:0] m1_awlen;
wire [2:0] m1_awsize;
wire [1:0] m1_awburst;
wire m1_awvalid;
wire [31:0] m1_wdata;
wire [3:0] m1_wstrb;
wire m1_wlast;
wire m1_wvalid;
wire m1_bready;

// output declaration of module axi4_full_arbiter
wire s_arready;
wire [3:0] s_rid;
wire [31:0] s_rdata;
wire [1:0] s_rresp;
wire s_rlast;
wire s_rvalid;
wire s_awready;
wire s_wready;
wire [3:0] s_bid;
wire [1:0] s_bresp;
wire s_bvalid;


wire m0_arready;
wire [3:0] m0_rid;
wire [31:0] m0_rdata;
wire [1:0] m0_rresp;
wire m0_rlast;
wire m0_rvalid;

/* verilator lint_off UNUSEDSIGNAL */
wire m0_awready;
wire m0_wready;
wire [3:0] m0_bid;
wire [1:0] m0_bresp;
wire m0_bvalid;

wire m1_arready;
wire [3:0] m1_rid;
wire [31:0] m1_rdata;
wire [1:0] m1_rresp;
wire m1_rlast;
wire m1_rvalid;
wire m1_awready;
wire m1_wready;
wire [3:0] m1_bid;
wire [1:0] m1_bresp;
wire m1_bvalid;
wire [3:0] s_arid;
wire [31:0] s_araddr;
wire [7:0] s_arlen;
wire [2:0] s_arsize;
wire [1:0] s_arburst;
wire s_arvalid;
wire s_rready;
wire [3:0] s_awid;
wire [31:0] s_awaddr;
wire [7:0] s_awlen;
wire [2:0] s_awsize;
wire [1:0] s_awburst;
wire s_awvalid;
wire [31:0] s_wdata;
wire [3:0] s_wstrb;
wire s_wlast;
wire s_wvalid;
wire s_bready;

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

// 信号连接
// IFU (Instruction Fetch Unit) connections to m0
assign m0_prerequest = ifu_prerequest;
assign m0_arid = IFU_ARID;
assign m0_araddr = IFU_ARADDR;
assign m0_arlen = IFU_ARLEN;
assign m0_arsize = IFU_ARSIZE;
assign m0_arburst = IFU_ARBURST;
assign m0_arvalid = IFU_ARVALID;
assign m0_rready = IFU_RREADY;

assign IFU_ARREADY = m0_arready;
assign IFU_RID = m0_rid;
assign IFU_RDATA = m0_rdata;
assign IFU_RRESP = m0_rresp;
assign IFU_RLAST = m0_rlast;
assign IFU_RVALID = m0_rvalid;

// Tie off unused IFU write channels
assign m0_awid = 4'b0;
assign m0_awaddr = 32'b0;
assign m0_awlen = 8'b0;
assign m0_awsize = 3'b0;
assign m0_awburst = 2'b0;
assign m0_awvalid = 1'b0;
assign m0_wdata = 32'b0;
assign m0_wstrb = 4'b0;
assign m0_wlast = 1'b0;
assign m0_wvalid = 1'b0;
assign m0_bready = 1'b1;

// LSU (Load Store Unit) connections to m1
assign m1_prerequest = lsu_prerequest;
assign m1_arid = LSU_ARID;
assign m1_araddr = LSU_ARADDR;
assign m1_arlen = LSU_ARLEN;
assign m1_arsize = LSU_ARSIZE;
assign m1_arburst = LSU_ARBURST;
assign m1_arvalid = LSU_ARVALID;
assign m1_rready = LSU_RREADY;
assign m1_awid = LSU_AWID;
assign m1_awaddr = LSU_AWADDR;
assign m1_awlen = LSU_AWLEN;
assign m1_awsize = LSU_AWSIZE;
assign m1_awburst = LSU_AWBURST;
assign m1_awvalid = LSU_AWVALID;
assign m1_wdata = LSU_WDATA;
assign m1_wstrb = LSU_WSTRB;
assign m1_wlast = LSU_WLAST;
assign m1_wvalid = LSU_WVALID;
assign m1_bready = LSU_BREADY;

assign LSU_ARREADY = m1_arready;
assign LSU_RID = m1_rid;
assign LSU_RDATA = m1_rdata;
assign LSU_RRESP = m1_rresp;
assign LSU_RLAST = m1_rlast;
assign LSU_RVALID = m1_rvalid;
assign LSU_AWREADY = m1_awready;
assign LSU_WREADY = m1_wready;
assign LSU_BID = m1_bid;
assign LSU_BRESP = m1_bresp;
assign LSU_BVALID = m1_bvalid;



// 连接到外设
// Connect arbiter slave interface to top-level AXI master signals
assign s_awready = io_master_awready;
assign io_master_awvalid = s_awvalid;
assign io_master_awaddr = s_awaddr;
assign io_master_awid = s_awid;
assign io_master_awlen = s_awlen;
assign io_master_awsize = s_awsize;
assign io_master_awburst = s_awburst;

assign s_wready = io_master_wready;
assign io_master_wvalid = s_wvalid;
assign io_master_wdata = s_wdata;
assign io_master_wstrb = s_wstrb;
assign io_master_wlast = s_wlast;

assign io_master_bready = s_bready;
assign s_bvalid = io_master_bvalid;
assign s_bresp = io_master_bresp;
assign s_bid = io_master_bid;

assign s_arready = io_master_arready;
assign io_master_arvalid = s_arvalid;
assign io_master_araddr = s_araddr;
assign io_master_arid = s_arid;
assign io_master_arlen = s_arlen;
assign io_master_arsize = s_arsize;
assign io_master_arburst = s_arburst;

assign io_master_rready = s_rready;
assign s_rvalid = io_master_rvalid;
assign s_rresp = io_master_rresp;
assign s_rdata = io_master_rdata;
assign s_rlast = io_master_rlast;
assign s_rid = io_master_rid;


// always_ff @(posedge clock) begin
// 	$display("RST = %d", reset);
// end


endmodule
