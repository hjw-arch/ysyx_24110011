module EXU
import pipeline_pkt_pkg::*;
(
	input				clk,
	input 				rst,

	output 	[31:0]		pc_target,
	output 				flush,
	output 	[4:0]		rd_addr_hazard,

	input 				valid_i,
	input	id2ex_pkt_t	data_i,
	output 				ready_o,

	output 				valid_o,
	output 	ex2ls_pkt_t	data_o,
	input				ready_i
);

// input
// data_i解码
wire [3:0]		alu_op			=	data_i.alu_op;
wire [1:0]		alu_src_sel		=	data_i.alu_src_sel;
wire [31:0]		rs1_data		=	data_i.rs1_data;
wire [31:0]		rs2_data		=	data_i.rs2_data;
wire [31:0]		pc				=	data_i.pc;
wire [31:0]		imm				=	data_i.imm;
wire			is_jump			=	data_i.is_jump;
wire			is_jalr			=	data_i.is_jalr;
wire			is_branch		=	data_i.is_branch;
wire [1:0]		branch_cond		=	data_i.branch_cond;
wire			csr_wen			=	data_i.csr_wen;
wire			csr_cmd			=	data_i.csr_cmd;
wire			csr_ecall		=	data_i.csr_ecall;
wire			csr_mret		=	data_i.csr_mret;
wire [11:0]		csr_addr		=	data_i.csr_addr;
wire [4:0]		rd_addr			=	data_i.rd_addr;


// 状态机
logic	state, nstate;

always_ff @(posedge clk) begin
	state <= rst ? 1'b0 : nstate;
end

assign nstate	=	valid_o & ~ready_i;

assign valid_o	=	valid_i | state;
assign ready_o	=	ready_i;

// 筛选
logic [31:0]	alu_src1, alu_src2;

always_comb begin
	unique case({alu_src_sel})
		2'b00: begin
			alu_src1 = rs1_data;
			alu_src2 = rs2_data;
		end 
		2'b01: begin
			alu_src1 = rs1_data;
			alu_src2 = imm;
		end 
		2'b10: begin
			alu_src1 = pc;
			alu_src2 = 32'h4;
		end 
		2'b11: begin
			alu_src1 = pc;
			alu_src2 = imm;
		end 
	endcase
end


logic [31:0]	alu_result;
logic 			alu_zf;

ALU u_ALU(
	.alu_op    	(alu_op     ),
	.data1     	(alu_src1   ),
	.data2     	(alu_src2   ),
	.result    	(alu_result ),
	.zero_flag 	(alu_zf     )
);


logic [31:0] csr_rdata;
logic [31:0] csr_mtvec;
logic [31:0] csr_mepc;

CSR u_CSR(
	.clk        	(clk      	),
	.rst        	(rst      	),
	.wen        	(csr_wen    ),
	.cmd        	(csr_cmd    ),
	.ecall	 		(csr_ecall	),
	.addr       	(csr_addr   ),
	.sdata      	(rs1_data   ),
	.pc         	(pc       	),
	.rdata      	(csr_rdata  ),
	.mtvec      	(csr_mtvec  ),
	.mepc       	(csr_mepc   )
);

logic [31:0]	exu_result;
assign			exu_result = csr_wen ? csr_rdata : alu_result;


// output

// assign data_o = {exu_result, rs2_data, rest_data};
assign data_o.result	=	exu_result;
assign data_o.rs2_data	=	rs2_data;
assign data_o.ls_store	=	data_i.ls_store;
assign data_o.ls_load	=	data_i.ls_load;
assign data_o.ls_type	=	data_i.ls_type;
assign data_o.rd_addr	=	data_i.rd_addr;


// 计算真PC
logic [31:0] pc_src1, pc_cal_target;
assign pc_src1 = is_jalr ? rs1_data : pc;
assign pc_cal_target = pc_src1 + imm;


logic branch_valid;

always_comb begin
	case(branch_cond)
		2'b00: branch_valid = alu_zf;
		2'b01: branch_valid = ~alu_zf;
		2'b10: branch_valid = alu_result[0];
		2'b11: branch_valid = ~alu_result[0];
	endcase
end

logic [31:0] pc_target_temp;
always_comb begin
	unique case({csr_ecall, csr_mret})
		2'b01: pc_target_temp = csr_mepc;
		2'b10: pc_target_temp = csr_mtvec;
		default: pc_target_temp = pc_cal_target;
	endcase
end

assign pc_target = pc_target_temp;

assign	flush = is_jump & valid_i | is_branch & branch_valid & valid_i | csr_ecall & valid_i | csr_mret & valid_i;

assign rd_addr_hazard = rd_addr & {5{valid_i | state}};

endmodule
