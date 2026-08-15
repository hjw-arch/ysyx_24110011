// 重命名阶段（Rename Stage）
// 集成映射表、空闲列表、忙碌表，完成寄存器重命名
// 关键优化：若唤醒信号与分派同周期到达，直接在分派包里标记 rs_ready=1，
// 避免指令进队后无法被唤醒的竞争（busy_table 清除要到下拍才生效）。

`include "./include/pipeline_pkt_pkg.sv"

module rename_stage
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    // 来自 Decode 阶段
    input               decode_valid_i,
    input   decode_pkt_t    decode_pkt_i,
    output              decode_ready_o,

    // 到 Issue Queue
    output              dispatch_valid_o,
    output  rename2issue_pkt_t  dispatch_pkt_o,
    input               dispatch_ready_i,

    // ROB 接口
    input       [4:0]   rob_alloc_idx_i,
    input               rob_ready_i,
    output              rob_alloc_en_o,
    output  rob_alloc_pkt_t rob_alloc_pkt_o,

    // 提交接口（释放旧物理寄存器）
    input               commit_valid_i,
    input       [5:0]   commit_preg_old_i,

    // 唤醒接口（写回广播，同时用于分派时的 bypass 判断）
    input               wakeup_en_i,
    input       [5:0]   wakeup_preg_i,

    // 刷新
    input               flush_i
);

// ── 子模块输出信号 ──
wire [5:0] rs1_phys;
wire [5:0] rs2_phys;
wire [5:0] rd_phys_old;
wire [5:0] rd_phys_new;
wire       freelist_valid;
wire       rs1_ready_bt;    // 来自忙碌表的就绪状态（下拍才反映本拍写回）
wire       rs2_ready_bt;

// ── 子模块实例化 ──
rename_map_table u_map_table (
    .clk            (clk),
    .rst            (rst),
    .rs1_arch_i     (decode_pkt_i.rs1_arch),
    .rs2_arch_i     (decode_pkt_i.rs2_arch),
    .rd_arch_i      (decode_pkt_i.rd_arch),
    .rs1_phys_o     (rs1_phys),
    .rs2_phys_o     (rs2_phys),
    .rd_phys_old_o  (rd_phys_old),
    .update_en_i    (dispatch_valid_o & decode_pkt_i.rd_wen),
    .update_arch_i  (decode_pkt_i.rd_arch),
    .update_phys_i  (rd_phys_new),
    .flush_i        (flush_i)
);

freelist u_freelist (
    .clk            (clk),
    .rst            (rst),
    .alloc_req_i    (decode_valid_i & decode_pkt_i.rd_wen),
    .alloc_valid_o  (freelist_valid),
    .alloc_preg_o   (rd_phys_new),
    .free_en_i      (commit_valid_i),
    .free_preg_i    (commit_preg_old_i),
    .flush_i        (flush_i)
);

busy_table u_busy_table (
    .clk                (clk),
    .rst                (rst),
    .query_preg1_i      (rs1_phys),
    .query_preg2_i      (rs2_phys),
    .ready1_o           (rs1_ready_bt),
    .ready2_o           (rs2_ready_bt),
    .set_busy_en_i      (dispatch_valid_o & decode_pkt_i.rd_wen),
    .set_busy_preg_i    (rd_phys_new),
    .clear_busy_en_i    (wakeup_en_i),
    .clear_busy_preg_i  (wakeup_preg_i),
    .flush_i            (flush_i)
);

// ── wakeup bypass：若本拍写回恰好命中 rs1/rs2，直接标为就绪 ──
// busy_table 的 clear 要到下拍才生效，若新指令此时分派会看到旧的 busy 状态。
// 加 bypass 后可消除这一拍多余的等待。
wire rs1_wakeup_bypass = wakeup_en_i & (wakeup_preg_i == rs1_phys);
wire rs2_wakeup_bypass = wakeup_en_i & (wakeup_preg_i == rs2_phys);

wire rs1_ready = !decode_pkt_i.rs1_used | rs1_ready_bt | rs1_wakeup_bypass;
wire rs2_ready = !decode_pkt_i.rs2_used | rs2_ready_bt | rs2_wakeup_bypass;

// ── 流水线握手 ──
// 分派需要：IQ 未满 + ROB 未满 + 若需要写寄存器则空闲列表有空位
wire can_proceed = dispatch_ready_i & rob_ready_i &
                   (!decode_pkt_i.rd_wen | freelist_valid);

assign decode_ready_o   = can_proceed;
assign dispatch_valid_o = decode_valid_i & can_proceed;

// ── 组装分派包 ──
assign dispatch_pkt_o.pc        = decode_pkt_i.pc;
assign dispatch_pkt_o.inst      = decode_pkt_i.inst;
assign dispatch_pkt_o.rob_idx   = rob_alloc_idx_i;
assign dispatch_pkt_o.phys_rs1  = rs1_phys;
assign dispatch_pkt_o.phys_rs2  = rs2_phys;
assign dispatch_pkt_o.phys_rd   = decode_pkt_i.rd_wen ? rd_phys_new : 6'd0;
assign dispatch_pkt_o.rd_wen    = decode_pkt_i.rd_wen;
assign dispatch_pkt_o.rs1_ready = rs1_ready;
assign dispatch_pkt_o.rs2_ready = rs2_ready;
assign dispatch_pkt_o.ex        = decode_pkt_i.ex;
assign dispatch_pkt_o.mem       = decode_pkt_i.mem;
assign dispatch_pkt_o.sys       = decode_pkt_i.sys;
assign dispatch_pkt_o.imm       = decode_pkt_i.imm;

// ── 组装 ROB 分配包 ──
assign rob_alloc_en_o              = dispatch_valid_o;
assign rob_alloc_pkt_o.pc          = decode_pkt_i.pc;
assign rob_alloc_pkt_o.inst        = decode_pkt_i.inst;
assign rob_alloc_pkt_o.arch_rd     = decode_pkt_i.rd_arch;
assign rob_alloc_pkt_o.phys_rd     = decode_pkt_i.rd_wen ? rd_phys_new : 6'd0;
assign rob_alloc_pkt_o.phys_rd_old = rd_phys_old;
assign rob_alloc_pkt_o.rd_wen      = decode_pkt_i.rd_wen;
assign rob_alloc_pkt_o.sys         = decode_pkt_i.sys;

endmodule
