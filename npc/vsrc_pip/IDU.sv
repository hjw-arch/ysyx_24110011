module IDU
(
    input 			clk,
    input			rst,

    output	[4:0] 	rs1_addr,
    output	[4:0] 	rs2_addr,
    input 	[31:0] 	rs1_data,
    input	[31:0] 	rs2_data,

	output	[4:0] 	id_rs1_addr,
	output	[4:0]	id_rs2_addr,
	input 			hazard,
	input			flush,
	output 			ifence,

    input			valid_i,
    input	[63:0] 	data_i,
    output			ready_o,

	output			valid_o,
	output	[174:0]	data_o,
	input 			ready_i
);

//================= OPCODE Definitions =================//
typedef enum logic [4:0] {
  OPCODE_LUI    = 5'b01101,
  OPCODE_AUIPC  = 5'b00101,
  OPCODE_JAL    = 5'b11011,
  OPCODE_JALR   = 5'b11001,
  OPCODE_BRANCH = 5'b11000,
  OPCODE_LOAD   = 5'b00000,
  OPCODE_STORE  = 5'b01000,
  OPCODE_FENCE  = 5'b00011,
  OPCODE_CAL_I  = 5'b00100,
  OPCODE_CAL_R  = 5'b01100,
  OPCODE_SYS    = 5'b11100
} opcode_type_e;

//================= FUNC3 Definitions =================//
typedef enum logic [2:0] {
  FUNC3_SRA     = 3'b101
} func3_type_e;

//================= FUNC7B5 Definitions =================//
typedef enum logic { 
	FUNC7B5_SRA = 1'b1
} func7b5_type_e;

//================= Branch Conditions =================//
typedef enum logic [1:0] {
  BRANCH_EQ     = 2'b00,
  BRANCH_NE     = 2'b01,
  BRANCH_LT     = 2'b10,
  BRANCH_GE     = 2'b11
} branch_cond_e;

`define 	IS_SRAI				opcode == OPCODE_CAL_I & func3 == FUNC3_SRA & func7b5 == FUNC7B5_SRA
`define  	IS_R_TYPE			opcode == OPCODE_CAL_R
`define  	IS_LUI				opcode == OPCODE_LUI
`define  	IS_CAL				opcode == OPCODE_CAL_I | opcode == OPCODE_CAL_R
`define  	IS_U_TYPE			~opcode[4] & opcode[2] & ~opcode[1] & opcode[0]
`define  	IS_I_TYPE			opcode == OPCODE_LUI | opcode == OPCODE_AUIPC | opcode == OPCODE_CAL_I
`define  	IS_SYS				opcode == OPCODE_SYS
`define  	IS_B				opcode == OPCODE_BRANCH & ~func3[1]
`define  	IS_BU				opcode == OPCODE_BRANCH & func3[1]
`define  	IS_LOAD				opcode == OPCODE_LOAD
`define  	IS_FENCE			opcode == OPCODE_FENCE

`define HANDSHAKE 				valid_o & ready_i


assign id_rs1_addr = rs1_addr_hazard & {5{valid_i | state}};
assign id_rs2_addr = rs2_addr_hazard & {5{valid_i | state}};


wire [31:0] inst	=	data_i[63:32];
wire [31:0] pc		=	data_i[31:0];


logic [4:0]	 rd_addr;
logic [4:0]	 opcode;
logic [2:0]	 func3;
logic 		 func7b5;
logic [1:0]	 alu_src_sel;	// 00: rs1, rs2		01: rs1, imm	10: pc, 4	11: pc, imm
logic [31:0] imm;
logic [4:0]  rs1_addr_hazard;
logic [4:0]  rs2_addr_hazard;
logic [11:0] csr_addr;
logic [3:0]	 alu_op;
logic [2:0]	 ls_type;
logic		 ls_load, ls_store;
logic		 is_jump, is_jalr, is_branch;
logic [1:0]	 branch_cond;
logic		 csr_ecall, csr_mret;
logic		 csr_wen, csr_cmd;

// 从valid_i出发
// 对于valid_o如果valid_i并且非flush非hazard，那么下个上升沿可以发送数据
// 如果valid_o且~ready_i，那么valid_o要持续置1，等待ready_i置1，此时本阶段数据仍然可用

// 有两个冲突，一是控制冲突，二是数据冲突，对于顺序流水线，也就是写后读冲突
// 对于控制冲突，如果接收到flush信号，那么就不能往前传递直到有新的valid_i，本阶段数据不可用，应该取消掉冲突检测，但是仍处于ready状态，可接收数据，IFU应该保证不向本阶段传送无效数据

// 对于写后读冲突，如果接收到hazard信号，那么本阶段不能发送valid_o，因为需要等待rs1、rs2数据有效，此时，应该记录下收到了hazard信号，以便hazard解除后可以发送valid_o

// 这两类冲突有一个区别：数据冲突的valid_o是待发送的，data_o是待有效的，而控制冲突的valid_o是无效的，data_o也是无效的
// 对于valid_o信号来说，他要指示下个上升沿可以发送数据，因此接收到valid_i且不存在冲突时，可以当周期置1，valid_o且非ready_i时，需要保持1
// 遇到hazard信号时，要等待hazard信号接触后再置1，对于flush信号，直接置0
// hazard和flush完全可能同时出现，要区分

// 因此实质上状态机只需要记录一个状态，就是本阶段数据待有效，待发送状态，IDLE且valid_o表示当即有效无需等待，IDLE且非valid_o表示当阶段无效


logic state, nstate;				// 0：IDLE	1：WAIT_TO_SEND
always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : nstate;
end

assign nstate = valid_o & ~ready_i | valid_i & hazard & ~flush | state & hazard;

assign valid_o = valid_i & ~flush & ~hazard | state & ~hazard;
assign ready_o = ready_i & ~hazard;

assign rs1_addr	= inst[19:15];
assign rs2_addr	= inst[24:20];

assign data_o = {alu_op, rs1_addr_hazard, rs2_addr_hazard, alu_src_sel, rs1_data, rs2_data, pc, imm, is_jump, is_jalr, is_branch, branch_cond, csr_wen, csr_cmd, csr_ecall, csr_mret, csr_addr, ls_store, ls_load, ls_type, rd_addr};

/********************************************** DATA ****************************************/
assign opcode = inst[6:2];

always_comb begin
    case (opcode)
        OPCODE_CAL_I, OPCODE_LOAD, OPCODE_JALR: // I-type
            imm = {{20{inst[31]}}, inst[31:20]};
        OPCODE_STORE: // S-type
            imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
        OPCODE_BRANCH: // B-type
            imm = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
        OPCODE_JAL: // J-type
            imm = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
        OPCODE_LUI, OPCODE_AUIPC: // U-type
            imm = {inst[31:12], 12'b0};
        default: imm = 32'b0;
    endcase
end

assign csr_addr = inst[31:20];


logic	rd_wen;
assign	alu_src_sel[1]  	=	(opcode == OPCODE_AUIPC | opcode == OPCODE_JALR | opcode == OPCODE_JAL);	// 0: rs1 1: pc
assign	alu_src_sel[0]  	=	(opcode == OPCODE_LUI | opcode == OPCODE_AUIPC | opcode == OPCODE_CAL_I | opcode == OPCODE_LOAD | opcode == OPCODE_STORE);	// 0: rs2, 1: imm	
assign	rd_wen				=	opcode != OPCODE_STORE & opcode != OPCODE_BRANCH;
assign	rs1_addr_hazard 	=	(opcode != OPCODE_SYS & opcode != OPCODE_JAL & opcode != OPCODE_LUI & opcode != OPCODE_AUIPC) ? rs1_addr : 5'b0;	
assign	rs2_addr_hazard 	=	(opcode == OPCODE_CAL_R | opcode == OPCODE_BRANCH | opcode == OPCODE_STORE) ? rs2_addr : 5'b0;
assign	rd_addr				=	rd_wen ? inst[11:7] : 5'b0;


/********************************************** CTRL ****************************************/

assign	func3			= 	inst[14:12];
assign	func7b5			= 	inst[30];

assign	alu_op[3]		=	`IS_SRAI | `IS_R_TYPE & func7b5 | `IS_LUI;								// 此位对于func7b5存在值得指令，就是func7b5，对于LUI也是1
assign	alu_op[2:0]		=	{3{`IS_CAL}} & func3 | {3{`IS_B}} & 3'b010 | {3{`IS_BU}} & 3'b011 | {3{`IS_LUI}} & 3'b100;		// 对于计算类指令是func3，对于B指令是010，BU是011，LUI是100

assign	ls_load			=	opcode == OPCODE_LOAD;
assign	ls_store		=	opcode == OPCODE_STORE;
assign	ls_type			=	func3;

assign	is_jump			=	opcode == OPCODE_JAL | opcode == OPCODE_JALR;
assign	is_jalr			=	opcode == OPCODE_JALR;
assign	is_branch		=	opcode == OPCODE_BRANCH;
assign	branch_cond		=	{func3[2], func3[0]};

assign	csr_ecall		=	`IS_SYS & func3 == 3'b0 & inst[31:20] == 12'b0;
assign	csr_mret		=	`IS_SYS & inst[31:20] == 12'h18;
assign	csr_wen			=	`IS_SYS & |func3;
assign	csr_cmd			=	func3[0];		// 不严谨，权宜之计, 表述rs1直接写入

assign	ifence			=	`IS_FENCE;	// 权宜之计



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






