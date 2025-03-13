module ysyx #(parameter WIDTH = 32) (
    input clk,
    input rst,

    // 用于测试
    output [31 : 0] inst,
    output [31 : 0] PC
);

assign inst = ifu_data[63 : 32];
assign PC = ifu_data[31 : 0];

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
wire [63 : 0] ifu_data;
wire [4 : 0] rs1_addr;
wire [4 : 0] rs2_addr;
wire ifu_prerequest;

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


// IF
IFU #(WIDTH) IFU_INTER(
    .clk       	(clk        ),
    .rst       	(rst        ),
    .wbu_valid  (wbu_valid  ),
    .pc        	(pc         ),
    .ifu_valid 	(ifu_valid  ),
    .ifu_data  	(ifu_data   ),
    .idu_ready 	(idu_ready  ),
    // SRAM
    .prerequest(ifu_prerequest),
    .ARADDR    	(IFU_ARADDR ),
    .ARVALID   	(IFU_ARVALID),
    .RREADY    	(IFU_RREADY ),
    .AWADDR    	(IFU_AWADDR ),
    .AWVALID   	(IFU_AWVALID),
    .WDATA     	(IFU_WDATA  ),
    .WSTRB     	(IFU_WSTRB  ),
    .WVALID    	(IFU_WVALID ),
    .BREADY    	(IFU_BREADY ),
    .ARREADY   	(IFU_ARREADY),
    .RVALID    	(IFU_RVALID ),
    .RDATA     	(IFU_RDATA  ),
    .RRESP     	(IFU_RRESP  ),
    .AWREADY   	(IFU_AWREADY),
    .WREADY    	(IFU_WREADY ),
    .BVALID    	(IFU_BVALID ),
    .BRESP     	(IFU_BRESP  )
);



// ID
IDU IDU_INTER(
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),

    .clk(clk),
    .rst(rst),
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
    .clk(clk),
    .rst(rst),

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
LSU LSU_INTER(
    .clk       	(clk        ),
    .rst       	(rst        ),
    .exu_valid 	(exu_valid  ),
    .exu_data  	(exu_data   ),
    .lsu_ready 	(lsu_ready  ),
    .lsu_valid 	(lsu_valid  ),
    .lsu_data  	(lsu_data   ),
    .wbu_ready 	(1'b1       ),
    // SRAM
    .pre_lsu_ren(pre_lsu_ren),
    .pre_lsu_wen(pre_lsu_wen),
    .prerequest(lsu_prerequest),
    .ARADDR    	(LSU_ARADDR ),
    .ARVALID   	(LSU_ARVALID),
    .RREADY    	(LSU_RREADY ),
    .AWADDR    	(LSU_AWADDR ),
    .AWVALID   	(LSU_AWVALID),
    .WDATA     	(LSU_WDATA  ),
    .WSTRB     	(LSU_WSTRB  ),
    .WVALID    	(LSU_WVALID ),
    .BREADY    	(LSU_BREADY ),
    .ARREADY   	(LSU_ARREADY),
    .RVALID    	(LSU_RVALID ),
    .RDATA     	(LSU_RDATA  ),
    .RRESP     	(LSU_RRESP  ),
    .AWREADY   	(LSU_AWREADY),
    .WREADY    	(LSU_WREADY ),
    .BVALID    	(LSU_BVALID ),
    .BRESP     	(LSU_BRESP  )
);


// WB
WBU #(WIDTH) WBU_INTER(
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),

    .clk(clk),
    .rst(rst),

    .lsu_valid(lsu_valid),
    .lsu_data(lsu_data),
    .wbu_valid(wbu_valid)
);





// IFU & LSU Interface
// output declaration of module axi4_lite_master
wire [31:0] LSU_ARADDR, IFU_ARADDR;
wire LSU_ARVALID, IFU_ARVALID;
wire LSU_RREADY, IFU_RREADY;
wire [31:0] LSU_AWADDR, IFU_AWADDR;
wire LSU_AWVALID, IFU_AWVALID;
wire [31:0] LSU_WDATA, IFU_WDATA;
wire [3:0] LSU_WSTRB, IFU_WSTRB;
wire LSU_WVALID, IFU_WVALID;
wire LSU_BREADY, IFU_BREADY;

// input declaration of module SRAM
wire LSU_ARREADY, IFU_ARREADY;
wire LSU_RVALID, IFU_RVALID;
wire [31:0] LSU_RDATA, IFU_RDATA;
wire [1:0] LSU_RRESP, IFU_RRESP;
wire LSU_AWREADY, IFU_AWREADY;
wire LSU_WREADY, IFU_WREADY;
wire LSU_BVALID, IFU_BVALID;
wire [1:0] LSU_BRESP, IFU_BRESP;

// output declaration of module axi4_lite_arbiter
wire [1 : 0] marready;
wire [1 : 0] [31:0] mrdata;
wire [1 : 0] [1:0] mrresp;
wire [1 : 0] mrvalid;
wire [1 : 0] mawready;
wire [1 : 0] mwready;
wire [1 : 0] [1:0] mbresp;
wire [1 : 0] mbvalid;

assign {LSU_ARREADY, IFU_ARREADY} = marready;
assign {LSU_RDATA, IFU_RDATA} = mrdata;
assign {LSU_RRESP, IFU_RRESP} = mrresp;
assign {LSU_RVALID, IFU_RVALID} = mrvalid;
assign {LSU_AWREADY, IFU_AWREADY} = mawready;
assign {LSU_WREADY, IFU_WREADY} = mwready;
assign {LSU_BRESP, IFU_BRESP} = mbresp;
assign {LSU_BVALID, IFU_BVALID} = mbvalid;


wire [1 : 0] [31 : 0] maraddr = {LSU_ARADDR, IFU_ARADDR};
wire [1 : 0] marvalid = {LSU_ARVALID, IFU_ARVALID};
wire [1 : 0] mrready = {LSU_RREADY, IFU_RREADY}; 
wire [1 : 0] [31 : 0] mawaddr = {LSU_AWADDR, IFU_AWADDR}; 
wire [1 : 0] mawvalid = {LSU_AWVALID, IFU_AWVALID}; 
wire [1 : 0] [31 : 0] mwdata = {LSU_WDATA, IFU_WDATA}; 
wire [1 : 0] [3 : 0] mwstrb = {LSU_WSTRB, IFU_WSTRB}; 
wire [1 : 0] mwvalid = {LSU_WVALID, IFU_WVALID}; 
wire [1 : 0] mbready = {LSU_BREADY, IFU_BREADY}; 

axi4_lite_arbiter u_axi4_lite_arbiter(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .prerequest 	({lsu_prerequest, ifu_prerequest}),
    .maraddr    	(maraddr     ),
    .marvalid   	(marvalid    ),
    .marready   	(marready    ),
    .mrdata     	(mrdata      ),
    .mrresp     	(mrresp      ),
    .mrvalid    	(mrvalid     ),
    .mrready    	(mrready     ),
    .mawaddr    	(mawaddr     ),
    .mawvalid   	(mawvalid    ),
    .mawready   	(mawready    ),
    .mwdata     	(mwdata      ),
    .mwstrb     	(mwstrb      ),
    .mwvalid    	(mwvalid     ),
    .mwready    	(mwready     ),
    .mbresp     	(mbresp      ),
    .mbvalid    	(mbvalid     ),
    .mbready    	(mbready     ),
    .saraddr    	(saraddr     ),
    .sarvalid   	(sarvalid    ),
    .sarready   	(sarready    ),
    .srdata     	(srdata      ),
    .srresp     	(srresp      ),
    .srvalid    	(srvalid     ),
    .srready    	(srready     ),
    .sawaddr    	(sawaddr     ),
    .sawvalid   	(sawvalid    ),
    .sawready   	(sawready    ),
    .swdata     	(swdata      ),
    .swstrb     	(swstrb      ),
    .swvalid    	(swvalid     ),
    .swready    	(swready     ),
    .sbresp     	(sbresp      ),
    .sbvalid    	(sbvalid     ),
    .sbready    	(sbready     )
);

// output
wire [31:0] saraddr;
wire sarvalid;
wire srready;
wire [31:0] sawaddr;
wire sawvalid;
wire [31:0] swdata;
wire [3:0] swstrb;
wire swvalid;
wire sbready;

// input
wire sarready = SRAM_ARREADY;
wire [31 : 0] srdata = SRAM_RDATA;
wire [1 : 0] srresp = SRAM_RRESP;
wire srvalid = SRAM_RVALID;
wire sawready = SRAM_AWREADY;
wire swready = SRAM_WREADY;
wire [1 : 0] sbresp = SRAM_BRESP;
wire sbvalid = SRAM_BVALID;


// SRAM
// output declaration of module SRAM
wire SRAM_ARREADY;
wire SRAM_RVALID;
wire [31:0] SRAM_RDATA;
wire [1:0] SRAM_RRESP;
wire SRAM_AWREADY;
wire SRAM_WREADY;
wire SRAM_BVALID;
wire [1:0] SRAM_BRESP;

// input declaration of module SRAM
wire SRAM_ARVALID = sarvalid;
wire [31 : 0] SRAM_ARADDR = saraddr;
wire SRAM_RREADY = srready;
wire SRAM_AWVALID = sawvalid;
wire [31 : 0] SRAM_AWADDR = sawaddr;
wire SRAM_WVALID = swvalid;
wire [31 : 0] SRAM_WDATA = swdata;
wire [3 : 0] SRAM_WSTRB = swstrb;
wire SRAM_BREADY = sbready;

SRAM #(
    .R_DELAY_TIME 	(1  ),
    .W_DELAY_TIME 	(1  ))
u_SRAM(
    .clk     	(clk      ),
    .rst     	(rst      ),
    .ARVALID 	(SRAM_ARVALID  ),
    .ARREADY 	(SRAM_ARREADY  ),
    .ARADDR  	(SRAM_ARADDR   ),
    .RVALID  	(SRAM_RVALID   ),
    .RREADY  	(SRAM_RREADY   ),
    .RDATA   	(SRAM_RDATA    ),
    .RRESP   	(SRAM_RRESP    ),
    .AWVALID 	(SRAM_AWVALID  ),
    .AWREADY 	(SRAM_AWREADY  ),
    .AWADDR  	(SRAM_AWADDR   ),
    .WVALID  	(SRAM_WVALID   ),
    .WREADY  	(SRAM_WREADY   ),
    .WDATA   	(SRAM_WDATA    ),
    .WSTRB   	(SRAM_WSTRB    ),
    .BREADY  	(SRAM_BREADY   ),
    .BVALID  	(SRAM_BVALID   ),
    .BRESP   	(SRAM_BRESP    )
);




endmodule
