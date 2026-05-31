module hazard_temp(
	input	[4:0]	id_rs1_addr,
	input 	[4:0]	id_rs2_addr,
	input			id_rs1_used,
	input			id_rs2_used,

	input 	[4:0]	ex_rd_addr,
	input 	[4:0]	ls_rd_addr,
	input	[4:0]	wb_rd_addr,

	output 			hazard_valid
);

// raw 地址比较与 used 解码并行，最后再用 used 门控。
// IDU 已经在 used 中处理 valid 和 x0，因此这里不再重复比较 rs!=0。
wire rs1_hit = (id_rs1_addr == ex_rd_addr) |
			   (id_rs1_addr == ls_rd_addr) |
			   (id_rs1_addr == wb_rd_addr);

wire rs2_hit = (id_rs2_addr == ex_rd_addr) |
			   (id_rs2_addr == ls_rd_addr) |
			   (id_rs2_addr == wb_rd_addr);

assign	hazard_valid	=	(id_rs1_used & rs1_hit) |
							(id_rs2_used & rs2_hit);

endmodule //moduleName
