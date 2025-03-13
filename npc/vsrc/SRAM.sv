module SRAM(
    input  clk, 
    input  rst,

    input  ARVALID,
    output ARREADY,
    input  [31 : 0] ARADDR,

    output RVALID,
    input  RREADY,
    output [31 : 0] RDATA,
    output [1 : 0] RRESP,

    input  AWVALID,
    output AWREADY,
    input  [31 : 0] AWADDR,

    input  WVALID,
    output WREADY,
    input  [31 : 0] WDATA,
    input  [3 : 0] WSTRB,

    input  BREADY,
    output BVALID,
    output [1 : 0] BRESP
);

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
assign RVALID = (~is_rcnt_not_zero & r_state == R_ACTIVE) | (r_state == R_WAIT_RREADY); // // 这里的r_state == R_ACTIVE可能没什么必要，除非0周期读数

reg [31 : 0] raddr_buf;
always_ff @(posedge clk) begin
    raddr_buf <= ARVALID & ARREADY ? ARADDR : raddr_buf;
end


assign RDATA = ~is_rcnt_not_zero ? pmem_read(raddr_buf, {28'b0, WSTRB}) : 32'b0;
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
assign WREADY = w_state == W_IDLE | w_state == W_WAIT_DATA;
assign BVALID = w_state == W_ACTIVE & ~is_wcnt_not_zero | w_state == W_WAIT_BREADY;

always_comb begin
    if (~is_wcnt_not_zero && w_state == W_ACTIVE) begin
       pmem_write(waddr_buf, wdata_buf, {28'b0, WSTRB});
    end
end

assign BRESP = 2'b00;


endmodule
