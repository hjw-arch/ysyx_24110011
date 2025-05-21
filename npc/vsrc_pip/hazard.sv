module hazard(
	input	[4:0]	id2ex_rs1_addr,
	input 	[4:0]	id2ex_rs2_addr,

	input 	[4:0]	ex2ls_rd_addr,
	input 	[4:0]	ls2wb_rd_addr,

	output 			hazard_valid
);

assign	hazard_valid	=	id2ex_rs1_addr == ex2ls_rd_addr | id2ex_rs1_addr == ls2wb_rd_addr | id2ex_rs2_addr == ex2ls_rd_addr | id2ex_rs2_addr == ls2wb_rd_addr;
	
endmodule //moduleName
