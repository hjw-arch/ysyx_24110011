module IDU (
    input 			clk,
    input			rst,

    output	[4:0] 	rs1_addr,
    output	[4:0] 	rs2_addr,
    input 	[31:0] 	rs1_data,
    input	[31:0] 	rs2_data,

	input 			hazard,
	input			fflush,

    input			valid_i,
    input	[63:0] 	data_i,
    output			ready_o,

	output			valid_o,
	output	[191:0]	data_o,
	input 			ready_i
);

`define HANDSHAKE 		valid_o & ready_i;
`define 


logic [31:0] inst	=	data_i[63:32];
logic [31:0] pc		=	data_i[31:0];


logic state, nstate;
logic [4:0] rd_addr;
logic [31:0] alu_src1, alu_src2;


always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : nstate;
end

assign nstate = valid_o & ~ready_i;

assign valid_o = valid_i | state;
assign ready_o = ready_i;



assign rs1_addr	= inst[19:15];
assign rs2_addr	= inst[24:20];
assign rd_addr	= inst[11:7];




// EXU部分 如果使用独热码，关键路径可以被优化, 面积会增加
wire [3 : 0] alu_op;
assign alu_op[3] = ~inst[5] & inst[4] & ~inst[2] & inst[14] & ~inst[13] & inst[12] & inst[30] |             // srai
                   inst[5] & inst[4] & inst[30] |          // R
                   inst[5] & inst[4] & inst[2];   //  lui

assign alu_op[0] = inst[4] & ~inst[2] & inst[12] |      // compute i + compute R
                  inst[6] & ~inst[2] & inst[13];    // Bu

assign alu_op[1] = inst[4] & ~inst[2] & inst[13] |       // compute i + compute R
                  inst[6] & ~inst[2];     // B

assign alu_op[2] = inst[4] & ~inst[2] & inst[14] |        // compute i + compute R
                  inst[5] & inst[4] & inst[2];        // lui

wire alu_left_sel = inst[2];  // U + J
wire alu_right_sel = inst[4] & inst[2] | ~inst[5] & inst[4] | ~inst[6] & ~inst[4];    // U + competeI + L + S

wire [31 : 0] alu_data1 = {32{alu_left_sel}} & pc | {32{~alu_left_sel}} & rs1_data;
wire [31 : 0] alu_data2 = {32{~alu_left_sel & ~alu_right_sel}} & rs2_data | {32{alu_left_sel & ~alu_right_sel}} & {{29{1'b0}}, 3'b100} | {32{alu_right_sel}} & imm;

// CSR
wire [11 : 0] csr_addr = inst[31 : 20];
wire csr_wen = inst[6] & inst[4] & |inst[13 : 12]; // Zicsr    添加此类指令需重构
wire csr_sel = inst[6] & inst[4] & inst[13];  // // Zicsr    添加此类指令需重构
wire csr_is_ecall = is_sys & ~inst[29];


// LSU部分
wire lsu_wen = ~inst[6] & inst[5] & ~inst[4];      // S
wire lsu_ren = ~inst[5] & ~inst[4];        // L
wire [2 : 0] lsu_op = inst[14 : 12];


wire is_sys = inst[6] & inst[4] & ~inst[13] & ~inst[12];    // 系统相关指令，ecall、mret，添加指令时可能需要做调整

// RF WB
wire rd_wen = ~(inst[5] & ~inst[4] & ~inst[2] | is_sys);   // ~((B + S) | sys)
wire [1 : 0] rd_input_sel;
assign rd_input_sel[1] = inst[6] & inst[4];     // CSR
assign rd_input_sel[0] = ~inst[5] & ~inst[4];   // Load

// PC部分   直通PC
assign pc_sel[1] = is_sys & inst[29];   // mret
assign pc_sel[0] = is_sys;  // ecall
assign pc_sel_for_adder_left = inst[6] & ~inst[3] & inst[2];
assign is_branch = inst[6] & ~inst[4] & ~inst[2];
assign pc_imm = imm;
assign pc_inst = inst;



// always_ff @(posedge clk) begin
//     idu_data <= (idu_valid & exu_ready) ? {alu_data1, alu_data2, alu_op, csr_wen, csr_sel, csr_is_ecall, csr_addr, pc, rs1_data, lsu_ren, lsu_wen, lsu_op, rs2_data, rd_wen, rd_addr, rd_input_sel} : idu_data;
// end



/************************** 性能计数器 *****************************/

// import "DPI-C" function void PerformanceCounter_idu_identify_inst(input int inst);

// always_ff @(posedge clk) begin
// 	if (idu_valid & (state != S_WAIT_READY)) PerformanceCounter_idu_identify_inst(inst);
// end

// always_ff @(posedge clk) begin
// 	if (has_new_data) $display("IDU!\n");
// end


/******************************************************************/


endmodule








/* verilator lint_off DECLFILENAME */
// 立即数生成器
module ImmGen #(parameter WIDTH = 32)(  /* verilator lint_off UNUSEDSIGNAL */
    input [31 : 0] inst,
    output [31 : 0] imm
);

// 64位需要扩展符号位
assign imm[WIDTH - 1 : 31] = {(WIDTH - 31){inst[31]}};

// 两级延迟
assign imm[10 : 5] = inst[30 : 25] & {6{~(inst[4] & inst[2])}}; // U-Type does not have imm[10 : 5] // {6~{~opcode[6] & opcode[4] & ~opcode[3] & opcode[2]}}， ~U

// 三级延迟，可以优化为两级延迟
assign imm[4 : 1] = inst[11 : 8] & {4{inst[5] & ~inst[2]}} |                    // S + B
                    inst[24 : 21] & {4{inst[3]}} |                                // J
                    inst[24 : 21] & {4{~inst[6] & ~inst[5] & ~inst[2]}} |     // I
                    inst[24 : 21] & {4{~inst[4] & ~inst[3] & inst[2]}};       // I

assign imm[0] = inst[20] & ~inst[6] & ~inst[5] & ~inst[2]  |              // I
                inst[20] & ~inst[4] & ~inst[3] & inst[2] |      // I
                inst[7] & ~inst[6] & inst[5] & ~inst[4];       // S

assign imm[30 : 20] = {11{inst[31] & ~(inst[4] & inst[2])}} | 
                      inst[30 : 20] & {11{inst[4] & inst[2]}}; // ~U | U

assign imm[19 : 12] = {8{inst[31] & inst[5] & ~inst[2]}} |                      // S + B
                      {8{inst[31] & ~inst[6] & ~inst[5] & ~inst[2]}} |        // I
                      {8{inst[31] & ~inst[4] & ~inst[3] & inst[2]}} |         // I
                      inst[19 : 12] & {8{inst[4] & inst[2]}} |                  // U
                      inst[19 : 12] & {8{inst[3]}};                               // J

assign imm[11] = inst[31] & ~inst[6] & inst[5] & ~inst[4] | 
                 inst[31] & ~inst[6] & ~inst[5] & ~inst[2] |
                 inst[31] & ~inst[4] & ~inst[3] & inst[2] |
                 inst[7] & inst[6] & ~inst[2] |
                 inst[20] & inst[3];

endmodule


module decode(
	input	[31:0]	inst,
	output	[3:0]	aluop,
	output			ls_load,
	output			ls_store,
	output	[2:0]	ls_type,
	output			is_jump,
	output			is_branch,
	output	[1:0]	branch_cond,
	output			rd_write,
	output	[1:0]	rd_src_sel,
	output 			is_csr,
	output 			is_ecall,
	output			csr_write,
	output			csr_op
);

localparam	OPCODE_LUI   	=	5'b01101;
localparam	OPCODE_AUIPC 	=	5'b00101;
localparam	OPCODE_JAL   	=	5'b11011;
localparam	OPCODE_JALR  	=	5'b11001;
localparam	OPCODE_BRANCH	=	5'b11000;
localparam	OPCODE_LOAD  	=	5'b00000;
localparam	OPCODE_STORE 	=	5'b01000;
localparam	OPCODE_CAL_I 	=	5'b00100;
localparam	OPCODE_CAL_R 	=	5'b01100;
localparam	OPCODE_CSR		=	5'b11100;

localparam	FUNC3_SRA		=	3'b101;

localparam	BRANCH_EQ		=	2'b00;
localparam	BRANCH_NE  		=	2'b01;
localparam	BRANCH_LT		=	2'b10; 
localparam	BRANCH_GE		=	2'b11;


`define 	IS_SRAI				opcode == OPCODE_CAL_I & func3 == FUNC3_SRA
`define  	IS_R_TYPE			opcode == OPCODE_CAL_R
`define  	IS_LUI				opcode == OPCODE_LUI
`define  	IS_CAL				opcode == OPCODE_CAL_I | opcode == OPCODE_CAL_R
`define  	IS_I_TYPE			opcode == OPCODE_LUI | opcode == OPCODE_AUIPC | opcode == OPCODE_CAL_I
`define  	IS_CSR_TYPE			opcode == OPCODE_CSR
`define  	IS_B				opcode == OPCODE_BRANCH & ~func3[2]
`define  	IS_BU				opcode == OPCODE_BRANCH & func3[2]
`define  	IS_LOAD				opcode == OPCODE_LOAD

logic [4:0]	opcode;
logic [2:0]	func3;
logic 		func7b5;

assign	opcode	= inst[6:2];
assign	func3	= inst[14:12];
assign	func7b5	= inst[30];

assign	aluop[3]		=	`IS_SRAI | `IS_R_TYPE & func7b5 | `IS_LUI;								// 此位对于func7b5存在值得指令，就是func7b5，对于LUI也是1
assign	aluop[2:0]		=	{3{`IS_CAL}} & func3 | {3{`IS_B}} & 3'b010 | {3{`IS_BU}} & 3'b011 | {3{`IS_LUI}} & 3'b100;		// 对于计算类指令是func3，对于B指令是010，BU是011，LUI是100

assign	ls_load			=	opcode == OPCODE_LOAD;
assign	ls_store		=	opcode == OPCODE_STORE;
assign	ls_type			=	func3;

assign	is_jump			=	opcode == OPCODE_JAL | opcode == OPCODE_JALR;
assign	is_branch		=	opcode == OPCODE_BRANCH;
assign	branch_cond		=	{func3[2], func3[0]};

assign	rd_write		=	opcode != OPCODE_STORE | opcode != OPCODE_BRANCH;
assign	rd_src_sel[0]	=	`IS_CSR_TYPE;
assign	rd_src_sel[1]	=	`IS_LOAD;

assign	is_csr			=	`IS_CSR_TYPE;
assign	is_ecall		=	`IS_CSR_TYPE & ~inst[29];




endmodule

