// `define SOC  1

`ifdef SOC
    //ifdef

`else
//else

module SRAM(
    input clk,
    input rst,

    // AXI4 从接口 - 读地址通道
    input  logic [3:0]  ARID,      // 读事务ID
    input  logic [31:0] ARADDR,    // 读地址
    input  logic [7:0]  ARLEN,     // 突发长度（仅支持0）
    input  logic [2:0]  ARSIZE,    // 突发大小
    input  logic [1:0]  ARBURST,   // 突发类型（仅支持FIXED）
    input  logic        ARVALID,   // 读地址有效
    output logic        ARREADY,   // 读地址准备好

    // 读数据通道
    output logic [3:0]  RID,       // 读事务ID
    output logic [31:0] RDATA,     // 读数据
    output logic [1:0]  RRESP,     // 读响应
    output logic        RLAST,     // 读数据结束
    output logic        RVALID,    // 读数据有效
    input  logic        RREADY,    // 读数据准备好

    // 写地址通道
    input  logic [3:0]  AWID,      // 写事务ID
    input  logic [31:0] AWADDR,    // 写地址
    input  logic [7:0]  AWLEN,     // 突发长度（仅支持0）
    input  logic [2:0]  AWSIZE,    // 突发大小
    input  logic [1:0]  AWBURST,   // 突发类型（仅支持FIXED）
    input  logic        AWVALID,   // 写地址有效
    output logic        AWREADY,   // 写地址准备好

    // 写数据通道
    input  logic [31:0] WDATA,     // 写数据
    input  logic [3:0]  WSTRB,     // 写选通
    input  logic        WLAST,     // 写数据结束
    input  logic        WVALID,    // 写数据有效
    output logic        WREADY,    // 写数据准备好

    // 写响应通道
    output logic [3:0]  BID,       // 写事务ID
    output logic [1:0]  BRESP,     // 写响应
    output logic        BVALID,    // 写响应有效
    input  logic        BREADY     // 写响应准备好
);

/*************************************** 回复无关信号 ******************************************/
// 读通道
assign RID   = ARID;
assign RLAST = 1'b1;

// 写通道
assign BID = AWID;

/**************************************** mtime **************************************************/

parameter R_DELAY_TIME = 5'd1;
parameter W_DELAY_TIME = 5'd1;

// 计时器
reg [4 : 0] r_delay_cnt, w_delay_cnt;

wire is_rcnt_not_zero = r_delay_cnt != 0;
wire is_wcnt_not_zero = w_delay_cnt != 0;

always_ff @(posedge clk) begin
    r_delay_cnt <= (ARVALID & ARREADY | r_state == R_ACTIVE) ? r_delay_cnt - {4'b0, is_rcnt_not_zero} : R_DELAY_TIME;
end

wire w_can_update = w_state == W_IDLE & AWVALID & WVALID | w_state == W_WAIT_ADDR & AWVALID | w_state == W_WAIT_DATA & WVALID;
always_ff @(posedge clk) begin
    w_delay_cnt <= (w_can_update | w_state == W_ACTIVE) ? w_delay_cnt - {4'b0, is_wcnt_not_zero} : W_DELAY_TIME;
end

import "DPI-C" function int pmem_read(input int addr, input int len);
import "DPI-C" function void pmem_write(input int addr, input int data, input int len);

// 读通道
typedef enum logic [2 : 0] {
    R_IDLE = 3'b001,
    R_ACTIVE = 3'b010,
    R_WAIT_RREADY = 3'b100
} r_state_t;

r_state_t r_state, next_r_state;

always_ff @(posedge clk) begin
    r_state <= rst ? R_IDLE : next_r_state;
end

always_comb begin
    case(r_state)
        R_IDLE:
            next_r_state = ARVALID ? R_ACTIVE : R_IDLE;
        R_ACTIVE:
            case({RVALID, RREADY})
                2'b11: next_r_state = R_IDLE;
                2'b10: next_r_state = R_WAIT_RREADY;
                default: next_r_state = R_ACTIVE;
            endcase
        R_WAIT_RREADY:
            next_r_state = RREADY ? R_IDLE : R_WAIT_RREADY;
        default:
            next_r_state = R_IDLE;
    endcase
end

assign ARREADY = r_state == R_IDLE;
assign RVALID  = (~is_rcnt_not_zero & r_state == R_ACTIVE) | (r_state == R_WAIT_RREADY); // // 这里的r_state == R_ACTIVE可能没什么必要，除非0周期读数

reg [31 : 0] raddr_buf;
always_ff @(posedge clk) begin
    raddr_buf <= ARVALID & ARREADY ? ARADDR : raddr_buf;
end

assign RDATA = ~is_rcnt_not_zero ? pmem_read(raddr_buf, {28'b0, 4'b1111}) : 32'b0;
assign RRESP = 2'b00;

// 写通道

typedef enum logic [4 : 0] {
    W_IDLE = 5'b00001,
    W_WAIT_ADDR = 5'b00010,
    W_WAIT_DATA = 5'b00100,
    W_ACTIVE = 5'b01000,
    W_WAIT_BREADY = 5'b10000
} w_state_t;

w_state_t w_state, next_w_state;

always_ff @(posedge clk) begin
    w_state <= rst ? W_IDLE : next_w_state;
end

always_comb begin
    case(w_state)
        W_IDLE:
            case({AWVALID, WVALID})
                2'b11: next_w_state = W_ACTIVE;
                2'b10: next_w_state = W_WAIT_DATA;
                2'b01: next_w_state = W_WAIT_ADDR;
                default: next_w_state = W_IDLE;
            endcase
        W_WAIT_ADDR:
            next_w_state = AWVALID ? W_ACTIVE : W_WAIT_ADDR;
        W_WAIT_DATA:
            next_w_state = WVALID ? W_ACTIVE : W_WAIT_DATA;
        W_ACTIVE:
            case({BVALID, BREADY})
                2'b11: next_w_state = W_IDLE;
                2'b10: next_w_state = W_WAIT_BREADY;
                default: next_w_state = W_ACTIVE;
            endcase
        W_WAIT_BREADY:
            next_w_state = BREADY ? W_IDLE : W_WAIT_BREADY;
        default:
            next_w_state = W_IDLE;
    endcase
end

reg [31 : 0] waddr_buf;
reg [31 : 0] wdata_buf;
always_ff @(posedge clk) begin
    waddr_buf <= AWVALID & AWREADY ? AWADDR : waddr_buf;
    wdata_buf <= WVALID & WREADY ? WDATA : wdata_buf;
end

assign AWREADY = w_state == W_IDLE | w_state == W_WAIT_ADDR;
assign WREADY  = w_state == W_IDLE | w_state == W_WAIT_DATA;
assign BVALID  = w_state == W_ACTIVE & ~is_wcnt_not_zero | w_state == W_WAIT_BREADY;

always_comb begin
    if (~is_wcnt_not_zero && w_state == W_ACTIVE) begin
       pmem_write(waddr_buf, wdata_buf, {28'b0, WSTRB});
    end
end

assign BRESP = 2'b00;

endmodule

`endif
