module EXU #(parameter WIDTH = 32) (
    input clk,
    input rst,

    input idu_valid,
    input [191 : 0] idu_data,
    output exu_ready,

    output exu_valid,
    output reg [108 : 0] exu_data,
    input lsu_ready,

    // 给到LSU进行仲裁器预准备
    output pre_lsu_ren,
    output pre_lsu_wen,


    // 直通PC
    // 仅仅适用多周期处理器
    input [1 : 0] pc_sel,
    input pc_sel_for_adder_left,
    input is_branch,
    input [31 : 0] imm,
    input [31 : 0] inst,
    output [31 : 0] pc
);


wire [WIDTH - 1 : 0] alu_data1 = idu_data[191 : 160];
wire [WIDTH - 1 : 0] alu_data2 = idu_data[159 : 128];
wire [3 : 0] alu_op = idu_data[127 : 124];
wire csr_wen = idu_data[123];
wire csr_sel = idu_data[122];
wire csr_is_ecall = idu_data[121];
wire [11 : 0] csr_addr = idu_data[120 : 109];
wire [31 : 0] pc_now = idu_data[108 : 77];
wire [31 : 0] rs1_data = idu_data[76 : 45];
wire [44 : 0] rest_idu_data = idu_data[44 : 0];

// 给到LSU预取
assign pre_lsu_ren = idu_data[44];
assign pre_lsu_wen = idu_data[43];


typedef enum logic { 
    S_IDLE,
    S_WAIT_READY
} exu_state_t;

exu_state_t state, next_state;

always_ff @(posedge clk) begin
    state <= rst ? S_IDLE : next_state;
end

always_comb begin
    case(state)
        S_IDLE:
            next_state = (exu_valid & ~lsu_ready) ? S_WAIT_READY : S_IDLE;
        S_WAIT_READY:
            next_state = (lsu_ready) ? S_IDLE : S_WAIT_READY;
        default:
            next_state = S_IDLE;
    endcase
end

reg has_new_data;
always_ff @(posedge clk) begin
    has_new_data <= (idu_valid & exu_ready) ? 1'b1 : 1'b0;
end

assign exu_ready = lsu_ready;
assign exu_valid = has_new_data | (state == S_WAIT_READY);

wire [31 : 0] alu_result;
wire zero_flag;

ALU #(WIDTH) alu (
    .alu_op(alu_op),
    .data1(alu_data1),
    .data2(alu_data2),
    .result(alu_result),
    .zero_flag(zero_flag)
);


// 直接在EXU内做完对CSR寄存器的读取写入全流程
wire [31 : 0] mtvec;    // For PC
wire [31 : 0] mepc;     // For PC

wire [31 : 0] csr_data_o;
wire [31 : 0] csr_data_i = csr_sel ? rs1_data | csr_data_o : rs1_data;
CSR #(32) CSR_INTER(
    .clk(clk),
    .rst(rst),
    .wen(csr_wen & has_new_data),
    .is_ecall(csr_is_ecall & has_new_data),
    .addr(csr_addr),
    .data_in(csr_data_i),
    .pc(pc_now),
    .data_out(csr_data_o),
    .mtvec(mtvec),
    .mepc(mepc)
);

always_ff @(posedge clk) begin
    exu_data <= (exu_valid & lsu_ready) ? {alu_result, rest_idu_data, csr_data_o} : exu_data;
end


// PC直通
PC #(WIDTH) PC_INTER(
    .clk(clk),
    .rst(rst),
    .valid(exu_valid),
    .sel(pc_sel),
    .sel_for_adder_left(pc_sel_for_adder_left),
    .is_branch(is_branch),
    .zero_flag(zero_flag),
    .less_flag(alu_result[0]),
    .inst(inst),
    .rs1(rs1_data),
    .imm(imm),
    .mtvec(mtvec),
    .mepc(mepc),
    .pc(pc)
);


endmodule
