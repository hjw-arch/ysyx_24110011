module CLINT (
    input clk,
    input rst,

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

// 内部只读寄存器
reg [63 : 0] mtime;

always_ff @(posedge clk) begin
    mtime <= rst ? 64'b0 : mtime + 1;
end

// 读通道
typedef enum logic [1 : 0] { 
    R_IDLE,
    R_ACTIVE,
    R_WAIT_RREADY
} r_state_t;

r_state_t state, next_state;

always_ff @(posedge clk) begin
    state <= rst ? R_IDLE : next_state;
end

always_comb begin
    case(state)
        R_IDLE:
            next_state = ARVALID ? R_ACTIVE : state;
        R_ACTIVE:
            case({RVALID, RREADY})
                2'b11: next_state = R_IDLE;
                2'b10: next_state = R_WAIT_RREADY;
                default: next_state = state;
            endcase
        R_WAIT_RREADY:
            next_state = RREADY ? R_IDLE : state;
        default:
            next_state = state;
    endcase
end

assign ARREADY = state == R_IDLE;
assign RVALID = state == R_ACTIVE | state == R_WAIT_RREADY;

reg [31 : 0] raddr_buf;
always_ff @(posedge clk) begin
    raddr_buf <= ARVALID & ARREADY ? ARADDR : raddr_buf;
end


assign RDATA = {32{~(|raddr_buf[2 : 0])}} & mtime[31 : 0] | {32{raddr_buf[2] & ~raddr_buf[1] & ~raddr_buf[0]}} & mtime[63 : 32];
assign RRESP = ~(|raddr_buf[2 : 0]) | raddr_buf[2] & ~raddr_buf[1] & ~raddr_buf[0] ? 2'b00 : 2'b10;


assign AWREADY = 1'b1;
assign WREADY = 1'b1;
assign BVALID = 1'b1;
assign BRESP = 2'b10;

endmodule
