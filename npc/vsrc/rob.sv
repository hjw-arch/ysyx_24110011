// 重排序缓冲（Reorder Buffer）
// 维护程序序，支持乱序完成、顺序提交、精确异常和分支误预测恢复
// 循环队列，16 项，单发射单提交
// 双路 complete：EXU 与 LSU 可同拍写回
// store 提交需 store_commit_ready_i（SQ drain 完成）

`include "./include/pipeline_pkt_pkg.sv"

module rob
import pipeline_pkt_pkg::*;
#(
    parameter int ROB_SIZE = 16
)(
    input               clk,
    input               rst,

    // ── 分配接口（Rename/Dispatch 阶段）──
    input               alloc_en_i,
    input   rob_alloc_pkt_t alloc_pkt_i,
    output      [4:0]   alloc_idx_o,
    output              alloc_ready_o,

    // ── 完成接口（双路：EXU / LSU）──
    input               complete_en1_i,
    input       [4:0]   complete_idx1_i,
    input       [31:0]  complete_data1_i,
    input               complete_exception1_i,
    input       [3:0]   complete_cause1_i,

    input               complete_en2_i,
    input       [4:0]   complete_idx2_i,
    input       [31:0]  complete_data2_i,
    input               complete_exception2_i,
    input       [3:0]   complete_cause2_i,

    // 分支误预测在执行级立即恢复：保留分支及更老项，只清除年轻项。
    input               branch_recover_valid_i,
    input       [4:0]   branch_recover_idx_i,

    // 稀疏快照恢复期间，Rename 顺序读取保留项并重放映射。
    input               recover_stall_i,
    input       [4:0]   recover_walk_idx_i,
    output              recover_walk_valid_o,
    output              recover_walk_rd_wen_o,
    output      [4:0]   recover_walk_arch_rd_o,
    output      [5:0]   recover_walk_phys_rd_o,

    // ── store 提交握手（SQ drain）──
    // head 为 store 且无异常时，需 SQ 完成 AXI 写才可 commit/flush 退休
    input               store_commit_ready_i,
    input               store_commit_fault_i, // drain 总线错误 → 精确异常
    output              store_commit_req_o, // head 是待 drain 的 store
    output      [4:0]   store_commit_rob_idx_o,

    // ── 提交接口（有序提交）──
    output              commit_valid_o,
    output  rob_commit_t    commit_pkt_o,

    // ── 异常提交观测（!commit_valid 但 head 异常退休）──
    output              exc_commit_valid_o,
    output      [3:0]   exc_commit_cause_o,
    output      [31:0]  exc_commit_pc_o,

    // ── 刷新接口──
    output              flush_o,
    output      [31:0]  flush_pc_o,

    // ── 当前 head（供 IQ 年龄比较）──
    output      [4:0]   head_idx_o
);

typedef struct packed {
    logic           valid;
    logic           complete;
    rob_idx_t       rob_idx;
    logic   [31:0]  pc;
    logic   [31:0]  inst;
    logic   [4:0]   arch_rd;
    phys_reg_t      phys_rd;
    phys_reg_t      phys_rd_old;
    logic   [31:0]  result;
    logic           rd_wen;
    logic           is_store;
    logic           exception;
    logic   [3:0]   exception_cause;
    sys_ctrl_t      sys;
} rob_entry_t;

rob_entry_t rob_q [0:ROB_SIZE-1];

localparam int SLOT_WIDTH = $clog2(ROB_SIZE);

// sequence ID 保持 5 位供 IQ 做模 32 年龄比较，低位仅用于寻址 16 个存储槽。
logic [4:0] rob_head, rob_tail;
logic [5:0] rob_count;
wire [SLOT_WIDTH-1:0] rob_head_slot = rob_head[SLOT_WIDTH-1:0];
wire [SLOT_WIDTH-1:0] rob_tail_slot = rob_tail[SLOT_WIDTH-1:0];
wire [SLOT_WIDTH-1:0] recover_walk_slot = recover_walk_idx_i[SLOT_WIDTH-1:0];

assign head_idx_o = rob_head;

assign alloc_ready_o = (rob_count < ROB_SIZE[5:0]);
assign alloc_idx_o   = rob_tail;

assign recover_walk_valid_o = rob_q[recover_walk_slot].valid
                            & (rob_q[recover_walk_slot].rob_idx == recover_walk_idx_i);
assign recover_walk_rd_wen_o   = rob_q[recover_walk_slot].rd_wen;
assign recover_walk_arch_rd_o  = rob_q[recover_walk_slot].arch_rd;
assign recover_walk_phys_rd_o  = rob_q[recover_walk_slot].phys_rd;

// ── 提交条件 ──
wire head_valid    = rob_q[rob_head_slot].valid;
wire head_complete = rob_q[rob_head_slot].complete;
wire head_excpt    = rob_q[rob_head_slot].exception;
wire head_redir    = rob_q[rob_head_slot].sys.fence_i
                   | (rob_q[rob_head_slot].sys.priv_redir != PRIV_REDIR_NONE);
wire head_store    = rob_q[rob_head_slot].is_store;

// store 无异常：等 SQ drain；有异常则不写内存，直接处理异常
wire store_block = head_store & ~head_excpt & ~store_commit_ready_i;
wire head_ready  = head_valid & head_complete & ~store_block;
wire store_fault = head_store & store_commit_ready_i & store_commit_fault_i;
wire head_trap   = head_excpt | store_fault;

assign store_commit_req_o     = head_valid & head_complete & head_store
                              & ~head_excpt & ~recover_stall_i;
assign store_commit_rob_idx_o = rob_head;

// 正常提交（含 store drain 完成且无 fault）
assign commit_valid_o = head_ready & ~head_trap & ~recover_stall_i;

assign commit_pkt_o.arch_rd     = rob_q[rob_head_slot].arch_rd;
assign commit_pkt_o.phys_rd     = rob_q[rob_head_slot].phys_rd;
assign commit_pkt_o.phys_rd_old = rob_q[rob_head_slot].phys_rd_old;
assign commit_pkt_o.result      = rob_q[rob_head_slot].result;
assign commit_pkt_o.rd_wen      = rob_q[rob_head_slot].rd_wen;
assign commit_pkt_o.sys         = rob_q[rob_head_slot].sys;
assign commit_pkt_o.pc          = rob_q[rob_head_slot].pc;
assign commit_pkt_o.inst        = rob_q[rob_head_slot].inst;

// 异常/特权跳转/fence.i 到达 head 时全局 flush；trap 目标由顶层覆盖。
assign flush_o    = head_ready & (head_trap | head_redir) & ~recover_stall_i;
assign flush_pc_o = rob_q[rob_head_slot].pc + 32'd4;

assign exc_commit_valid_o = head_ready & head_trap;
assign exc_commit_cause_o = head_excpt ? rob_q[rob_head_slot].exception_cause
                                       : CAUSE_STORE_ACCESS_FAULT;
assign exc_commit_pc_o    = rob_q[rob_head_slot].pc;

// 退休：正常 commit 或提交点全局 flush；执行级误预测不退休分支。
// 注意：flush 时整表清空，head 归零；仅 commit 时 head++
wire alloc_fire  = alloc_en_i & alloc_ready_o;
wire commit_fire = commit_valid_o; // flush 走整表清，不单独 head++
wire retire_fire = commit_fire | flush_o;

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

wire [4:0] recover_span = branch_recover_idx_i - rob_head + 5'd1;

always_ff @(posedge clk) begin
    if (rst) begin
        rob_head  <= '0;
        rob_tail  <= '0;
        rob_count <= '0;
        for (int i = 0; i < ROB_SIZE; i++)
            rob_q[i].valid <= 1'b0;
    end else if (flush_o) begin
        // 含 head 一起清空；head 指令的 CSR/trap 副作用在同拍由顶层完成
        rob_head  <= '0;
        rob_tail  <= '0;
        rob_count <= '0;
        for (int i = 0; i < ROB_SIZE; i++)
            rob_q[i].valid <= 1'b0;
    end else begin
        if (alloc_fire) begin
            rob_q[rob_tail_slot].valid           <= 1'b1;
            rob_q[rob_tail_slot].complete        <= 1'b0;
            rob_q[rob_tail_slot].rob_idx         <= rob_tail;
            rob_q[rob_tail_slot].pc              <= alloc_pkt_i.pc;
            rob_q[rob_tail_slot].inst            <= alloc_pkt_i.inst;
            rob_q[rob_tail_slot].arch_rd         <= alloc_pkt_i.arch_rd;
            rob_q[rob_tail_slot].phys_rd         <= alloc_pkt_i.phys_rd;
            rob_q[rob_tail_slot].phys_rd_old     <= alloc_pkt_i.phys_rd_old;
            rob_q[rob_tail_slot].rd_wen          <= alloc_pkt_i.rd_wen;
            rob_q[rob_tail_slot].is_store        <= alloc_pkt_i.is_store;
            rob_q[rob_tail_slot].exception       <= 1'b0;
            rob_q[rob_tail_slot].exception_cause <= '0;
            rob_q[rob_tail_slot].result          <= '0;
            rob_q[rob_tail_slot].sys             <= alloc_pkt_i.sys;
            rob_tail <= rob_tail + 5'd1;
        end

        if (complete_en1_i
                && (!branch_recover_valid_i
                    || !is_younger(complete_idx1_i, branch_recover_idx_i))) begin
            rob_q[complete_idx1_i[SLOT_WIDTH-1:0]].complete        <= 1'b1;
            rob_q[complete_idx1_i[SLOT_WIDTH-1:0]].result          <= complete_data1_i;
            rob_q[complete_idx1_i[SLOT_WIDTH-1:0]].exception       <= complete_exception1_i;
            rob_q[complete_idx1_i[SLOT_WIDTH-1:0]].exception_cause <= complete_cause1_i;
        end
        if (complete_en2_i
                && (!branch_recover_valid_i
                    || !is_younger(complete_idx2_i, branch_recover_idx_i))) begin
            rob_q[complete_idx2_i[SLOT_WIDTH-1:0]].complete        <= 1'b1;
            rob_q[complete_idx2_i[SLOT_WIDTH-1:0]].result          <= complete_data2_i;
            rob_q[complete_idx2_i[SLOT_WIDTH-1:0]].exception       <= complete_exception2_i;
            rob_q[complete_idx2_i[SLOT_WIDTH-1:0]].exception_cause <= complete_cause2_i;
        end

        if (commit_valid_o) begin
            rob_q[rob_head_slot].valid <= 1'b0;
            rob_head <= rob_head + 5'd1;
        end

        if (branch_recover_valid_i) begin
            for (int i = 0; i < ROB_SIZE; i++) begin
                if (rob_q[i].valid
                        && is_younger(rob_q[i].rob_idx, branch_recover_idx_i))
                    rob_q[i].valid <= 1'b0;
            end
            rob_tail  <= branch_recover_idx_i + 5'd1;
            rob_count <= {1'b0, recover_span} - 6'(commit_fire);
        end else begin
            rob_count <= rob_count + 6'(alloc_fire) - 6'(retire_fire);
        end
    end
end

endmodule
