module EXU(
	input				clk,
	input 				rst,

	output 	[31:0]		pc_target,
	output 				flush,
	output 	[4:0]		rd_addr_hazard,

	input 				valid_i,
	input	[174:0]		data_i,
	output 				ready_o,

	output 				valid_o,
	output 	[73:0]		data_o,
	input				ready_i
);


// data_i解码
wire [3:0]		alu_op			=	data_i[174:171];
wire [1:0]		alu_src_sel		=	data_i[160:159];
wire [31:0]		rs1_data		=	data_i[158:127];
wire [31:0]		rs2_data		=	data_i[126:95];
wire [31:0]		pc				=	data_i[94:63];
wire [31:0]		imm				=	data_i[62:31];
wire			is_jump			=	data_i[30];
wire			is_jalr			=	data_i[29];
wire			is_branch		=	data_i[28];
wire [1:0]		branch_cond		=	data_i[27:26];
wire			csr_wen			=	data_i[25];
wire			csr_cmd			=	data_i[24];
wire			csr_ecall		=	data_i[23];
wire			csr_mret		=	data_i[22];
wire [11:0]		csr_addr		=	data_i[21:10];
wire [9:0]		rest_data		=	data_i[9:0];


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


// 传递给lsu
assign data_o = {exu_result, rs2_data, rest_data};


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

assign rd_addr_hazard = data_i[4:0] & {5{valid_i}};

endmodule
