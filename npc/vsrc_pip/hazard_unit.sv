`include "./include/pipeline_pkt_pkg.sv"

module hazard_unit
import pipeline_pkt_pkg::*;
(
	input	[4:0]		id_rs1_addr,
	input 	[4:0]		id_rs2_addr,
	input				id_rs1_used,
	input				id_rs2_used,

	input 	[4:0]		ex_rd_addr,
	input				ex_is_load,
	input				ex_is_csr,

	input 	[4:0]		ls_rd_addr,
	input				ls_is_csr,
	input				ls_can_wb,

	output	fwd_sel_t	fwd_rs1_sel,
	output	fwd_sel_t	fwd_rs2_sel,
	output 				hazard_valid
);

// 前递选择按“下一拍消费者进入 EX 时生产者所在的位置”编码：
//   - 当前 EX 的 ALU/JAL/LUI 结果，下一拍在 LS，选择 LS 前递；
//   - 当前 LS 的普通可提交结果，下一拍在 WB，选择 WB packet 的 result；
//   - CSR 结果不走前递，等到 WB 后由寄存器堆同拍读写 bypass 吸收。
wire ex_can_forward = ~(ex_is_load | ex_is_csr);
wire ls_can_forward = ls_can_wb & ~ls_is_csr;

wire rs1_hit_ex = id_rs1_used & (id_rs1_addr == ex_rd_addr);
wire rs2_hit_ex = id_rs2_used & (id_rs2_addr == ex_rd_addr);
wire rs1_hit_ls = id_rs1_used & (id_rs1_addr == ls_rd_addr);
wire rs2_hit_ls = id_rs2_used & (id_rs2_addr == ls_rd_addr);

// EX 阶段的 load/CSR 还拿不到真正写回值，必须阻塞。
// LS 阶段如果还不能在本拍进入 WB，或者是 CSR 指令，也必须阻塞。
wire rs1_block_ex = rs1_hit_ex & ~ex_can_forward;
wire rs2_block_ex = rs2_hit_ex & ~ex_can_forward;
wire rs1_block_ls = ~rs1_hit_ex & rs1_hit_ls & ~ls_can_forward;
wire rs2_block_ls = ~rs2_hit_ex & rs2_hit_ls & ~ls_can_forward;

assign hazard_valid = rs1_block_ex | rs2_block_ex | rs1_block_ls | rs2_block_ls;

assign fwd_rs1_sel = rs1_hit_ex & ex_can_forward ? FWD_SEL_LS :
					 ~rs1_hit_ex & rs1_hit_ls & ls_can_forward ? FWD_SEL_WB :
					 FWD_SEL_RF;

assign fwd_rs2_sel = rs2_hit_ex & ex_can_forward ? FWD_SEL_LS :
					 ~rs2_hit_ex & rs2_hit_ls & ls_can_forward ? FWD_SEL_WB :
					 FWD_SEL_RF;

endmodule
