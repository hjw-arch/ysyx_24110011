// 这种PC的计算方法仅仅在单、多周期处理器适用
// 五级流水线时，要分别计算无条件跳转和条件跳转，PC的最终值由ID解析出来的sel和ALU计算结果决定
// 暂时不改动

// `define SOC 1

module PC #(parameter WIDTH = 32) (
    input clk,
    input rst,
    input valid,
    input [1 : 0] sel,
    input sel_for_adder_left,
    input is_branch,
    input zero_flag,
    input less_flag,
    input [31 : 0] inst,
    input [WIDTH - 1 : 0] rs1,
    input [WIDTH - 1 : 0] imm,
    input [WIDTH - 1 : 0] mtvec,
    input [WIDTH - 1 : 0] mepc,

    output reg [WIDTH - 1 : 0] pc
);

`ifdef SOC

localparam RST_VECTOR = 32'h30000000;
	
`else

localparam RST_VECTOR = 32'h80000000;
	
`endif


wire sel_for_adder_right = inst[6] & inst[2] |     // 这条信号会是瓶颈，是关键路径，单多周期不影响，流水线需要单独设置这条信号
                            is_branch & ~inst[14] & ~inst[12] & zero_flag |
                            is_branch & ~inst[14] & inst[12] & ~zero_flag |
                            is_branch & inst[14] & ~inst[12] & less_flag |
                            is_branch & inst[14] & inst[12] & ~less_flag;

wire [WIDTH - 1 : 0] adder_left = sel_for_adder_left ? rs1 : pc;
wire [WIDTH - 1 : 0] adder_right = sel_for_adder_right ? imm : {{(WIDTH-3){1'b0}}, 3'b100};

wire [WIDTH - 1 : 0] adder_result = adder_left + adder_right;

wire [WIDTH - 1 : 0] new_pc = sel == 2'b01 ? mtvec :
                              sel == 2'b11 ? mepc  : 
                              adder_result;

always_ff @(posedge clk) begin
    if (rst) pc <= RST_VECTOR;
    else if (valid) pc <= new_pc;
    else pc <= pc;
end


endmodule
