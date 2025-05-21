`include "define.svh"

module IDU (
    input 			clk,
    input			rst,

    output	[4:0] 	rs1_addr,
    output	[4:0] 	rs2_addr,
    input 	[31:0] 	rs1_data,
    input	[31:0] 	rs2_data,

	input 			hazard,
	input			flush,

    input			valid_i,
    input	[63:0] 	data_i,
    output			ready_o,

	output			valid_o,
	output	[174:0]	data_o,
	input 			ready_i
);

`define HANDSHAKE 		valid_o & ready_i;


logic [31:0] inst	=	data_i[63:32];
logic [31:0] pc		=	data_i[31:0];


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
logic		 is_fencei;



logic state, nstate;
always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : nstate;
end

assign nstate = valid_o & ~ready_i;

assign valid_o = valid_i & ~flush & ~hazard | state;
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
assign	alu_src_sel[1]  	=	(opcode == OPCODE_LUI | opcode == OPCODE_JAL | opcode == OPCODE_JALR);	// 0: rs1 1: pc
assign	alu_src_sel[0]  	=	(opcode == OPCODE_AUIPC | opcode == OPCODE_CAL_I | opcode == OPCODE_LOAD | opcode == OPCODE_STORE);	// 0: rs2, 1: imm	
assign	rd_wen				=	opcode != OPCODE_STORE & opcode != OPCODE_BRANCH;
assign	rs1_addr_hazard 	=	(opcode != OPCODE_SYS | opcode != OPCODE_JAL | opcode != OPCODE_LUI | opcode != OPCODE_AUIPC) ? 5'b0 : rs1_addr;	
assign	rs2_addr_hazard 	=	(opcode == OPCODE_CAL_R | opcode == OPCODE_BRANCH) ? rs2_addr : 5'b0;
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

assign	is_fencei		=	`IS_FENCE;	// 权宜之计



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






