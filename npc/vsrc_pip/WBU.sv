module WBU
import pipeline_pkt_pkg::*;
(
	input				clk,

	input	[4:0]		rs1_addr,
	input 	[4:0]		rs2_addr,
	output 	[31:0]		rs1_data,
	output 	[31:0]		rs2_data,

	output	[4:0]		rd_addr_hazard,

	input 				valid_i,
	input	ls2wb_pkt_t	data_i,
	output 				ready_o
);

/*
typedef struct packed {
    logic   [31:0]  result;
    logic   [4:0]   rd_addr;
    logic           is_load;
} ls2wb_pkt_t;
*/

// 解码
wire [31:0]	rd_data		=	data_i.result;
wire		is_load		=	data_i.is_load;		// 给旁路使用
wire [4:0]  rd_addr		=	data_i.rd_addr;


// 状态机
assign	ready_o	=	1'b1;		// WBU收到命令就可以直接写入

assign	rd_addr_hazard = rd_addr & {5{valid_i}};

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



