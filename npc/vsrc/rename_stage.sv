// 重命名阶段（Rename Stage）
//
// 单发射数据通路：RAT 查询、物理寄存器分配、Busy 查询、ROB/IQ 分派。
// 恢复采用四份分布式稀疏快照：RAT 与 FreeList 各自在同一槽保存状态，
// Rename 只维护槽有效位和 ROB 标签。误预测命中最近旧快照后，按 ROB
// 顺序重放两者之间的目的寄存器映射；未命中则从提交态开始重放。

`include "./include/pipeline_pkt_pkg.sv"

module rename_stage
import pipeline_pkt_pkg::*;
#(
    parameter int SNAPSHOT_PERIOD = 4
) (
    input                       clk,
    input                       rst,

    input                       decode_valid_i,
    input   decode_pkt_t        decode_pkt_i,
    output                      decode_ready_o,

    output                      dispatch_valid_o,
    output  rename2issue_pkt_t  dispatch_pkt_o,
    input                       dispatch_ready_i,

    input       [4:0]           rob_alloc_idx_i,
    input                       rob_ready_i,
    output                      rob_alloc_en_o,
    output  rob_alloc_pkt_t     rob_alloc_pkt_o,

    input       [4:0]           rob_head_idx_i,
    output      [4:0]           rob_walk_idx_o,
    input                       rob_walk_valid_i,
    input                       rob_walk_rd_wen_i,
    input       [4:0]           rob_walk_arch_rd_i,
    input       [5:0]           rob_walk_phys_rd_i,

    input                       commit_valid_i,
    input       [4:0]           commit_arch_rd_i,
    input       [5:0]           commit_phys_rd_i,
    input       [5:0]           commit_preg_old_i,
    input                       commit_rd_wen_i,

    input                       wakeup_en1_i,
    input       [5:0]           wakeup_preg1_i,
    input                       wakeup_en2_i,
    input       [5:0]           wakeup_preg2_i,

    input       [4:0]           branch_recover_idx_i,
    input                       branch_recover_i,
    output                      recover_busy_o,

    input                       flush_i
);

localparam int NUM_SNAPSHOTS       = 4;
localparam int SNAPSHOT_SLOT_WIDTH = $clog2(NUM_SNAPSHOTS);
localparam int SNAPSHOT_GAP_WIDTH  = $clog2(SNAPSHOT_PERIOD + 1);
localparam int SNAPSHOT_GAP_LIMIT  = SNAPSHOT_PERIOD - 1;

logic [NUM_SNAPSHOTS-1:0] snapshot_valid;
logic [4:0] snapshot_tag [0:NUM_SNAPSHOTS-1];
logic [SNAPSHOT_GAP_WIDTH-1:0] snapshot_gap;

logic       recover_busy;
logic [4:0] walk_idx;
logic [4:0] walk_remaining;

wire [4:0] rs1_arch = decode_pkt_i.inst[19:15];
wire [4:0] rs2_arch = decode_pkt_i.inst[24:20];
wire [4:0] rd_arch  = decode_pkt_i.inst[11:7];

wire [5:0] rs1_phys;
wire [5:0] rs2_phys;
wire [5:0] rd_phys_old;
wire [5:0] rd_phys_new;
wire       freelist_valid;
wire       rs1_ready_bt;
wire       rs2_ready_bt;

// ── 四项快照槽分配：最低空闲槽，结构是固定的四级优先选择 ──
wire [NUM_SNAPSHOTS-1:0] snapshot_free_vec = ~snapshot_valid;
wire                      snapshot_has_free = |snapshot_free_vec;
wire [SNAPSHOT_SLOT_WIDTH-1:0] snapshot_free_slot =
    snapshot_free_vec[0] ? SNAPSHOT_SLOT_WIDTH'(0) :
    snapshot_free_vec[1] ? SNAPSHOT_SLOT_WIDTH'(1) :
    snapshot_free_vec[2] ? SNAPSHOT_SLOT_WIDTH'(2) :
                           SNAPSHOT_SLOT_WIDTH'(3);

wire snapshot_due = ~(|snapshot_valid)
                  | (snapshot_gap == SNAPSHOT_GAP_WIDTH'(SNAPSHOT_GAP_LIMIT));
wire snapshot_en = dispatch_valid_o & snapshot_has_free & snapshot_due;

// ── 恢复点选择：四个 ROB 距离比较，选择离误预测分支最近的旧快照 ──
wire [4:0] recover_distance0 = branch_recover_idx_i - snapshot_tag[0];
wire [4:0] recover_distance1 = branch_recover_idx_i - snapshot_tag[1];
wire [4:0] recover_distance2 = branch_recover_idx_i - snapshot_tag[2];
wire [4:0] recover_distance3 = branch_recover_idx_i - snapshot_tag[3];

wire recover_eligible0 = snapshot_valid[0] & ~recover_distance0[4];
wire recover_eligible1 = snapshot_valid[1] & ~recover_distance1[4];
wire recover_eligible2 = snapshot_valid[2] & ~recover_distance2[4];
wire recover_eligible3 = snapshot_valid[3] & ~recover_distance3[4];

wire recover_pick1 = recover_eligible1
                   & (~recover_eligible0 | (recover_distance1 < recover_distance0));
wire recover_pick3 = recover_eligible3
                   & (~recover_eligible2 | (recover_distance3 < recover_distance2));

wire recover_pair01_hit = recover_eligible0 | recover_eligible1;
wire recover_pair23_hit = recover_eligible2 | recover_eligible3;
wire [SNAPSHOT_SLOT_WIDTH-1:0] recover_pair01_slot = recover_pick1 ? 2'd1 : 2'd0;
wire [SNAPSHOT_SLOT_WIDTH-1:0] recover_pair23_slot = recover_pick3 ? 2'd3 : 2'd2;
wire [4:0] recover_pair01_distance = recover_pick1
    ? recover_distance1
    : recover_distance0;
wire [4:0] recover_pair23_distance = recover_pick3
    ? recover_distance3
    : recover_distance2;

wire recover_pick23 = recover_pair23_hit
                    & (~recover_pair01_hit
                       | (recover_pair23_distance < recover_pair01_distance));
wire recover_snapshot_hit = recover_pair01_hit | recover_pair23_hit;
wire [SNAPSHOT_SLOT_WIDTH-1:0] recover_snapshot_slot = recover_pick23
    ? recover_pair23_slot
    : recover_pair01_slot;
wire [4:0] recover_snapshot_tag = snapshot_tag[recover_snapshot_slot];

// 快照保存 tagged 指令重命名完成后的状态，因此从 tag+1 开始 Walk。
// 无快照时从 ROB head 开始；若 head 同拍提交，则从下一项开始。
wire [4:0] recover_walk_start = recover_snapshot_hit
    ? recover_snapshot_tag + 5'd1
    : rob_head_idx_i + 5'(commit_valid_i);
wire [4:0] recover_walk_count = recover_snapshot_hit
    ? branch_recover_idx_i - recover_snapshot_tag
    : branch_recover_idx_i - rob_head_idx_i + 5'd1 - 5'(commit_valid_i);

assign rob_walk_idx_o = walk_idx;
assign recover_busy_o = recover_busy;

wire walk_update_en = recover_busy & rob_walk_valid_i & rob_walk_rd_wen_i;

// ── RAT / FreeList / BusyTable ──
rename_map_table #(
    .NUM_SNAPSHOTS (NUM_SNAPSHOTS)
) u_map_table (
    .clk                       (clk),
    .rst                       (rst),
    .rs1_arch_i                (rs1_arch),
    .rs2_arch_i                (rs2_arch),
    .rd_arch_i                 (rd_arch),
    .rs1_phys_o                (rs1_phys),
    .rs2_phys_o                (rs2_phys),
    .rd_phys_old_o             (rd_phys_old),
    .update_en_i               (dispatch_valid_o & decode_pkt_i.rd_wen),
    .update_arch_i             (rd_arch),
    .update_phys_i             (rd_phys_new),
    .commit_en_i               (commit_valid_i & commit_rd_wen_i),
    .commit_arch_i             (commit_arch_rd_i),
    .commit_phys_i             (commit_phys_rd_i),
    .snapshot_en_i             (snapshot_en),
    .snapshot_slot_i           (snapshot_free_slot),
    .recover_en_i              (branch_recover_i),
    .recover_snapshot_hit_i    (recover_snapshot_hit),
    .recover_snapshot_slot_i   (recover_snapshot_slot),
    .walk_en_i                 (walk_update_en),
    .walk_arch_i               (rob_walk_arch_rd_i),
    .walk_phys_i               (rob_walk_phys_rd_i),
    .flush_i                   (flush_i)
);

freelist #(
    .NUM_SNAPSHOTS (NUM_SNAPSHOTS)
) u_freelist (
    .clk                       (clk),
    .rst                       (rst),
    .alloc_req_i               (dispatch_valid_o & decode_pkt_i.rd_wen),
    .alloc_valid_o             (freelist_valid),
    .alloc_preg_o              (rd_phys_new),
    .commit_en_i               (commit_valid_i & commit_rd_wen_i),
    .commit_preg_new_i         (commit_phys_rd_i),
    .commit_preg_old_i         (commit_preg_old_i),
    .snapshot_en_i             (snapshot_en),
    .snapshot_slot_i           (snapshot_free_slot),
    .recover_en_i              (branch_recover_i),
    .recover_snapshot_hit_i    (recover_snapshot_hit),
    .recover_snapshot_slot_i   (recover_snapshot_slot),
    .walk_en_i                 (walk_update_en),
    .walk_preg_i               (rob_walk_phys_rd_i),
    .flush_i                   (flush_i)
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
    .clear_busy_en1_i   (wakeup_en1_i),
    .clear_busy_preg1_i (wakeup_preg1_i),
    .clear_busy_en2_i   (wakeup_en2_i),
    .clear_busy_preg2_i (wakeup_preg2_i),
    .flush_i            (flush_i)
);

// ── 快照目录与恢复 Walk 状态 ──
function automatic logic is_younger(
    input logic [4:0] candidate,
    input logic [4:0] reference
);
    logic [4:0] distance;
    begin
        distance   = candidate - reference;
        is_younger = (distance != 5'd0) & ~distance[4];
    end
endfunction

always_ff @(posedge clk) begin
    if (rst) begin
        snapshot_valid <= '0;
        snapshot_gap   <= '0;
        recover_busy   <= 1'b0;
        walk_idx       <= '0;
        walk_remaining <= '0;
    end else if (flush_i) begin
        snapshot_valid <= '0;
        snapshot_gap   <= '0;
        recover_busy   <= 1'b0;
        walk_idx       <= '0;
        walk_remaining <= '0;
    end else begin
        if (commit_valid_i) begin
            for (int i = 0; i < NUM_SNAPSHOTS; i++) begin
                if (snapshot_valid[i] && (snapshot_tag[i] == rob_head_idx_i))
                    snapshot_valid[i] <= 1'b0;
            end
        end

        if (branch_recover_i) begin
            for (int i = 0; i < NUM_SNAPSHOTS; i++) begin
                if (snapshot_valid[i]
                        && is_younger(snapshot_tag[i], branch_recover_idx_i))
                    snapshot_valid[i] <= 1'b0;
            end

            snapshot_gap   <= SNAPSHOT_GAP_WIDTH'(SNAPSHOT_GAP_LIMIT);
            recover_busy   <= |recover_walk_count;
            walk_idx       <= recover_walk_start;
            walk_remaining <= recover_walk_count;
        end else if (recover_busy) begin
            walk_idx       <= walk_idx + 5'd1;
            walk_remaining <= walk_remaining - 5'd1;
            if (walk_remaining == 5'd1)
                recover_busy <= 1'b0;
        end

        if (snapshot_en) begin
            snapshot_valid[snapshot_free_slot] <= 1'b1;
            snapshot_tag[snapshot_free_slot]   <= rob_alloc_idx_i;
            snapshot_gap                       <= '0;
        end else if (dispatch_valid_o
                && (snapshot_gap != SNAPSHOT_GAP_WIDTH'(SNAPSHOT_GAP_LIMIT))) begin
            snapshot_gap <= snapshot_gap + SNAPSHOT_GAP_WIDTH'(1);
        end
    end
end

// ── 查询就绪与分派握手 ──
wire rs1_wakeup_bypass = (wakeup_en1_i & (wakeup_preg1_i == rs1_phys))
                       | (wakeup_en2_i & (wakeup_preg2_i == rs1_phys));
wire rs2_wakeup_bypass = (wakeup_en1_i & (wakeup_preg1_i == rs2_phys))
                       | (wakeup_en2_i & (wakeup_preg2_i == rs2_phys));

wire rs1_ready = !decode_pkt_i.rs1_used | rs1_ready_bt | rs1_wakeup_bypass;
wire rs2_ready = !decode_pkt_i.rs2_used | rs2_ready_bt | rs2_wakeup_bypass;

wire can_proceed = dispatch_ready_i & rob_ready_i
                 & (!decode_pkt_i.rd_wen | freelist_valid)
                 & ~flush_i & ~branch_recover_i & ~recover_busy;

assign decode_ready_o   = can_proceed;
assign dispatch_valid_o = decode_valid_i & can_proceed;

// ── 分派包 ──
assign dispatch_pkt_o.pc         = decode_pkt_i.pc;
assign dispatch_pkt_o.funct3     = decode_pkt_i.inst[14:12];
assign dispatch_pkt_o.pred_taken = decode_pkt_i.pred_taken;
assign dispatch_pkt_o.rob_idx    = rob_alloc_idx_i;
assign dispatch_pkt_o.phys_rs1   = rs1_phys;
assign dispatch_pkt_o.phys_rs2   = rs2_phys;
assign dispatch_pkt_o.phys_rd    = decode_pkt_i.rd_wen ? rd_phys_new : 6'd0;
assign dispatch_pkt_o.rd_wen     = decode_pkt_i.rd_wen;
assign dispatch_pkt_o.rs1_ready  = rs1_ready;
assign dispatch_pkt_o.rs2_ready  = rs2_ready;
assign dispatch_pkt_o.ex         = decode_pkt_i.ex;
assign dispatch_pkt_o.mem        = decode_pkt_i.mem;
assign dispatch_pkt_o.sys        = decode_pkt_i.sys;
assign dispatch_pkt_o.imm        = decode_pkt_i.imm;

// ── ROB 分配包 ──
assign rob_alloc_en_o              = dispatch_valid_o;
assign rob_alloc_pkt_o.pc          = decode_pkt_i.pc;
assign rob_alloc_pkt_o.inst        = decode_pkt_i.inst;
assign rob_alloc_pkt_o.arch_rd     = rd_arch;
assign rob_alloc_pkt_o.phys_rd     = decode_pkt_i.rd_wen ? rd_phys_new : 6'd0;
assign rob_alloc_pkt_o.phys_rd_old = rd_phys_old;
assign rob_alloc_pkt_o.rd_wen      = decode_pkt_i.rd_wen;
assign rob_alloc_pkt_o.is_store    = decode_pkt_i.mem.cmd == MEM_STORE;
assign rob_alloc_pkt_o.sys         = decode_pkt_i.sys;

endmodule
