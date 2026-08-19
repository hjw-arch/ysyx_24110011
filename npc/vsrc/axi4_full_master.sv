// 仅支持增量传输、
// 需要重构
module axi4_full_master (
    // Global Signals
    input               clk,
    input               rst,

    // User Signals
    input               wen,        // 写数据和写地址有效
    input               ren,        // 读数据和读地址有效
    input               user_ready, // 主机可接受反馈
    input        [1:0]  size,       // 传输大小
    input        [7:0]  len,        // 传输次数（突发传输）
    input  logic [31:0] waddr,
    input  logic [31:0] wdata,
    input  logic [31:0] raddr,
    output logic [31:0] rdata,
    output logic        rdata_valid,
    output logic [1:0]  rresp,
    output logic [1:0]  wresp,
    output              done,

    // READ ADDRESS CHANNEL
    input               ARREADY,
    output              ARVALID,
    output       [31:0] ARADDR,
    output       [3:0]  ARID,
    output       [7:0]  ARLEN,
    output       [2:0]  ARSIZE,
    output       [1:0]  ARBURST,

    // READ DATA CHANNEL
    output              RREADY,
    input               RVALID,
    input        [31:0] RDATA,
    input               RLAST,
    input        [3:0]  RID,
    input        [1:0]  RRESP,

    // WRITE ADDRESS CHANNEL
    output       [31:0] AWADDR,
    output              AWVALID,
    output       [3:0]  AWID,
    output       [7:0]  AWLEN,
    output       [2:0]  AWSIZE,
    output       [1:0]  AWBURST,
    input               AWREADY,

    // WRITE DATA CHANNEL
    output       [31:0] WDATA,
    output       [3:0]  WSTRB,
    output              WLAST,
    output              WVALID,
    input               WREADY,

    // BRESP CHANNEL
    input        [1:0]  BRESP,
    input               BVALID,
    input        [3:0]  BID,
    output              BREADY
);

// 模式固定，BURST只传一个，不会连续传输
// ARSIZE只支持1、2、4字节
// 不支持乱序，XID固定
// 每次都是LAST传输
assign ARBURST = 2'b01;
assign AWBURST = 2'b01;
assign AWLEN   = 8'b0;        // 读通道不进行突发传输
assign WLAST   = 1'b1;        //
assign ARID    = 4'b0;
assign AWID    = 4'b0;

// 可根据AXSIZE判断地址是否对齐
// 000：无须对齐    001：地址最后一位必须为0    010：地址最后两位必须为0
assign ARSIZE = {1'b0, size};
assign AWSIZE = {1'b0, size};

assign ARLEN = len;

typedef enum logic [1:0] {
    R_IDLE,
    R_WAIT_ARREADY,
    R_WAIT_RDATA
} r_state_t;

typedef enum logic [2:0] {
    W_IDLE,
    W_WAIT_ALLREADY,
    W_WAIT_AWREADY,
    W_WAIT_WREADY,
    W_WAIT_BRESP
} w_state_t;

r_state_t r_state, next_r_state;
w_state_t w_state, next_w_state;

always_ff @(posedge clk) begin
    r_state <= rst ? R_IDLE : next_r_state;
end

// 时序可优化，2级mux->1级mux
always_comb begin
    case(r_state)
        R_IDLE:
            case({ARVALID, ARREADY})
                2'b11: next_r_state = R_WAIT_RDATA;
                2'b10: next_r_state = R_WAIT_ARREADY;
                default: next_r_state = r_state;
            endcase
        R_WAIT_ARREADY:
            next_r_state = ARREADY ? R_WAIT_RDATA : r_state;
        R_WAIT_RDATA:
            next_r_state = RVALID & RREADY & RLAST ? R_IDLE : r_state;
        default:
            next_r_state = r_state;
    endcase
end

reg [31 : 0] RDATA_TEMP;
always_ff @(posedge clk) begin
    RDATA_TEMP <= RVALID & RREADY ? RDATA : RDATA_TEMP;
end

// rdata
always_comb begin
    case ({ARSIZE[1 : 0], ARADDR[1 : 0]})
        4'b0000: rdata = {24'b0, RDATA_TEMP[7:0]};
        4'b0001: rdata = {24'b0, RDATA_TEMP[15:8]};
        4'b0010: rdata = {24'b0, RDATA_TEMP[23:16]};
        4'b0011: rdata = {24'b0, RDATA_TEMP[31:24]};
        4'b0100: rdata = {16'b0, RDATA_TEMP[15:0]};
        4'b0110: rdata = {16'b0, RDATA_TEMP[31:16]};
        4'b1000: rdata = RDATA_TEMP;
        default: rdata = 32'b0;
    endcase
end

assign ARADDR = raddr;
assign rresp  = RRESP;

assign ARVALID = r_state == R_IDLE & ren | r_state == R_WAIT_ARREADY;
assign RREADY  = r_state == R_WAIT_RDATA & user_ready;

always_ff @(posedge clk) begin
    rdata_valid <= RVALID & RREADY ? 1'b1 : 1'b0;
end

reg rdone;
always_ff @(posedge clk) begin
    rdone <= RVALID & RREADY & RLAST ? 1'b1 : 1'b0;
end

// 写通道
always_ff @(posedge clk) begin
    w_state <= rst ? W_IDLE : next_w_state;
end

// 时序可优化，2级mux->1级mux
always_comb begin
    case(w_state)
        W_IDLE:
            case({AWVALID & WVALID, AWREADY, WREADY})
                3'b111: next_w_state = W_WAIT_BRESP;
                3'b110: next_w_state = W_WAIT_WREADY;
                3'b101: next_w_state = W_WAIT_AWREADY;
                3'b100: next_w_state = W_WAIT_ALLREADY;
                default: next_w_state = W_IDLE;
            endcase
        W_WAIT_ALLREADY:
            case({AWREADY, WREADY})
                2'b11: next_w_state = W_WAIT_BRESP;
                2'b10: next_w_state = W_WAIT_WREADY;
                2'b01: next_w_state = W_WAIT_AWREADY;
                default: next_w_state = w_state;
            endcase
        W_WAIT_AWREADY:
            next_w_state = AWREADY ? W_WAIT_BRESP : w_state;
        W_WAIT_WREADY:
            next_w_state = WREADY ? W_WAIT_BRESP : w_state;
        W_WAIT_BRESP:
            next_w_state = BVALID & BREADY ? W_IDLE : w_state;
        default:
            next_w_state = w_state;
    endcase
end

// 设置WSTRB
// always_comb begin
//     case(AWSIZE[1 : 0])
//         2'b00:
//             case(waddr[1 : 0])
//                 2'b00: WSTRB = 4'b0001;
//                 2'b01: WSTRB = 4'b0010;
//                 2'b10: WSTRB = 4'b0100;
//                 2'b11: WSTRB = 4'b1000;
//             endcase
//         2'b01:
//             case(waddr[1])
//                 1'b1: WSTRB = 4'b1100;
//                 1'b0: WSTRB = 4'b0011;
//             endcase
//         2'b10:
//             WSTRB = 4'b1111;
//         default:
//             WSTRB = 4'b0000;
//     endcase
// end

// 同等替换，效率更高
// 不支持非对齐访问
assign WSTRB[0] = ~AWSIZE[1] & ~AWSIZE[0] & ~AWADDR[1] & ~AWADDR[0] | ~AWSIZE[1] & AWSIZE[0] & ~AWADDR[1] | AWSIZE[1] & ~AWSIZE[0];
assign WSTRB[1] = ~AWSIZE[1] & ~AWSIZE[0] & ~AWADDR[1] & AWADDR[0] | ~AWSIZE[1] & AWSIZE[0] & ~AWADDR[1] | AWSIZE[1] & ~AWSIZE[0];
assign WSTRB[2] = ~AWSIZE[1] & ~AWSIZE[0] & AWADDR[1] & ~AWADDR[0] | ~AWSIZE[1] & AWSIZE[0] & AWADDR[1] | AWSIZE[1] & ~AWSIZE[0];
assign WSTRB[3] = ~AWSIZE[1] & ~AWSIZE[0] & AWADDR[1] & AWADDR[0] | ~AWSIZE[1] & AWSIZE[0] & AWADDR[1] | AWSIZE[1] & ~AWSIZE[0];

// WDATA
// always_comb begin
//     case (AWSIZE[1 : 0])
//         2'b00: // 1 字节
//             case (waddr[1:0])
//                 2'b00: WDATA = {24'b0, wdata[7:0]};          // 第 0 字节
//                 2'b01: WDATA = {16'b0, wdata[7:0], 8'b0};    // 第 1 字节
//                 2'b10: WDATA = {8'b0, wdata[7:0], 16'b0};    // 第 2 字节
//                 2'b11: WDATA = {wdata[7:0], 24'b0};          // 第 3 字节
//             endcase
//         2'b01: // 2 字节
//             case (waddr[1])
//                 1'b0: WDATA = {16'b0, wdata[15:0]};         // 第 0、1 字节
//                 1'b1: WDATA = {wdata[15:0], 16'b0};         // 第 2、3 字节
//             endcase
//         2'b10: //  personally4 字节
//             WDATA = wdata;                              // 完整 32 位
//         default:
//             WDATA = 32'b0;                              // 默认 0
//     endcase
// end

// 同等替换，效率更高

// 不支持非对齐访问
assign WDATA[7 : 0] = {8{~AWSIZE[1] & ~AWSIZE[0] & ~AWADDR[1] & ~AWADDR[0]}} & wdata[7 : 0] |
                        {8{~AWSIZE[1] & AWSIZE[0] & ~AWADDR[1]}} & wdata[7 : 0] |
                        {8{AWSIZE[1] & ~AWSIZE[0]}} & wdata[7 : 0];

assign WDATA[15 : 8] = {8{~AWSIZE[1] & ~AWSIZE[0] & ~AWADDR[1] & AWADDR[0]}} & wdata[7 : 0] |
                        {8{~AWSIZE[1] & AWSIZE[0] & ~AWADDR[1]}} & wdata[15 : 8] |
                        {8{AWSIZE[1] & ~AWSIZE[0]}} & wdata[15 : 8];

assign WDATA[23 : 16] = {8{~AWSIZE[1] & ~AWSIZE[0] & AWADDR[1] & ~AWADDR[0]}} & wdata[7 : 0] |
                        {8{~AWSIZE[1] & AWSIZE[0] & AWADDR[1]}} & wdata[7 : 0] |
                        {8{AWSIZE[1] & ~AWSIZE[0]}} & wdata[23 : 16];

assign WDATA[31 : 24] = {8{~AWSIZE[1] & ~AWSIZE[0] & AWADDR[1] & AWADDR[0]}} & wdata[7 : 0] |
                        {8{~AWSIZE[1] & AWSIZE[0] & AWADDR[1]}} & wdata[15 : 8] |
                        {8{AWSIZE[1] & ~AWSIZE[0]}} & wdata[31 : 24];

assign AWADDR  = waddr;
assign AWVALID = w_state == W_IDLE & wen | w_state == W_WAIT_AWREADY | w_state == W_WAIT_ALLREADY;
assign WVALID  = w_state == W_IDLE & wen | w_state == W_WAIT_WREADY | w_state == W_WAIT_ALLREADY;
assign BREADY  = w_state == W_WAIT_BRESP & user_ready;
assign wresp   = BRESP;

wire wdone = BVALID & BREADY;

assign done = rdone | wdone;    // 告诉主机，下个上升沿就可以保存数据

endmodule
