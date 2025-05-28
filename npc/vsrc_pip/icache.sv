module icache #(
    parameter BLOCK_SIZE    =   16,
    parameter BLOCK_NUM     =   16
) (
    input                       clk,
    input                       rst,
    											// 与IFU (指令取指单元) 数据交互
    input      		[31:0]     	addr_i,   	// CPU发来的指令地址
    input                       valid_i,  	// CPU请求有效信号
	input 						flush,		// 冲刷流水线
	input						ifence,		// fence.i, 需要冲刷icache
    output                      valid_o,  	// Cache返回给CPU的数据是否有效
    output	logic	[31:0]     	data_o,   	// Cache返回给CPU的指令数据
	output 						in_mem,		// 指示当前是否在内存中取指

												// 连接SRAM
    output			[31:0]		ARADDR,
    output						ARVALID,
    output						RREADY,
    output			[3:0] 		ARID,
    output			[7:0] 		ARLEN,
    output			[2:0] 		ARSIZE,
    output			[1:0] 		ARBURST,

    input						ARREADY,
    input						RVALID,
    input						RLAST,
    input			[3:0] 		RID,
    input			[31:0]		RDATA,
    input			[1:0]		RRESP
);



localparam ADDR_WIDTH    =   32;
localparam DATA_WIDTH    =   32;
localparam BLOCK_WIDTH	 =	 BLOCK_SIZE * 8;
localparam INDEX_WIDTH   =   $clog2(BLOCK_NUM);
localparam OFFSET_WIDTH  =   $clog2(BLOCK_SIZE);
localparam TAG_WIDTH     =   ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;


// Cache storage
logic [BLOCK_NUM-1:0] 		cache_valid;
logic [TAG_WIDTH-1:0] 		cache_tag 	[BLOCK_NUM-1:0];
logic [BLOCK_WIDTH-1:0] 	cache_data 	[BLOCK_NUM-1:0];

always_ff @(posedge clk) begin
	if (rst | ifence) begin
		cache_valid <= {BLOCK_NUM{1'b0}};
	end else begin
		if (m2i_done) begin
            cache_data[index_reg] <=  {m2i_data, m2i_data_buffer};
            cache_tag[index_reg] <= tag_reg;
            cache_valid[index_reg] <= 1;
        end
	end
end


logic   [TAG_WIDTH-1:0]     tag, tag_reg;
logic   [INDEX_WIDTH-1:0]   index, index_reg;	/* verilator lint_off UNUSEDSIGNAL */
logic   [OFFSET_WIDTH-1:0]  offset, offset_reg;

always_ff @(posedge clk) begin
	tag_reg <= ~state[0] & ~state[1] & ~hit & ~flush? addr_i[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_WIDTH] : tag_reg;
	index_reg <= ~state[0] & ~state[1] & ~hit & ~flush? addr_i[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH] : index_reg;
	offset_reg <= ~state[0] & ~state[1] & ~hit & ~flush? addr_i[OFFSET_WIDTH - 1 : 0] : offset_reg;
end

assign  index   =   addr_i[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
assign  tag     =   addr_i[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_WIDTH];
assign  offset  =   addr_i[OFFSET_WIDTH - 1 : 0];

/********************** 命中信号 ********************/

logic   hit;
assign  hit     =      ~state[0] & cache_valid[index] & (cache_tag[index] == tag);



/********************** 状态机 ********************/

// localparam	IDLE		=	2'b00,
// 				REQ_MEM		=	2'b01,
// 				WAIT_MEM	=	2'b11;

logic	[1:0]   state,  nstate;
always_ff @(posedge clk) begin
    state <= rst ? 2'b00 : nstate;
end

assign nstate[0]	=	~state[0] & ~state[1] & ~hit & ~flush | state[0] & ~m2i_done;
assign nstate[1]	=	state[0] & ~m2i_done;
assign in_mem		=	state[0];		// 权宜之计

/********************** 与mem通信 ********************/


assign  i2m_valid   =   state[0] & ~state[1];
assign  i2m_addr    =   {tag_reg, index_reg, {OFFSET_WIDTH{1'b0}}};


/************************* 填充 ***********************/


logic [BLOCK_WIDTH - DATA_WIDTH - 1 : 0] m2i_data_buffer;

always_ff @(posedge clk) begin
	m2i_data_buffer <= m2i_valid ? {m2i_data, m2i_data_buffer[BLOCK_WIDTH - DATA_WIDTH - 1 : DATA_WIDTH]} : m2i_data_buffer;	// 其实可以提前一个周期，这里先不这么干
end


/************************* 返回上层数据 *************************/

assign   valid_o    =   valid_i & hit | state[1] & state[0] & m2i_done;


always_comb begin
	case({state[0] ? offset_reg[3:2] : offset[3:2], state[0]})
		3'b001: data_o = m2i_data_buffer[31:0];
		3'b011: data_o = m2i_data_buffer[63:32];
		3'b101: data_o = m2i_data_buffer[95:64];
		3'b111: data_o = m2i_data;
		3'b000: data_o = cache_data[index][31:0];
		3'b010: data_o = cache_data[index][63:32];
		3'b100: data_o = cache_data[index][95:64];
		3'b110: data_o = cache_data[index][127:96];
	endcase
end



/*************************** AXI MASTER ******************************/


logic			i2m_valid;  			// Cache向主存的请求是否有效
logic	[31:0]	i2m_addr;   			// Cache向主存请求的地址 (块地址)
logic	[31:0]	m2i_data;   			// 主存返回给Cache的数据
logic			m2i_valid;  			// 主存返回的数据是否有效
logic			m2i_done;			
logic	[1:0]	m2i_resp;				// resp暂时不用

axi4_full_master u_axi4_full_master(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .wen        	(1'b0        ),
    .ren        	(i2m_valid   ),
    .user_ready 	(1'b1   	 ),
	.size			(2'b10		 ),
    .len        	(8'b11       ),
    .waddr      	(32'b0       ),
    .wdata      	(32'b0       ),
	.rdata_valid	(m2i_valid   ),
    .raddr      	(i2m_addr    ),
    .rdata      	(m2i_data    ),
    .rresp      	(m2i_resp    ),/* verilator lint_off PINCONNECTEMPTY */
    .wresp      	(            ),
    .done       	(m2i_done    ),
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


endmodule
