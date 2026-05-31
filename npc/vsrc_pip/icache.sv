// error暂不实现
module icache #(
    parameter   ADDR_WIDTH          =   32,
    parameter   LINE_BYTES          =   16,
    parameter   NUM_LINES           =   16,

    localparam  DATA_WIDTH          =   32,
    localparam  DATA_WIDTH_LOG2     =   $clog2(DATA_WIDTH),
    localparam  WORD_OFFSET_WIDTH   =   $clog2(DATA_WIDTH / 8),
    localparam  LINE_WIDTH          =   LINE_BYTES * 8,
    localparam  WORD_SEL_WIDTH      =   $clog2(LINE_WIDTH / DATA_WIDTH),
    localparam  INDEX_WIDTH         =   $clog2(NUM_LINES),
    localparam  OFFSET_WIDTH        =   $clog2(LINE_BYTES),
    localparam  TAG_WIDTH           =   ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH
)(
    input                       clk,
    input                       rst,

    // ifu    <---->    icache
    input                       req_valid_i,
    input   [ADDR_WIDTH-1:0]    req_addr_i,
    output                      req_ready_o,

    output                      resp_valid_o,
    output  [DATA_WIDTH-1:0]    resp_data_o,
    output  [ADDR_WIDTH-1:0]    resp_addr_o,
    output                      resp_err_o,
    input                       resp_ready_i,

    input                       kill_i,
    input                       inval_i,

    // icache    <---->    axi
    output                      refill_req_valid_o,
    output  [ADDR_WIDTH-1:0]    refill_req_addr_o,
    input                       refill_req_ready_i,

    input                       refill_resp_valid_i,
    input   [LINE_WIDTH-1:0]    refill_resp_data_i,
    input                       refill_resp_err_i,
    output                      refill_resp_ready_o
);

/*============================================================
 *  1. 类型定义 & 状态声明
 *============================================================*/
typedef enum logic { 
    S_IDLE,
    S_MISS
} state_t;

state_t state, nstate;


/*============================================================
 *  2. 内部寄存器声明
 *============================================================*/
logic [TAG_WIDTH-1:0]       miss_tag_r;
logic [INDEX_WIDTH-1:0]     miss_index_r;
logic [OFFSET_WIDTH-1:0]    miss_offset_r;
logic [ADDR_WIDTH-1:0]      miss_addr_r;
logic                       miss_kill_r;            // 用于杀掉在途请求的写回


/*============================================================
 *  3. 地址解析
 *============================================================*/
wire [TAG_WIDTH-1:0]    tag     = req_addr_i[ADDR_WIDTH-1 -: TAG_WIDTH];
wire [INDEX_WIDTH-1:0]  index   = req_addr_i[OFFSET_WIDTH +: INDEX_WIDTH];
wire [OFFSET_WIDTH-1:0] offset  = req_addr_i[OFFSET_WIDTH-1:0];


/*============================================================
 *  4. Cache Array
 *============================================================*/
wire                    entry_valid;
wire [TAG_WIDTH-1:0]    entry_tag;
wire [LINE_WIDTH-1:0]   entry_data;

wire    kill_any    =   kill_i | inval_i;
wire    refill_resp_fire = refill_resp_valid_i & refill_resp_ready_o;
wire    drop_refill = miss_kill_r | kill_any;                     // 这里的关键权衡：对于我们这种小icache，flush掉的内容不写回cache可能更好
wire    refill_valid = refill_resp_fire & ~drop_refill;

icache_array #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .LINE_BYTES (LINE_BYTES),
    .NUM_LINES  (NUM_LINES)
) u_array (
    .clk                (clk),
    .rst                (rst),
    .lookup_idx_i       (index),
    .entry_valid_o      (entry_valid),
    .entry_tag_o        (entry_tag),
    .entry_data_o       (entry_data),
    .fill_valid_i       (refill_valid),
    .fill_idx_i         (miss_index_r),
    .fill_tag_i         (miss_tag_r),
    .fill_data_i        (refill_resp_data_i),
    .invalidate_all_i   (inval_i)                   // inval的时候，不会发生同时读写，先读后inval，而且inval的时候不会有读请求
);


/*============================================================
 *  5. Hit/Miss 判断
 *============================================================*/
wire array_hit = entry_valid & (entry_tag == tag);
wire can_accept_req = (state == S_IDLE) & ~kill_any;

/*============================================================
 *  6. 握手信号
 *============================================================*/
wire req_hit          = req_valid_i & can_accept_req & array_hit & resp_ready_i;
wire req_miss         = req_valid_i & can_accept_req & ~array_hit;

/*============================================================
 *  7. FSM
 *============================================================*/
always_comb begin
    unique case (state)
        S_IDLE: nstate = req_miss           ? S_MISS : S_IDLE;      // req_miss 已经过 can_accept_req 过滤，flush 当拍不会接受新请求
        S_MISS: nstate = refill_resp_fire   ? S_IDLE : S_MISS;
    endcase
end

always_ff @(posedge clk) 
    state <= rst ? S_IDLE : nstate;


/*============================================================
 *  8. Miss 信息锁存
 *============================================================*/
always_ff @(posedge clk) begin
    miss_tag_r    <= req_miss ? tag             :   miss_tag_r;
    miss_index_r  <= req_miss ? index           :   miss_index_r;
    miss_offset_r <= req_miss ? offset          :   miss_offset_r;
    miss_addr_r   <= req_miss ? req_addr_i      :   miss_addr_r;
end

// 本拍发生flush，但本拍还没有消费掉 refill response，才需要记住 kill
wire kill_set = (state == S_MISS) & kill_any & ~refill_resp_fire;

always_ff @(posedge clk) begin
    if (rst) 
        miss_kill_r <= 1'b0;
    else
        miss_kill_r <= (miss_kill_r | kill_set) & ~refill_resp_fire;
end


/*============================================================
 *  9. Refill 接口
 *============================================================*/
logic refill_req_valid;

always_ff @(posedge clk) begin
    if (rst) begin
        refill_req_valid <= 1'b0;
    end else begin
        refill_req_valid <= req_miss | refill_req_valid & ~refill_req_ready_i;
    end
end

assign refill_req_valid_o  = refill_req_valid;
assign refill_req_addr_o   = {miss_tag_r, miss_index_r, {OFFSET_WIDTH{1'b0}}};
assign refill_resp_ready_o = (state == S_MISS) & (drop_refill | resp_ready_i);


/*============================================================
 *  10. Word 选择 MUX
 *============================================================*/
wire [WORD_SEL_WIDTH-1 : 0] word_sel = (state == S_IDLE) ? offset[OFFSET_WIDTH-1 : WORD_OFFSET_WIDTH] : 
                                                           miss_offset_r[OFFSET_WIDTH-1 : WORD_OFFSET_WIDTH];

wire [LINE_WIDTH-1:0] sel_line = (state == S_IDLE) ? entry_data : refill_resp_data_i;


/*============================================================
 *  11. IFU 侧输出
 *============================================================*/
assign req_ready_o  = can_accept_req & (resp_ready_i | ~array_hit);                // 这里考虑去掉~hit，不知道这里的时序如何，很可能造成巨大的时序压力.这里使用resp_ready_i反压，只是权宜之计
assign resp_valid_o = (state == S_IDLE) ? req_hit : refill_resp_valid_i & ~drop_refill;
assign resp_data_o  = sel_line[{word_sel, {DATA_WIDTH_LOG2{1'b0}}} +: DATA_WIDTH];
assign resp_addr_o  = (state == S_IDLE) ? req_addr_i  : miss_addr_r;
assign resp_err_o   = refill_resp_err_i;

endmodule



module icache_array #(
    parameter   ADDR_WIDTH      =   32,
    parameter   LINE_BYTES      =   16,
    parameter   NUM_LINES       =   16,

    localparam  LINE_WIDTH      =   LINE_BYTES * 8,
    localparam  INDEX_WIDTH     =   $clog2(NUM_LINES),
    localparam  OFFSET_WIDTH    =   $clog2(LINE_BYTES),
    localparam  TAG_WIDTH       =   ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH
)(
    input                       clk,
    input                       rst,

    input   [INDEX_WIDTH-1:0]   lookup_idx_i,
    output                      entry_valid_o,
    output  [TAG_WIDTH-1:0]     entry_tag_o,
    output  [LINE_WIDTH-1:0]    entry_data_o,

    input                       fill_valid_i,
    input   [INDEX_WIDTH-1:0]   fill_idx_i,
    input   [TAG_WIDTH-1:0]     fill_tag_i,
    input   [LINE_WIDTH-1:0]    fill_data_i,

    input                       invalidate_all_i
);

// 定义存储体
logic   [NUM_LINES-1:0]     cache_line_valid;
logic   [TAG_WIDTH-1:0]     cache_line_tag      [NUM_LINES-1:0];
logic   [LINE_WIDTH-1:0]    cache_line_data     [NUM_LINES-1:0];

// read
assign  entry_valid_o  =   cache_line_valid[lookup_idx_i];
assign  entry_tag_o    =   cache_line_tag[lookup_idx_i];
assign  entry_data_o   =   cache_line_data[lookup_idx_i];


// write
always_ff @(posedge clk) begin
    if (rst | invalidate_all_i) begin
        cache_line_valid <= {NUM_LINES{1'b0}};
    end else begin
        cache_line_valid[fill_idx_i] <= fill_valid_i ? 1'b1 : cache_line_valid[fill_idx_i];
    end
end

always_ff @(posedge clk) begin
    cache_line_tag[fill_idx_i]  <= fill_valid_i ? fill_tag_i    : cache_line_tag[fill_idx_i];
    cache_line_data[fill_idx_i] <= fill_valid_i ? fill_data_i   : cache_line_data[fill_idx_i];
end

endmodule


// axi_read_adapter 是一个很薄的adapter，不保存请求以节省ysyx要求的面积，这里的请求由icache自己保存
// 但可能存在时序问题，如果后期发现存在时序问题则需要加一拍skid来保证时序
module axi_read_adapter #(
	parameter ADDR_WIDTH  = 32,
	parameter LINE_WIDTH  = 128,
	parameter BUS_WIDTH   = 32
)(
	input  logic clk,
	input  logic rst,

	// ======== 上游接口（cacheline 粒度）========
	input  logic                    req_valid_i,
	input  logic [ADDR_WIDTH-1:0]   req_addr_i,
	output logic                    req_ready_o,

	output logic                    resp_valid_o,
	output logic [LINE_WIDTH-1:0]   resp_data_o,
	output logic                    resp_err_o,
	input  logic                    resp_ready_i,

	// ======== AXI4 读通道 ========
	output logic [ADDR_WIDTH-1:0]   ARADDR,
	output logic                    ARVALID,
	output logic [7:0]              ARLEN,
	output logic [2:0]              ARSIZE,
	output logic [1:0]              ARBURST,
	output logic [3:0]              ARID,
	input  logic                    ARREADY,

	input  logic [BUS_WIDTH-1:0]    RDATA,
	input  logic                    RVALID,
	input  logic                    RLAST,
	input  logic [1:0]              RRESP,
	input  logic [3:0]              RID,
	output logic                    RREADY
);

	// ──────────── 参数与类型 ────────────
	localparam BEATS        =   LINE_WIDTH / BUS_WIDTH;
    localparam BURST_LEN    =   BEATS - 1;                      // ARLEN
    localparam BEAT_SIZE    =   $clog2(BUS_WIDTH / 8);          // ARSIZE

	typedef enum logic [1:0] {
		S_IDLE,
		S_REFILL,
		S_DONE
	} state_t;

	state_t state, nstate;

	// ──────────── 状态寄存器 ────────────
	always_ff @(posedge clk)
		state <= rst ? S_IDLE : nstate;

	// ──────────── 次态逻辑 ────────────
	wire ar_fire   = ARVALID & ARREADY;
	wire beat_fire = RVALID  & RREADY;
	wire resp_fire = resp_valid_o & resp_ready_i;

	always_comb begin
		unique case (state)
			S_IDLE:   nstate = ar_fire              ? S_REFILL : S_IDLE;
			S_REFILL: nstate = (beat_fire & RLAST)  ? S_DONE   : S_REFILL;
			S_DONE:   nstate = resp_fire            ? S_IDLE   : S_DONE;
			default:  nstate = S_IDLE;
		endcase
	end

	// ──────────── 数据通路：128-bit 三合一 buffer ────────────
	// 功能：beat 拼接 / fill buffer / 反压保持
	logic [LINE_WIDTH-1:0] shift_reg;

	always_ff @(posedge clk)
		shift_reg <= beat_fire ? {RDATA, shift_reg[LINE_WIDTH-1:BUS_WIDTH]} : shift_reg;

	// ──────────── 错误累积 ────────────
    // 暂时不用
	// logic err_r;

	// always_ff @(posedge clk) begin
	// 	if (rst | resp_fire)
	// 		err_r <= 1'b0;
	// 	else if (beat_fire & (RRESP != 2'b00))
	// 		err_r <= 1'b1;
	// end

	// ──────────── AXI AR 通道（固定参数）────────────
	assign ARVALID = (state == S_IDLE) & req_valid_i;
	assign ARADDR  = req_addr_i;
	assign ARLEN   = BURST_LEN[7:0];
	assign ARSIZE  = BEAT_SIZE[2:0];
	assign ARBURST = 2'b01;     // INCR
	assign ARID    = 4'b0;

	// ──────────── AXI R 通道 ────────────
	assign RREADY  = (state == S_REFILL);

	// ──────────── 上游接口 ────────────
	assign req_ready_o  = (state == S_IDLE) & ARREADY;      // 这里存在不确定性的时序压力，如果确实发现存在时序压力，需要让adapter自己存储请求
	assign resp_valid_o = (state == S_DONE);
	assign resp_data_o  = shift_reg;
	assign resp_err_o   = 1'b0;

endmodule











// // 旧版

// module icache #(
//     parameter BLOCK_SIZE    =   16,
//     parameter BLOCK_NUM     =   16
// ) (
//     input                       clk,
//     input                       rst,
//     										// 与IFU (指令取指单元) 数据交互
//     input      		[31:0]     	addr_i,   	// CPU发来的指令地址
//     input                       valid_i,  	// CPU请求有效信号
// 	input 						flush,		// 冲刷流水线
// 	input						ifence,		// fence.i, 需要冲刷icache
//     output                      valid_o,  	// Cache返回给CPU的数据是否有效
//     output	logic	[31:0]     	data_o,   	// Cache返回给CPU的指令数据
// 	output 						in_mem,		// 指示当前是否在内存中取指

// 												// 连接SRAM
//     output			[31:0]		ARADDR,
//     output						ARVALID,
//     output						RREADY,
//     output			[3:0] 		ARID,
//     output			[7:0] 		ARLEN,
//     output			[2:0] 		ARSIZE,
//     output			[1:0] 		ARBURST,

//     input						ARREADY,
//     input						RVALID,
//     input						RLAST,
//     input			[3:0] 		RID,
//     input			[31:0]		RDATA,
//     input			[1:0]		RRESP
// );



// localparam ADDR_WIDTH    =   32;
// localparam DATA_WIDTH    =   32;
// localparam BLOCK_WIDTH	 =	 BLOCK_SIZE * 8;
// localparam INDEX_WIDTH   =   $clog2(BLOCK_NUM);
// localparam OFFSET_WIDTH  =   $clog2(BLOCK_SIZE);
// localparam TAG_WIDTH     =   ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;


// // Cache storage
// logic [BLOCK_NUM-1:0] 		cache_valid;
// logic [TAG_WIDTH-1:0] 		cache_tag 	[BLOCK_NUM-1:0];
// logic [BLOCK_WIDTH-1:0] 	cache_data 	[BLOCK_NUM-1:0];

// always_ff @(posedge clk) begin
// 	if (rst | ifence) begin
// 		cache_valid <= {BLOCK_NUM{1'b0}};
// 	end else begin
// 		if (m2i_done) begin
//             cache_data[index_reg] <=  {m2i_data, m2i_data_buffer};
//             cache_tag[index_reg] <= tag_reg;
//             cache_valid[index_reg] <= 1;
//         end
// 	end
// end


// logic   [TAG_WIDTH-1:0]     tag, tag_reg;
// logic   [INDEX_WIDTH-1:0]   index, index_reg;	/* verilator lint_off UNUSEDSIGNAL */
// logic   [OFFSET_WIDTH-1:0]  offset, offset_reg;

// always_ff @(posedge clk) begin
// 	tag_reg <= ~state[0] & ~state[1] & ~hit & ~flush? addr_i[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_WIDTH] : tag_reg;
// 	index_reg <= ~state[0] & ~state[1] & ~hit & ~flush? addr_i[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH] : index_reg;
// 	offset_reg <= ~state[0] & ~state[1] & ~hit & ~flush? addr_i[OFFSET_WIDTH - 1 : 0] : offset_reg;
// end

// assign  index   =   addr_i[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
// assign  tag     =   addr_i[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_WIDTH];
// assign  offset  =   addr_i[OFFSET_WIDTH - 1 : 0];

// /********************** 命中信号 ********************/

// logic   hit;
// assign  hit     =      ~state[0] & cache_valid[index] & (cache_tag[index] == tag);



// /********************** 状态机 ********************/

// // localparam	IDLE		=	2'b00,
// // 				REQ_MEM		=	2'b01,
// // 				WAIT_MEM	=	2'b11;

// logic	[1:0]   state,  nstate;
// always_ff @(posedge clk) begin
//     state <= rst ? 2'b00 : nstate;
// end

// assign nstate[0]	=	~state[0] & ~state[1] & ~hit & ~flush | state[0] & ~m2i_done;
// assign nstate[1]	=	state[0] & ~m2i_done;
// assign in_mem		=	state[0];		// 权宜之计

// /********************** 与mem通信 ********************/


// assign  i2m_valid   =   state[0] & ~state[1];
// assign  i2m_addr    =   {tag_reg, index_reg, {OFFSET_WIDTH{1'b0}}};


// /************************* 填充 ***********************/


// logic [BLOCK_WIDTH - DATA_WIDTH - 1 : 0] m2i_data_buffer;

// always_ff @(posedge clk) begin
// 	m2i_data_buffer <= m2i_valid ? {m2i_data, m2i_data_buffer[BLOCK_WIDTH - DATA_WIDTH - 1 : DATA_WIDTH]} : m2i_data_buffer;	// 其实可以提前一个周期，这里先不这么干
// end


// /************************* 返回上层数据 *************************/

// assign   valid_o    =   valid_i & hit | state[1] & state[0] & m2i_done;


// always_comb begin
// 	case({state[0] ? offset_reg[3:2] : offset[3:2], state[0]})
// 		3'b001: data_o = m2i_data_buffer[31:0];
// 		3'b011: data_o = m2i_data_buffer[63:32];
// 		3'b101: data_o = m2i_data_buffer[95:64];
// 		3'b111: data_o = m2i_data;
// 		3'b000: data_o = cache_data[index][31:0];
// 		3'b010: data_o = cache_data[index][63:32];
// 		3'b100: data_o = cache_data[index][95:64];
// 		3'b110: data_o = cache_data[index][127:96];
// 	endcase
// end



// /*************************** AXI MASTER ******************************/


// logic			i2m_valid;  			// Cache向主存的请求是否有效
// logic	[31:0]	i2m_addr;   			// Cache向主存请求的地址 (块地址)
// logic	[31:0]	m2i_data;   			// 主存返回给Cache的数据
// logic			m2i_valid;  			// 主存返回的数据是否有效
// logic			m2i_done;			
// logic	[1:0]	m2i_resp;				// resp暂时不用

// axi4_full_master u_axi4_full_master(
//     .clk        	(clk         ),
//     .rst        	(rst         ),
//     .wen        	(1'b0        ),
//     .ren        	(i2m_valid   ),
//     .user_ready 	(1'b1   	 ),
// 	.size			(2'b10		 ),
//     .len        	(8'b11       ),
//     .waddr      	(32'b0       ),
//     .wdata      	(32'b0       ),
// 	.rdata_valid	(m2i_valid   ),
//     .raddr      	(i2m_addr    ),
//     .rdata      	(m2i_data    ),
//     .rresp      	(m2i_resp    ),/* verilator lint_off PINCONNECTEMPTY */
//     .wresp      	(            ),
//     .done       	(m2i_done    ),
//     .ARREADY    	(ARREADY     ),
//     .ARVALID    	(ARVALID     ),
//     .ARADDR     	(ARADDR      ),
//     .ARID       	(ARID        ),
//     .ARLEN      	(ARLEN       ),
//     .ARSIZE     	(ARSIZE      ),
//     .ARBURST    	(ARBURST     ),
//     .RREADY     	(RREADY      ),
//     .RVALID     	(RVALID      ),
//     .RDATA      	(RDATA       ),
//     .RLAST      	(RLAST       ),
//     .RID        	(RID         ),
//     .RRESP      	(RRESP       )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWADDR     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWVALID    	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWID       	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWLEN      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWSIZE     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWBURST    	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWREADY    	(1'b0        ),
//     .WDATA      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WSTRB      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WLAST      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WVALID     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WREADY     	(1'b0        ),
//     .BRESP      	(2'b00       ),
//     .BVALID     	(1'b0        ),
//     .BID        	(4'b0        ),
//     .BREADY     	(            )/* verilator lint_off PINCONNECTEMPTY */
// );


// endmodule
