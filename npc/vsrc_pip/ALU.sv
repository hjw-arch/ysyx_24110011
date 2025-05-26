module ALU (        // 需要狠狠优化
    input [3 : 0] alu_op,
    input [31 : 0] data1,
    input [31 : 0] data2,

    output [31 : 0] result,
    output zero_flag
);

// 加减法器
wire cin = alu_op[1] | alu_op[3];
wire [31 : 0] addsub_result;
wire cout;
adder32 addsub(
    .a(data1),
    .b(data2 ^ {32{cin}}),
    .cin(cin),
    .result(addsub_result),
    .cout(cout)
);

// assign {cout, addsub_result} = data1 + (data2 ^ {32{cin}}) + cin;    // 另一种方法


wire [31:0] left_logic_shifter = data1 << data2[4:0];
wire [31:0] right_logic_shifter = data1 >> data2[4:0];
wire [31:0] right_arithmetic_shifter = $signed(data1) >>> data2[4:0];

// 与 或 异或
wire [31:0] and_result = data1 & data2;
wire [31:0] or_result = data1 | data2;
wire [31:0] xor_result = data1 ^ data2;

// 比较大小
wire real_symbol = data2[31] ^ cin;
wire overflow_flag = (data1[31] & real_symbol & ~addsub_result[31]) | 
                     (~data1[31] & ~real_symbol & addsub_result[31]);

wire [31:0] less_signed_result = {31'b0, addsub_result[31] ^ overflow_flag};
wire [31:0] less_unsigned_result = {31'b0, cout ^ cin};

logic [31 : 0] result_comb;
// 选择器
always_comb begin
    unique case(alu_op)
        4'b0000: result_comb = addsub_result;
        4'b1000: result_comb = addsub_result;
        4'b0111: result_comb = and_result;
        4'b0110: result_comb = or_result;
        4'b0100: result_comb = xor_result;
        4'b0001: result_comb = left_logic_shifter;
        4'b0101: result_comb = right_logic_shifter;
        4'b1101: result_comb = right_arithmetic_shifter;
        4'b0010: result_comb = less_signed_result;
        4'b0011: result_comb = less_unsigned_result;
        default: result_comb = data2;
    endcase
end

assign result = result_comb;
assign zero_flag = ~(|addsub_result);

endmodule
