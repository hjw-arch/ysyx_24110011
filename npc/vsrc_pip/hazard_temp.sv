module hazard_temp(
	input	[4:0]	id_rs1_addr,
	input 	[4:0]	id_rs2_addr,

	input 	[4:0]	ex_rd_addr,
	input 	[4:0]	ls_rd_addr,
	input	[4:0]	wb_rd_addr,

	output 			hazard_valid
);

assign	hazard_valid	=	(id_rs1_addr == ex_rd_addr | id_rs1_addr == ls_rd_addr | id_rs1_addr == wb_rd_addr) & (id_rs1_addr != 5'b0) |
							(id_rs2_addr == ex_rd_addr | id_rs2_addr == ls_rd_addr | id_rs2_addr == wb_rd_addr) & (id_rs2_addr != 5'b0);
	
endmodule //moduleName
