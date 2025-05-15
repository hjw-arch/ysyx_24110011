// m0＞m1
// 如果能够提前一个周期发送一个预请求，那么就能忽略仲裁器带来的延迟影响
// 五级流水线时可以对读通道和写通道各自实现仲裁，这样可以同时读写
module axi4_lite_arbiter
(
    input clk,
    input rst,

    input logic [1 : 0] prerequest,

    // MASTER Signals
    // READ ADDRESS CHANNEL
    input  logic [1 : 0][31 : 0] maraddr,
    input  logic [1 : 0]marvalid,
    output logic [1 : 0]marready,

    // READ DATA CHANNEL
    output logic [1 : 0][31 : 0] mrdata,
    output logic [1 : 0][1 : 0] mrresp,
    output logic [1 : 0] mrvalid,
    input  logic [1 : 0] mrready,

    // WRITE ADDRESS CHANNEL
    input  logic [1 : 0][31 : 0] mawaddr,
    input  logic [1 : 0] mawvalid,
    output logic [1 : 0] mawready,

    // WRITE DATA CHANNEL
    input  logic [1 : 0][31 : 0] mwdata,
    input  logic [1 : 0][3 : 0] mwstrb,
    input  logic [1 : 0] mwvalid,
    output logic [1 : 0] mwready,

    // BRESP CHANNEL
    output logic [1 : 0][1 : 0] mbresp,
    output logic [1 : 0] mbvalid,
    input  logic [1 : 0] mbready,


    // SLAVE Signals
    // READ ADDRESS CHANNEL
    output logic [31 : 0] saraddr,
    output logic sarvalid,
    input  logic sarready,

    // READ DATA CHANNEL
    input  logic [31 : 0] srdata,
    input  logic [1 : 0] srresp,
    input  logic srvalid,
    output logic srready,

    // WRITE ADDR CHANNEL
    output logic [31 : 0] sawaddr,
    output logic sawvalid,
    input  logic sawready,

    // WRITE DATA CHANNEL
    output logic [31 : 0] swdata,
    output logic [3 : 0] swstrb,
    output logic swvalid,
    input  logic swready,

    // BRESP CHANNEL
    input  logic [1 : 0] sbresp,
    input  logic sbvalid,
    output logic sbready
);

logic [1 : 0] request = marvalid | mawvalid | mwvalid | prerequest;
logic [1 : 0] will_done;
assign will_done[0] = srvalid & mrready[0] | sbvalid & mbready[0];
assign will_done[1] = srvalid & mrready[1] | sbvalid & mbready[1];

typedef enum logic [2 : 0]{ 
    IDLE = 3'b001,
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



// 转发机制
assign mrdata[0] = srdata;
assign mrdata[1] = srdata;
assign mrresp[0] = srresp;
assign mrresp[1] = srresp;
assign mbresp[0] = sbresp;
assign mbresp[1] = sbresp;
assign mrvalid[0] = srvalid;
assign mrvalid[1] = srvalid;
assign mbvalid[0] = sbvalid;
assign mbvalid[1] = sbvalid;

assign marready[0] = (state == M0_ACTIVE) ? sarready : 1'b0;
assign mawready[0] = (state == M0_ACTIVE) ? sawready : 1'b0;
assign mwready[0] = (state == M0_ACTIVE) ? swready : 1'b0;

assign marready[1] = (state == M1_ACTIVE) ? sarready : 1'b0;
assign mawready[1] = (state == M1_ACTIVE) ? sawready : 1'b0;
assign mwready[1] = (state == M1_ACTIVE) ? swready : 1'b0;

// 要注意时序，对于握手信号，只有仲裁选择之后才能接通
assign sarvalid = (state == M1_ACTIVE) & marvalid[1] | (state == M0_ACTIVE) & marvalid[0];
assign sawvalid = (state == M1_ACTIVE) & mawvalid[1] |  (state == M0_ACTIVE) & mawvalid[0];
assign swvalid = (state == M1_ACTIVE) & mwvalid[1] | (state == M0_ACTIVE) & mwvalid[0];

assign saraddr = (state == M1_ACTIVE) ? maraddr[1] : maraddr[0];
assign srready = (state == M1_ACTIVE) ? mrready[1] : mrready[0];
assign sawaddr = (state == M1_ACTIVE) ? mawaddr[1] : mawaddr[0];
assign swdata = (state == M1_ACTIVE) ? mwdata[1] : mwdata[0];
assign swstrb = (state == M1_ACTIVE) ? mwstrb[1] : mwstrb[0];
assign sbready = (state == M1_ACTIVE) ? mbready[1] : mbready[0];


endmodule

