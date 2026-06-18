`include "./include/pipeline_pkt_pkg.sv"

module hazard_unit
import pipeline_pkt_pkg::*;
(
	input	[4:0]		id_rs1_addr,
	input 	[4:0]		id_rs2_addr,
	input				id_rs1_used,
	input				id_rs2_used,

	input 	[4:0]		ex_rd_addr,

	input 	[4:0]		ls_rd_addr,

	output 				hazard_valid
);

wire rs1_hit_ex = id_rs1_used & (id_rs1_addr == ex_rd_addr);
wire rs2_hit_ex = id_rs2_used & (id_rs2_addr == ex_rd_addr);
wire rs1_hit_ls = id_rs1_used & (id_rs1_addr == ls_rd_addr);
wire rs2_hit_ls = id_rs2_used & (id_rs2_addr == ls_rd_addr);

// 无前递实验基线：
//   - 只要 ID 阶段读到的源寄存器命中 EX/LS 阶段将要写回的 rd，就阻塞；
//   - WB 阶段不阻塞，交给寄存器堆同拍写读 bypass 吸收。
//
// rs*_block_ls 保留“EX 优先”门控，避免同一个源寄存器同时命中 EX/LS 时重复归因。
wire rs1_block_ex /* verilator public_flat_rd */;
wire rs2_block_ex /* verilator public_flat_rd */;
wire rs1_block_ls /* verilator public_flat_rd */;
wire rs2_block_ls /* verilator public_flat_rd */;

assign rs1_block_ex = rs1_hit_ex;
assign rs2_block_ex = rs2_hit_ex;
assign rs1_block_ls = ~rs1_hit_ex & rs1_hit_ls;
assign rs2_block_ls = ~rs2_hit_ex & rs2_hit_ls;

assign hazard_valid = rs1_block_ex | rs2_block_ex | rs1_block_ls | rs2_block_ls;

endmodule
