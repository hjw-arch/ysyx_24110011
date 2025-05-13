module ALU #(parameter WIDTH = 32) (        // 需要狠狠优化
    input [3 : 0] alu_op,
    input [WIDTH - 1 : 0] data1,
    input [WIDTH - 1 : 0] data2,

    output [WIDTH - 1 : 0] result,
    output zero_flag
);

// 加减法器
wire cin = alu_op[2] | alu_op[0];
wire [WIDTH - 1 : 0] addsub_result;
wire cout;
adder32 addsub(
    .a(data1),
    .b(data2 ^ {WIDTH{cin}}),
    .cin(cin),
    .result(addsub_result),
    .cout(cout)
);

// assign {cout, addsub_result} = data1 + (data2 ^ {WIDTH{cin}}) + cin;    // 另一种方法

// 移位, 这么写可能带来巨大的面积开销，可以手写桶形移位器来解决
wire [WIDTH - 1 : 0] left_logic_shifter = data1 << data2[$clog2(WIDTH) - 1 : 0];
wire [WIDTH - 1 : 0] right_logic_shifter = data1 >> data2[$clog2(WIDTH) - 1 : 0];
wire [WIDTH - 1 : 0] right_arithmetic_shifter = $signed(data1) >>> data2[$clog2(WIDTH) - 1 : 0];

// 与 或 异或
wire [WIDTH - 1 : 0] and_result = data1 & data2;
wire [WIDTH - 1 : 0] or_result = data1 | data2;
wire [WIDTH - 1 : 0] xor_result = data1 ^ data2;

// 比较大小
wire real_symbol = data2[WIDTH - 1] ^ cin;
wire overflow_flag = (data1[WIDTH - 1] & real_symbol & ~addsub_result[WIDTH - 1]) | 
                     (~data1[WIDTH - 1] & ~real_symbol & addsub_result[WIDTH - 1]);

wire [WIDTH - 1 : 0] less_signed_result = {{(WIDTH - 1){1'b0}}, addsub_result[WIDTH - 1] ^ overflow_flag};
wire [WIDTH - 1 : 0] less_unsigned_result = {{(WIDTH - 1){1'b0}}, cout ^ cin};

logic [WIDTH - 1 : 0] result_comb;
// 选择器
always_comb begin
    case(alu_op)
        4'b0000: result_comb = addsub_result;
        4'b0001: result_comb = addsub_result;
        4'b1110: result_comb = and_result;
        4'b1100: result_comb = or_result;
        4'b1000: result_comb = xor_result;
        4'b0010: result_comb = left_logic_shifter;
        4'b1010: result_comb = right_logic_shifter;
        4'b1011: result_comb = right_arithmetic_shifter;
        4'b0100: result_comb = less_signed_result;
        4'b0110: result_comb = less_unsigned_result;
        default: result_comb = data2;
    endcase
end

assign result = result_comb;
assign zero_flag = ~(|addsub_result);

endmodule
