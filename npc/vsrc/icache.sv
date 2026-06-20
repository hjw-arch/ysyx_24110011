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

typedef struct packed {
    logic [TAG_WIDTH-1:0]       tag;
    logic [INDEX_WIDTH-1:0]     index;
    logic [OFFSET_WIDTH-1:0]    offset;
    logic                       entry_valid;
    logic [TAG_WIDTH-1:0]       entry_tag;
    logic [LINE_WIDTH-1:0]      entry_data;
} lookup_pkt_t;


typedef enum logic {
    S_IDLE,
    S_MISS
} state_t;

state_t state /* verilator public_flat_rd */;
state_t nstate;


/*============================================================
 *  2. 信号声明
 *============================================================*/
// common
wire kill_any;
wire req_hit  /* verilator public_flat_rd */;
wire req_miss /* verilator public_flat_rd */;

// S1 lookup
wire        [TAG_WIDTH-1:0]         req_tag;
wire        [INDEX_WIDTH-1:0]       req_index;
wire        [OFFSET_WIDTH-1:0]      req_offset;

wire                                entry_valid;
wire        [TAG_WIDTH-1:0]         entry_tag;
wire        [LINE_WIDTH-1:0]        entry_data;

lookup_pkt_t                        s1_pre_data;
lookup_pkt_t                        s1_data;
logic                               s1_valid;
wire [ADDR_WIDTH-1:0]               s1_addr;

// S2 hit/miss
wire                                s2_hit;
wire                                s2_miss;
wire                                s2_pop;
wire                                s2_ready_for_s1;
wire                                s2_hit_fire;
wire                                s2_miss_fire;
wire                                s2_kill_fire;
wire    [WORD_SEL_WIDTH-1:0]        hit_word_sel;
wire    [WORD_SEL_WIDTH-1:0]        miss_word_sel;
wire    [WORD_SEL_WIDTH-1:0]        resp_word_sel;
wire    [LINE_WIDTH-1:0]            resp_line;
wire                                hit_resp_valid;
wire                                refill_resp_valid;
wire                                resp_from_refill;

// miss/refill
logic   [ADDR_WIDTH-1:0]            miss_addr_r;
logic                               miss_kill_r;       // 已进入 refill 的请求被 kill 后，返回时丢弃。
logic                               refill_req_valid;
wire    [TAG_WIDTH-1:0]             miss_tag;
wire    [INDEX_WIDTH-1:0]           miss_index;
wire    [OFFSET_WIDTH-1:0]          miss_offset;
wire                                refill_resp_fire;
wire                                drop_refill;
wire                                refill_valid;
wire                                kill_set;


/*============================================================
 *  3. 公共派生信号
 *============================================================*/
assign  kill_any            =      kill_i | inval_i;

assign  req_tag             =      req_addr_i[ADDR_WIDTH-1 -: TAG_WIDTH];
assign  req_index           =      req_addr_i[OFFSET_WIDTH +: INDEX_WIDTH];
assign  req_offset          =      req_addr_i[OFFSET_WIDTH-1:0];

assign  s1_addr             =      {s1_data.tag, s1_data.index, s1_data.offset};
assign  miss_tag            =      miss_addr_r[ADDR_WIDTH-1 -: TAG_WIDTH];
assign  miss_index          =      miss_addr_r[OFFSET_WIDTH +: INDEX_WIDTH];
assign  miss_offset         =      miss_addr_r[OFFSET_WIDTH-1:0];
assign  refill_resp_fire    =      refill_resp_valid_i & refill_resp_ready_o;

// 对这个小 icache，flush 掉的 refill 不写回 cache，避免污染刚被重定向/失效后的取指流。
assign  drop_refill         =       miss_kill_r | kill_any;
assign  refill_valid        =       refill_resp_fire & ~drop_refill;


/*============================================================
 *  4. Cache Array
 *============================================================*/
icache_array #(
    .ADDR_WIDTH        (ADDR_WIDTH),
    .LINE_BYTES        (LINE_BYTES),
    .NUM_LINES         (NUM_LINES)
) u_array (
    .clk               (clk),
    .rst               (rst),
    .lookup_idx_i      (req_index),
    .entry_valid_o     (entry_valid),
    .entry_tag_o       (entry_tag),
    .entry_data_o      (entry_data),
    .fill_valid_i      (refill_valid),
    .fill_idx_i        (miss_index),
    .fill_tag_i        (miss_tag),
    .fill_data_i       (refill_resp_data_i),
    .invalidate_all_i  (inval_i)                 // inval 当拍不接收新请求；在途 lookup 由 kill_any 清掉。
);


/*============================================================
 *  5. S1: Lookup / Array Access
 *============================================================*/
// S1 没有自己的状态：只按 req_addr_i 读 array，并把地址切片和 array 快照组成
// lookup packet。S1 是否真的接收该 packet，由后面的 S1/S2 pipeline reg 决定。
// 这里不做 tag compare，也不理解 miss/refill/kill 的后级策略。
assign s1_pre_data.tag         = req_tag;
assign s1_pre_data.index       = req_index;
assign s1_pre_data.offset      = req_offset;
assign s1_pre_data.entry_valid = entry_valid;
assign s1_pre_data.entry_tag   = entry_tag;
assign s1_pre_data.entry_data  = entry_data;


/*============================================================
 *  6. S2: Hit/Miss / Flow Control / Response
 *============================================================*/
// S2 是 lookup packet 的唯一解释者：tag compare 后要么形成 hit response，
// 要么形成 miss event 交给 refill engine。
assign s2_hit       = s1_valid & s1_data.entry_valid & (s1_data.entry_tag == s1_data.tag);
assign s2_miss      = s1_valid & ~s2_hit;

assign req_hit      = (state == S_IDLE) & ~kill_any & s2_hit;
assign req_miss     = (state == S_IDLE) & ~kill_any & s2_miss;

// 这里刻意区分两种 S2 事件：
//   s2_pop          : S2 当前 lookup 被消费，hit/miss/kill 都算；
//   s2_ready_for_s1 : S2 本拍能接收 S1 的下一条 lookup。
//
// miss 会 pop 掉当前 lookup 并启动 refill，但 blocking cache 在 miss 同拍不接收下一条
// lookup，否则会把 refill 前的旧 array 快照带到 refill 之后，造成同一 cacheline 的重复 miss。
assign s2_hit_fire  = req_hit & resp_ready_i;
assign s2_miss_fire = req_miss;
assign s2_kill_fire = s1_valid & kill_any;
assign s2_pop       = s2_hit_fire | s2_miss_fire | s2_kill_fire;
assign s2_ready_for_s1 = (state == S_IDLE) & (~s1_valid | s2_hit_fire);

// S1 没有 ready 状态，IFU 看到的 ready 只来自 S2 的接收能力和全局 kill。
assign req_ready_o = ~kill_any & s2_ready_for_s1;

assign hit_word_sel  = s1_data.offset[OFFSET_WIDTH-1:WORD_OFFSET_WIDTH];
assign miss_word_sel = miss_offset[OFFSET_WIDTH-1:WORD_OFFSET_WIDTH];
assign hit_resp_valid    = req_hit;
assign refill_resp_valid = (state == S_MISS) & refill_resp_valid_i & ~drop_refill;
assign resp_from_refill  = (state == S_MISS);

assign resp_word_sel = resp_from_refill ? miss_word_sel       : hit_word_sel;
assign resp_line     = resp_from_refill ? refill_resp_data_i  : s1_data.entry_data;

assign resp_valid_o  = hit_resp_valid | refill_resp_valid;
assign resp_data_o   = resp_line[{resp_word_sel, {DATA_WIDTH_LOG2{1'b0}}} +: DATA_WIDTH];
assign resp_addr_o   = resp_from_refill ? miss_addr_r : s1_addr;
assign resp_err_o    = refill_resp_valid & refill_resp_err_i;


/*============================================================
 *  7. S1/S2 Pipeline Register
 *============================================================*/
// 这个寄存器只负责把 S1 的 array 快照送到 S2；是否接收新 lookup 由 S2 段给出的
// req_ready_o 决定，避免在边界寄存器附近重新散落 miss/refill 策略。
pip_reg #(
    .WIDTH($bits(lookup_pkt_t))
) u_lookup_reg (
    .clk        (clk),
    .rst        (rst),
    .flush      (kill_any),
    .pre_valid  (req_valid_i & req_ready_o),
    .pre_data   (s1_pre_data),
    .pre_ready  (),
    .next_valid (s1_valid),
    .next_data  (s1_data),
    .next_ready (s2_pop)
);


/*============================================================
 *  8. Miss / Refill Control
 *============================================================*/
always_comb begin
    unique case (state)
        S_IDLE: nstate = s2_miss_fire     ? S_MISS : S_IDLE;
        S_MISS: nstate = refill_resp_fire ? S_IDLE : S_MISS;
    endcase
end

always_ff @(posedge clk) begin
    state <= rst ? S_IDLE : nstate;
end

always_ff @(posedge clk) begin
    miss_addr_r <= s2_miss_fire ? s1_addr : miss_addr_r;
end

// kill 有两层语义：
//   1. lookup kill：直接清掉 S1；
//   2. miss kill：已经进入 refill 的请求无法取消，记住 miss_kill_r，等返回时丢弃。
assign kill_set = (state == S_MISS) & kill_any & ~refill_resp_fire;

always_ff @(posedge clk) begin
    if (rst) begin
        miss_kill_r <= 1'b0;
    end else begin
        miss_kill_r <= (miss_kill_r | kill_set) & ~refill_resp_fire;
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        refill_req_valid <= 1'b0;
    end else begin
        refill_req_valid <= s2_miss_fire | refill_req_valid & ~refill_req_ready_i;
    end
end

assign refill_req_valid_o  = refill_req_valid;
assign refill_req_addr_o   = {miss_addr_r[ADDR_WIDTH-1:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
assign refill_resp_ready_o = (state == S_MISS) & (drop_refill | resp_ready_i);

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
