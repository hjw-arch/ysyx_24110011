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
wire                                s1_ready;
lookup_pkt_t                        s2_data;
logic                               s2_valid;
wire    [ADDR_WIDTH-1:0]            s2_addr;

// S2 hit/miss
wire                                s2_hit;
wire                                s2_miss;
wire                                s2_ready;
wire                                s2_hit_fire;
wire                                s2_miss_fire;
wire                                s2_kill_ready;
wire    [WORD_SEL_WIDTH-1:0]        hit_word_sel;
wire    [WORD_SEL_WIDTH-1:0]        resp_word_sel;
wire    [LINE_WIDTH-1:0]            resp_line;
wire                                hit_resp_valid;
wire                                refill_resp_valid;
wire                                resp_from_refill;

// miss/refill
logic                               miss_kill_r;       // 已进入 refill 的请求被 kill 后，返回时丢弃。
logic                               refill_req_valid;
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

assign  s2_addr             =      {s2_data.tag, s2_data.index, s2_data.offset};
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
    .fill_idx_i        (s2_data.index),
    .fill_tag_i        (s2_data.tag),
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
// S2 是 lookup packet 的唯一解释者。miss 期间，S2 本身就是 outstanding
// miss entry，因此 refill 地址、返回 offset、fill tag/index 都直接从 s2_data 取。
assign s2_hit       = s2_valid & s2_data.entry_valid & (s2_data.entry_tag == s2_data.tag);
assign s2_miss      = s2_valid & ~s2_hit;

assign req_hit      = (state == S_IDLE) & ~kill_any & s2_hit;
assign req_miss     = (state == S_IDLE) & ~kill_any & s2_miss;

// s2_ready 就是 S2 对前一级流水寄存器的 ready：
//   1. hit 响应被 IFU 接收，当前 S2 lookup 生命周期结束；
//   2. miss refill 返回，并被 IFU 接收或因 kill 被丢弃，当前 S2 lookup 生命周期结束；
//   3. S_IDLE 下收到 kill/inval，尚未发出 refill 的 lookup 可以直接清掉。
// miss 只启动 refill，不代表 S2 这条 lookup 已经被消费，因此 miss 当拍不 ready。
assign s2_hit_fire   = req_hit & resp_ready_i;
assign s2_miss_fire  = req_miss;
assign s2_kill_ready = (state == S_IDLE) & s2_valid & kill_any;
assign s2_ready      = s2_hit_fire | refill_resp_fire | s2_kill_ready;

// IFU 侧 req_ready 由 S1/S2 流水寄存器的 pre_ready 给出。
// refill 返回当拍不接新请求：array 写回发生在时钟沿，新请求若同拍锁存会看到旧 array 快照。
assign req_ready_o = (state == S_IDLE) & ~kill_any & s1_ready;

assign hit_word_sel  = s2_data.offset[OFFSET_WIDTH-1:WORD_OFFSET_WIDTH];
assign hit_resp_valid    = req_hit;
assign refill_resp_valid = (state == S_MISS) & refill_resp_valid_i & ~drop_refill;
assign resp_from_refill  = (state == S_MISS);

assign resp_word_sel = hit_word_sel;
assign resp_line     = resp_from_refill ? refill_resp_data_i  : s2_data.entry_data;

assign resp_valid_o  = hit_resp_valid | refill_resp_valid;
assign resp_data_o   = resp_line[{resp_word_sel, {DATA_WIDTH_LOG2{1'b0}}} +: DATA_WIDTH];
assign resp_addr_o   = s2_addr;
assign resp_err_o    = refill_resp_valid & refill_resp_err_i;


/*============================================================
 *  7. S1/S2 Pipeline Register
 *============================================================*/
// 这个寄存器只负责把 S1 的 array 快照送到 S2。
// S2 miss 时保持寄存器内容不变，让它直接作为 outstanding miss entry。
pip_reg #(
    .WIDTH($bits(lookup_pkt_t))
) u_lookup_reg (
    .clk        (clk),
    .rst        (rst),
    .flush      (1'b0),
    .pre_valid  (req_valid_i & (state == S_IDLE) & ~kill_any),
    .pre_data   (s1_pre_data),
    .pre_ready  (s1_ready),
    .next_valid (s2_valid),
    .next_data  (s2_data),
    .next_ready (s2_ready)
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

// kill 有两层语义：
//   1. S_IDLE 下的 lookup kill：尚未发出 refill，直接通过 s2_ready 清掉 S2；
//   2. S_MISS 下的 miss kill：refill 已经在路上，保留 S2 地址信息，等返回时丢弃。
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
assign refill_req_addr_o   = {s2_addr[ADDR_WIDTH-1:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
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
