// icache.sv
// This file contains a Verilog implementation of an instruction cache (icache)
// without using packages or include directives, all consolidated into a single file
// for compatibility with Yosys.

module icache #(
    parameter BLOCK_SIZE    =   4,
    parameter BLOCK_NUM     =   16,
    parameter ADDR_WIDTH    =   32,
    parameter DATA_WIDTH    =   32
) (
    input                           clk,
    input                           rst,
    // 与IFU (指令取指单元) 数据交互
    input      [ADDR_WIDTH-1:0]     c2i_addr,   // CPU发来的指令地址
    input                           c2i_valid,  // CPU请求有效信号
    output                          i2c_ready,  // Cache是否准备好接收CPU请求
    output                          i2c_valid,  // Cache返回给CPU的数据是否有效
    output     [DATA_WIDTH-1:0]     i2c_data,   // Cache返回给CPU的指令数据
    input                           c2i_ready,  // CPU是否准备好接收Cache数据
    // 与主内存 (Memory) 交互
    output                          i2m_valid,  // Cache向主存的请求是否有效
    output     [ADDR_WIDTH-1:0]     i2m_addr,   // Cache向主存请求的地址 (块地址)
    input                           m2i_ready,  // 主存是否准备好接收Cache请求
    input      [DATA_WIDTH-1:0]     m2i_data,   // 主存返回给Cache的数据
    input                           m2i_valid,  // 主存返回的数据是否有效
    output                          i2m_ready   // Cache是否准备好接收主存数据
);

// Calculated parameters
localparam INDEX_WIDTH   =   $clog2(BLOCK_NUM);
localparam OFFSET_WIDTH  =   $clog2(BLOCK_SIZE);
localparam TAG_WIDTH     =   ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;

// Internal wires
// P1 -> SRAM (读)
wire [INDEX_WIDTH-1:0]  sram_raddr_w;
// SRAM -> P1
wire                    sram_rdata_valid_w;
wire [TAG_WIDTH-1:0]    sram_rdata_tag_w;
wire [DATA_WIDTH-1:0]   sram_rdata_data_w;
// P2 -> SRAM (写)
wire                    sram_wen_w;
wire [INDEX_WIDTH-1:0]  sram_waddr_w;
wire [TAG_WIDTH-1:0]    sram_wtag_w;
wire [DATA_WIDTH-1:0]   sram_wdata_w;
// P1 -> P2
wire [TAG_WIDTH-1:0]    p1_to_p2_tag_w;
wire [INDEX_WIDTH-1:0]  p1_to_p2_index_w;
wire [OFFSET_WIDTH-1:0] p1_to_p2_offset_w;
wire                    p1_to_p2_cache_valid_w;
wire [TAG_WIDTH-1:0]    p1_to_p2_cache_tag_w;
wire [DATA_WIDTH-1:0]   p1_to_p2_cache_data_w;
wire                    p1_to_p2_valid_w;
// P2 -> P1
wire                    p2_to_p1_ready_w;
// P2 -> IFU
wire                    p2_o_valid_w;
wire [DATA_WIDTH-1:0]   p2_o_data_w;

// Module instantiations
icache_sram #(
    .INDEX_WIDTH(INDEX_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .BLOCK_NUM(BLOCK_NUM)
) i_icache_sram (
    .clk        (clk),
    .rst        (rst),
    .wen        (sram_wen_w),
    .waddr      (sram_waddr_w),
    .wtag       (sram_wtag_w),
    .wdata      (sram_wdata_w),
    .raddr      (sram_raddr_w),
    .rdata_valid(sram_rdata_valid_w),
    .rdata_tag  (sram_rdata_tag_w),
    .rdata_data (sram_rdata_data_w)
);

icache_P1 #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .INDEX_WIDTH(INDEX_WIDTH),
    .OFFSET_WIDTH(OFFSET_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) i_icache_P1 (
    .clk        (clk),
    .rst        (rst),
    .sram_raddr (sram_raddr_w),
    .sram_rdata_valid(sram_rdata_valid_w),
    .sram_rdata_tag(sram_rdata_tag_w),
    .sram_rdata_data(sram_rdata_data_w),
    .i_valid    (c2i_valid),
    .i_addr     (c2i_addr),
    .o_ready    (i2c_ready),
    .i_ready    (p2_to_p1_ready_w),
    .o_tag      (p1_to_p2_tag_w),
    .o_index    (p1_to_p2_index_w),
    .o_offset   (p1_to_p2_offset_w),
    .o_cache_valid(p1_to_p2_cache_valid_w),
    .o_cache_tag(p1_to_p2_cache_tag_w),
    .o_cache_data(p1_to_p2_cache_data_w),
    .o_valid    (p1_to_p2_valid_w)
);

icache_P2 #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .INDEX_WIDTH(INDEX_WIDTH),
    .OFFSET_WIDTH(OFFSET_WIDTH),
    .TAG_WIDTH(TAG_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) i_icache_P2 (
    .clk        (clk),
    .rst        (rst),
    .i2m_valid  (i2m_valid),
    .i2m_addr   (i2m_addr),
    .m2i_ready  (m2i_ready),
    .m2i_data   (m2i_data),
    .m2i_valid  (m2i_valid),
    .i2m_ready  (i2m_ready),
    .sram_wen   (sram_wen_w),
    .sram_wtag  (sram_wtag_w),
    .sram_waddr (sram_waddr_w),
    .sram_wdata (sram_wdata_w),
    .i_valid    (p1_to_p2_valid_w),
    .i_tag      (p1_to_p2_tag_w),
    .i_index    (p1_to_p2_index_w),
    .i_offset   (p1_to_p2_offset_w),
    .i_cache_valid(p1_to_p2_cache_valid_w),
    .i_cache_tag(p1_to_p2_cache_tag_w),
    .i_cache_data(p1_to_p2_cache_data_w),
    .o_ready    (p2_to_p1_ready_w),
    .o_data     (p2_o_data_w),
    .o_valid    (p2_o_valid_w)
);

// Handling IFU output handshake
assign i2c_valid = p2_o_valid_w;
assign i2c_data = p2_o_data_w;

always_ff @(posedge clk) begin
	if (c2i_valid) begin
		$display("c2i addr = %x", c2i_addr);
	end

	if (i2c_valid) begin
		$display("addr = %x, data = %x", c2i_addr, i2c_data);
	end
end


endmodule




module icache_sram #(
    parameter INDEX_WIDTH 	= 4,
    parameter TAG_WIDTH 	= 26,
    parameter DATA_WIDTH 	= 32,
    parameter BLOCK_NUM 	= 16
) (
    input                       clk,
    input                       rst,
    input                       wen,
    input   [INDEX_WIDTH-1:0]   waddr,
    input   [TAG_WIDTH-1:0]     wtag,
    input   [DATA_WIDTH-1:0]    wdata,
    input   [INDEX_WIDTH-1:0]   raddr,
    output  logic               rdata_valid,
    output  logic [TAG_WIDTH-1:0] rdata_tag,
    output  logic [DATA_WIDTH-1:0] rdata_data
);

// Cache storage
logic [BLOCK_NUM-1:0] 	cache_valid;
logic [TAG_WIDTH-1:0] 	cache_tag 	[BLOCK_NUM-1:0];
logic [DATA_WIDTH-1:0] 	cache_data 	[BLOCK_NUM-1:0];

// Write operation
always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < BLOCK_NUM; i++) begin
            cache_valid[i] <= 0;
            cache_tag[i] <= 0;
        end
    end else begin
        if (wen) begin
            cache_data[waddr] <=  wdata;
            cache_tag[waddr] <= wtag;
            cache_valid[waddr] <= 1;
        end
    end
end

// Read operation
assign rdata_valid = cache_valid[raddr];
assign rdata_tag = cache_tag[raddr];
assign rdata_data = cache_data[raddr];

endmodule






module icache_P1 #(
    parameter ADDR_WIDTH	=	32,
    parameter INDEX_WIDTH	=	4,
    parameter OFFSET_WIDTH	=	2,
    parameter TAG_WIDTH		=	26,
    parameter DATA_WIDTH	=	32
) (
    input                       		clk,
    input                       		rst,

    output  		[INDEX_WIDTH-1:0]   sram_raddr,
    input                       		sram_rdata_valid,
    input   		[TAG_WIDTH-1:0]     sram_rdata_tag,
    input   		[DATA_WIDTH-1:0]    sram_rdata_data,

    input                       		i_valid,
    input   		[ADDR_WIDTH-1:0]    i_addr,
    output                      		o_ready,

    input                       		i_ready,
    output  logic	[TAG_WIDTH-1:0]     o_tag,
    output  logic	[INDEX_WIDTH-1:0]   o_index,
    output  logic	[OFFSET_WIDTH-1:0]  o_offset,
    output  logic                   	o_cache_valid,
    output  logic	[TAG_WIDTH-1:0]     o_cache_tag,
    output  logic	[DATA_WIDTH-1:0]    o_cache_data,
    output                      		o_valid
);

logic   state, nstate;      // 0: IDLE  1: WAIT_READY
always_ff @(posedge clk) begin
    state <= rst ? 1'b0 : nstate;
end
assign  nstate  =   o_valid & ~i_ready | state & ~i_ready;

// 交互信号
assign  o_ready     =       i_ready;
assign  o_valid     =       i_valid | state;

logic   [TAG_WIDTH-1:0]     tag;
logic   [INDEX_WIDTH-1:0]   index;
logic   [OFFSET_WIDTH-1:0]  offset;
assign  index   =   i_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
assign  tag     =   i_addr[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_WIDTH];
assign  offset  =   i_addr[OFFSET_WIDTH - 1 : 0];

// 与SRAM连接
assign  sram_raddr  =   index;

always_ff @(posedge clk) begin
    if (i_ready & o_valid) begin
        o_cache_valid   <=  sram_rdata_valid;
        o_cache_tag     <=  sram_rdata_tag;
        o_cache_data    <=  sram_rdata_data;
        o_tag           <=  tag;
        o_index         <=  index;
        o_offset        <=  offset;
    end
end

reg [31 : 0] counter;

always_ff @(posedge clk) begin
	if (!rst) counter <= counter + 1;
	if (counter < 100000)
		$display("P1:   cnt = %d, state = %d", counter, state);
end

endmodule




module icache_P2 #(
    parameter ADDR_WIDTH	=	32,
    parameter INDEX_WIDTH	=	4,
    parameter OFFSET_WIDTH	=	2,
    parameter TAG_WIDTH		=	26,
    parameter DATA_WIDTH	=	32
) (
    input                           		clk,
    input                           		rst,
    // 与mem交互
    output                          		i2m_valid,
    output  		[ADDR_WIDTH-1:0]        i2m_addr,
    input                           		m2i_ready,
    input   		[DATA_WIDTH-1:0]        m2i_data,
    input                           		m2i_valid,
    output                          		i2m_ready,
    // 与cache sram交互
    output                          		sram_wen,
    output  		[TAG_WIDTH-1:0]         sram_wtag,
    output  		[INDEX_WIDTH-1:0]       sram_waddr,
    output  		[DATA_WIDTH-1:0]        sram_wdata,
    // 上层流水线
    input                           		i_valid,
    input   		[TAG_WIDTH-1:0]         i_tag,
    input   		[INDEX_WIDTH-1:0]       i_index,
    input   		[OFFSET_WIDTH-1:0]      i_offset,
    input                           		i_cache_valid,
    input   		[TAG_WIDTH-1:0]         i_cache_tag,
    input   		[DATA_WIDTH-1:0]        i_cache_data,
    output                          		o_ready,
    // 返回顶层模块(给CPU)
    output  logic	[DATA_WIDTH-1:0]        o_data,
    output  logic                        	o_valid
);

/********************** 握手信号 ********************/

assign  o_ready =       ~nstate;        // 只要下个周期还是idle，就应该能够接收新数据
logic   has_new_data;
always_ff @(posedge clk) begin
    has_new_data <= rst ? 1'b0 : (i_valid & o_ready);
end


/********************** 命中信号 ********************/
logic   hit;
assign  hit     =      i_cache_valid & (i_cache_tag == i_tag);


/********************** 状态机 ********************/
logic   state,  nstate;
always_ff @(posedge clk) begin
    state <= rst ? 1'b0 : nstate;
end

assign  nstate  =   has_new_data & ~hit | state & ~m2i_valid;


/********************** 与mem通信 ********************/
assign  i2m_valid   =   has_new_data & ~hit;
assign  i2m_addr    =   {i_tag, i_index, {OFFSET_WIDTH{1'b0}}};
assign  i2m_ready   =   1'b1;


/************************* 填充 ***********************/
assign  sram_wen    =   state & m2i_valid;
assign  sram_waddr  =   i_index;
assign  sram_wdata  =   m2i_data;
assign  sram_wtag   =   i_tag;


/************************* 返回上层数据 *************************/
assign  o_valid     =   has_new_data & hit | state & m2i_valid;
assign  o_data      =   state ? m2i_data : i_cache_data;


reg [31 : 0] counter;

always_ff @(posedge clk) begin
	if (!rst) counter <= counter + 1;
	if (counter < 100000)
		$display("P2:   cnt = %d, state = %d, next_state = %d, new_data = %d", counter, state, nstate, has_new_data);
end

endmodule

