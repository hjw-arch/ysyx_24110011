module WBU(
	input			clk,

	input	[4:0]	rs1_addr,
	input 	[4:0]	rs2_addr,
	output 	[31:0]	rs1_data,
	output 	[31:0]	rs2_data,

	input 			valid_i,
	input	[37:0]	data_i,
	output 			ready_o
);

// 解码
wire [31:0]	rd_data		=	data_i[37:6];
wire		is_load		=	data_i[5];		// 给旁路使用
wire [4:0]  rd_addr		=	data_i[4:0];


// 状态机
assign	ready_o	=	1'b1;		// WBU收到命令就可以直接写入


registerfile u_registerfile(
	.clk      	(clk       ),
	.wen      	(valid_i   ),
	.rd_addr  	(rd_addr   ),
	.rd_data  	(rd_data   ),
	.rs1_addr 	(rs1_addr  ),
	.rs1_data 	(rs1_data  ),
	.rs2_addr 	(rs2_addr  ),
	.rs2_data 	(rs2_data  )
);



	
endmodule 



