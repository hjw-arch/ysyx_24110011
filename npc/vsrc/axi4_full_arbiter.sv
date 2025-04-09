module axi4_full_arbiter (
    input clk,
    input rst,

    input m0_prerequest,                // Master 0预请求信号
    input m1_prerequest,                // Master 1预请求信号

    // MASTER 0 Signals
    // READ ADDRESS CHANNEL
    input  logic [3:0]  m0_arid,     // 新增ID
    input  logic [31:0] m0_araddr,
    input  logic [7:0]  m0_arlen,    // 新增突发长度
    input  logic [2:0]  m0_arsize,   // 新增传输大小
    input  logic [1:0]  m0_arburst,  // 新增突发类型
    input  logic        m0_arvalid,
    output logic        m0_arready,

    // READ DATA CHANNEL
    output logic [3:0]  m0_rid,      // 新增RID
    output logic [31:0] m0_rdata,
    output logic [1:0]  m0_rresp,
    output logic        m0_rlast,    // 新增RLAST
    output logic        m0_rvalid,
    input  logic        m0_rready,

    // WRITE ADDRESS CHANNEL
    input  logic [3:0]  m0_awid,     // 新增AWID
    input  logic [31:0] m0_awaddr,
    input  logic [7:0]  m0_awlen,    // 新增AWLEN
    input  logic [2:0]  m0_awsize,   // 新增AWSIZE
    input  logic [1:0]  m0_awburst,  // 新增AWBURST
    input  logic        m0_awvalid,
    output logic        m0_awready,

    // WRITE DATA CHANNEL
    input  logic [31:0] m0_wdata,
    input  logic [3:0]  m0_wstrb,
    input  logic        m0_wlast,    // 新增WLAST
    input  logic        m0_wvalid,
    output logic        m0_wready,

    // BRESP CHANNEL
    output logic [3:0]  m0_bid,      // 新增BID
    output logic [1:0]  m0_bresp,
    output logic        m0_bvalid,
    input  logic        m0_bready,

    // MASTER 1 Signals
    // READ ADDRESS CHANNEL
    input  logic [3:0]  m1_arid,
    input  logic [31:0] m1_araddr,
    input  logic [7:0]  m1_arlen,
    input  logic [2:0]  m1_arsize,
    input  logic [1:0]  m1_arburst,
    input  logic        m1_arvalid,
    output logic        m1_arready,

    // READ DATA CHANNEL
    output logic [3:0]  m1_rid,
    output logic [31:0] m1_rdata,
    output logic [1:0]  m1_rresp,
    output logic        m1_rlast,
    output logic        m1_rvalid,
    input  logic        m1_rready,

    // WRITE ADDRESS CHANNEL
    input  logic [3:0]  m1_awid,
    input  logic [31:0] m1_awaddr,
    input  logic [7:0]  m1_awlen,
    input  logic [2:0]  m1_awsize,
    input  logic [1:0]  m1_awburst,
    input  logic        m1_awvalid,
    output logic        m1_awready,

    // WRITE DATA CHANNEL
    input  logic [31:0] m1_wdata,
    input  logic [3:0]  m1_wstrb,
    input  logic        m1_wlast,
    input  logic        m1_wvalid,
    output logic        m1_wready,

    // BRESP CHANNEL
    output logic [3:0]  m1_bid,
    output logic [1:0]  m1_bresp,
    output logic        m1_bvalid,
    input  logic        m1_bready,

    // SLAVE Signals
    // READ ADDRESS CHANNEL
    output logic [3:0]  s_arid,
    output logic [31:0] s_araddr,
    output logic [7:0]  s_arlen,
    output logic [2:0]  s_arsize,
    output logic [1:0]  s_arburst,
    output logic        s_arvalid,
    input  logic        s_arready,

    // READ DATA CHANNEL
    input  logic [3:0]  s_rid,
    input  logic [31:0] s_rdata,
    input  logic [1:0]  s_rresp,
    input  logic        s_rlast,
    input  logic        s_rvalid,
    output logic        s_rready,

    // WRITE ADDRESS CHANNEL
    output logic [3:0]  s_awid,
    output logic [31:0] s_awaddr,
    output logic [7:0]  s_awlen,
    output logic [2:0]  s_awsize,
    output logic [1:0]  s_awburst,
    output logic        s_awvalid,
    input  logic        s_awready,

    // WRITE DATA CHANNEL
    output logic [31:0] s_wdata,
    output logic [3:0]  s_wstrb,
    output logic        s_wlast,
    output logic        s_wvalid,
    input  logic        s_wready,

    // BRESP CHANNEL
    input  logic [3:0]  s_bid,
    input  logic [1:0]  s_bresp,
    input  logic        s_bvalid,
    output logic        s_bready
);

logic [1:0] request;
assign request[0] = m0_arvalid | m0_awvalid | m0_wvalid | m0_prerequest;
assign request[1] = m1_arvalid | m1_awvalid | m1_wvalid | m1_prerequest;

// 完成判断逻辑
logic [1:0] will_done;
assign will_done[0] = (s_rvalid & m0_rready & s_rlast) | (s_bvalid & m0_bready);
assign will_done[1] = (s_rvalid & m1_rready & s_rlast) | (s_bvalid & m1_bready);

// 状态机定义
typedef enum logic [2:0] { 
    IDLE      = 3'b001,
    M0_ACTIVE = 3'b010,
    M1_ACTIVE = 3'b100
} state_t;

state_t state, next_state;

always_ff @(posedge clk) begin
    state <= rst ? IDLE : next_state;
end

// 轮询机制
always_comb begin
    case(state)
        IDLE:
            case(request)
                2'b11, 2'b01: next_state = M0_ACTIVE;
                2'b10: next_state = M1_ACTIVE;
                default: next_state = state;
            endcase
        M0_ACTIVE:
            if(will_done[0]) begin
                case(request)
                    2'b11, 2'b10: next_state = M1_ACTIVE;
                    2'b01: next_state = M0_ACTIVE;
                    default: next_state = IDLE;
                endcase
            end else begin
                next_state = state;
            end
        M1_ACTIVE:
            if(will_done[1]) begin
                case(request)
                    2'b11, 2'b01: next_state = M0_ACTIVE;
                    2'b10: next_state = M1_ACTIVE;
                    default: next_state = IDLE;
                endcase
            end else begin
                next_state = state;
            end
        default:
            next_state = state;
    endcase
end

// to master
// 可以直接给到master的信号，无需转发
assign m0_rvalid = s_rvalid;    // 读通道
assign m0_rid    = s_rid;
assign m0_rlast  = s_rlast;
assign m0_rdata  = s_rdata;
assign m0_rresp  = s_rresp;
assign m0_bvalid = s_bvalid;    // 写通道
assign m0_bresp  = s_bresp;
assign m0_bid    = s_bid;

assign m1_rdata  = s_rdata;     // 读通道
assign m1_rid    = s_rid;
assign m1_rlast  = s_rlast;
assign m1_rresp  = s_rresp;
assign m1_rvalid = s_rvalid;
assign m1_bvalid = s_bvalid;    // 写通道
assign m1_bresp  = s_bresp;
assign m1_bid    = s_bid;

// 对读写请求的响应信号，不能直连，需要仲裁
assign m0_arready = (state == M0_ACTIVE) ? s_arready : 1'b0;
assign m0_awready = (state == M0_ACTIVE) ? s_awready : 1'b0;
assign m0_wready  = (state == M0_ACTIVE) ? s_wready  : 1'b0;

assign m1_arready = (state == M1_ACTIVE) ? s_arready : 1'b0;
assign m1_awready = (state == M1_ACTIVE) ? s_awready : 1'b0;
assign m1_wready  = (state == M1_ACTIVE) ? s_wready  : 1'b0;



// to slave
// valid信号生成
// 要注意时序，对于握手信号，只有仲裁选择之后才能接通，当然，如果能够提前一个周期转换状态，也可以像下面那些信号一样默认一个
assign s_arvalid = (state == M1_ACTIVE) & m1_arvalid | (state == M0_ACTIVE) & m0_arvalid;
assign s_awvalid = (state == M1_ACTIVE) & m1_awvalid |  (state == M0_ACTIVE) & m0_awvalid;
assign s_wvalid = (state == M1_ACTIVE) & m1_wvalid | (state == M0_ACTIVE) & m0_wvalid;

// ready信号生成
assign s_rready = (state == M1_ACTIVE) ? m1_rready : m0_rready;
assign s_bready = (state == M1_ACTIVE) ? m1_bready : m0_bready;

// 默认m0，可以减少面积和延迟
// 读地址通道
assign s_arid    = (state == M1_ACTIVE) ? m1_arid    : m0_arid;
assign s_araddr  = (state == M1_ACTIVE) ? m1_araddr  : m0_araddr;
assign s_arlen   = (state == M1_ACTIVE) ? m1_arlen   : m0_arlen;
assign s_arsize  = (state == M1_ACTIVE) ? m1_arsize  : m0_arsize;
assign s_arburst = (state == M1_ACTIVE) ? m1_arburst : m0_arburst;

// 写地址通道
assign s_awid    = (state == M1_ACTIVE) ? m1_awid    : m0_awid;
assign s_awaddr  = (state == M1_ACTIVE) ? m1_awaddr  : m0_awaddr;
assign s_awlen   = (state == M1_ACTIVE) ? m1_awlen   : m0_awlen;
assign s_awsize  = (state == M1_ACTIVE) ? m1_awsize  : m0_awsize;
assign s_awburst = (state == M1_ACTIVE) ? m1_awburst : m0_awburst;

// 写数据通道路由
assign s_wdata  = (state == M1_ACTIVE) ? m1_wdata  : m0_wdata;
assign s_wstrb  = (state == M1_ACTIVE) ? m1_wstrb  : m0_wstrb;
assign s_wlast  = (state == M1_ACTIVE) ? m1_wlast  : m0_wlast;


always_ff @(posedge clk) begin
	if(state == M1_ACTIVE) begin
		$display("AR Channel: ARADDR = 0x%08x\nARLEN = %d\nARSIZE = %d\nARVALID = %d\nARREADY = %d\n", s_araddr, s_arlen, s_arsize, s_arvalid, s_arready);
		$display("R Channel: RDATA = 0x%08x\nRRESP = %d\nRLAST = %d\nRVALID = %d\nRREADY = %d\n", s_rdata, s_rresp, s_rlast, s_rvalid, s_rready);
		$display("AW Channel: AWADDR = 0x%08x\nAWLEN = %d\nAWSIZE = %d\nAWVALID = %d\nAWREADY = %d\n", s_awaddr, s_awlen, s_awsize, s_awvalid, s_awready);
		$display("W Channel: WDATA = 0x%08x\nWSTRB = %d\nWLAST = %d\nWVALID = %d\nWREADY = %d\n", s_wdata, s_wstrb, s_wlast, s_wvalid, s_wready);
		$display("B Channel: BRESP = 0x%08x\nBVALID = %d\nBREADY = %d\n\n\n", s_bresp, s_bvalid, s_bready);
	end
end



endmodule

