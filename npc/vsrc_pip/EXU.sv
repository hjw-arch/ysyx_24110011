module EXU #(parameter WIDTH = 32) (
    input 			clk,
    input			rst,

    input			valid_i,
    input	[191:0] data_i,
    output			ready_o,

    output			valid_o,
    output	[108:0]	data_o,
    input			ready_i,

    // 给到LSU进行仲裁器预准备
    output pre_lsu_ren,
    output pre_lsu_wen
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

logic state, nstate;

always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : nstate;
end

assign nstate = valid_o & ~ready_i;

assign valid_o = valid_i | state;


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
CSR CSR_INTER(
    .clk			(clk							),
    .rst			(rst							),
    .wen_i			(csr_wen & has_new_data			),
    .is_ecall_i		(csr_is_ecall & has_new_data	),
    .addr_i			(csr_addr						),
    .data_i			(csr_data_i						),
    .pc_i			(pc_now							),
    .data_o			(csr_data_o						),
    .mtvec_o		(mtvec							),
    .mepc_o			(mepc							)
);

always_ff @(posedge clk) begin
    exu_data <= (exu_valid & lsu_ready) ? {alu_result, rest_idu_data, csr_data_o} : exu_data;
end


/************************** 性能计数器 *****************************/

// import "DPI-C" function void PerformanceCounter_exu_finish_cal();

// always_ff @(posedge clk) begin
// 	if (exu_valid & (state != S_WAIT_READY))  PerformanceCounter_exu_finish_cal();
// end

// always_ff @(posedge clk) begin
// 	if (has_new_data) $display("EXU!\n");
// end

/******************************************************************/




endmodule
