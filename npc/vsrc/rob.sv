// 重排序缓冲（Reorder Buffer）
// 维护程序序，支持乱序完成、顺序提交、精确异常和分支误预测恢复
// 循环队列，32 项，单发射单提交
// 双路 complete：EXU 与 LSU 可同拍写回
// store 提交需 store_commit_ready_i（SQ drain 完成）

`include "./include/pipeline_pkt_pkg.sv"

module rob
import pipeline_pkt_pkg::*;
#(
    parameter int ROB_SIZE = 32
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
    input               complete_redirect_valid1_i,
    input       [31:0]  complete_redirect_addr1_i,

    input               complete_en2_i,
    input       [4:0]   complete_idx2_i,
    input       [31:0]  complete_data2_i,
    input               complete_exception2_i,
    input       [3:0]   complete_cause2_i,
    input               complete_redirect_valid2_i,
    input       [31:0]  complete_redirect_addr2_i,

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
    logic           redirect_valid;
    logic   [31:0]  redirect_addr;
    sys_ctrl_t      sys;
} rob_entry_t;

rob_entry_t rob_q [0:ROB_SIZE-1];

logic [4:0] rob_head, rob_tail;
logic [5:0] rob_count;

assign head_idx_o = rob_head;

assign alloc_ready_o = (rob_count < ROB_SIZE[5:0]);
assign alloc_idx_o   = rob_tail;

// ── 提交条件 ──
wire head_valid    = rob_q[rob_head].valid;
wire head_complete = rob_q[rob_head].complete;
wire head_excpt    = rob_q[rob_head].exception;
wire head_redir    = rob_q[rob_head].redirect_valid;
wire head_store    = rob_q[rob_head].is_store;

// store 无异常：等 SQ drain；有异常则不写内存，直接处理异常
wire store_block = head_store & ~head_excpt & ~store_commit_ready_i;
wire head_ready  = head_valid & head_complete & ~store_block;
wire store_fault = head_store & store_commit_ready_i & store_commit_fault_i;
wire head_trap   = head_excpt | store_fault;

assign store_commit_req_o     = head_valid & head_complete & head_store & ~head_excpt;
assign store_commit_rob_idx_o = rob_head;

// 正常提交（含 store drain 完成且无 fault）
assign commit_valid_o = head_ready & ~head_trap;

assign commit_pkt_o.valid       = commit_valid_o;
assign commit_pkt_o.arch_rd     = rob_q[rob_head].arch_rd;
assign commit_pkt_o.phys_rd     = rob_q[rob_head].phys_rd;
assign commit_pkt_o.phys_rd_old = rob_q[rob_head].phys_rd_old;
assign commit_pkt_o.result      = rob_q[rob_head].result;
assign commit_pkt_o.rd_wen      = rob_q[rob_head].rd_wen;
assign commit_pkt_o.is_store    = rob_q[rob_head].is_store;
assign commit_pkt_o.sys         = rob_q[rob_head].sys;
assign commit_pkt_o.redirect    = '0;
assign commit_pkt_o.pc          = rob_q[rob_head].pc;
assign commit_pkt_o.inst        = rob_q[rob_head].inst;

// 异常/误预测 head：flush；trap 目标由顶层用 mtvec 覆盖
assign flush_o    = head_ready & (head_trap | head_redir);
assign flush_pc_o = head_redir ? rob_q[rob_head].redirect_addr
                               : rob_q[rob_head].pc + 4;

assign exc_commit_valid_o = head_ready & head_trap;
assign exc_commit_cause_o = head_excpt ? rob_q[rob_head].exception_cause
                                       : CAUSE_STORE_ACCESS_FAULT;
assign exc_commit_pc_o    = rob_q[rob_head].pc;

// 退休：正常 commit 或 flush（异常/误预测 head 也前进）
// 注意：flush 时整表清空，head 归零；仅 commit 时 head++
wire alloc_fire  = alloc_en_i & alloc_ready_o;
wire commit_fire = commit_valid_o; // flush 走整表清，不单独 head++

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
            rob_q[rob_tail].valid           <= 1'b1;
            // 译码期异常：分配即 complete，到 head 直接 trap
            rob_q[rob_tail].complete        <= alloc_pkt_i.exception;
            rob_q[rob_tail].pc              <= alloc_pkt_i.pc;
            rob_q[rob_tail].inst            <= alloc_pkt_i.inst;
            rob_q[rob_tail].arch_rd         <= alloc_pkt_i.arch_rd;
            rob_q[rob_tail].phys_rd         <= alloc_pkt_i.phys_rd;
            rob_q[rob_tail].phys_rd_old     <= alloc_pkt_i.phys_rd_old;
            rob_q[rob_tail].rd_wen          <= alloc_pkt_i.rd_wen;
            rob_q[rob_tail].is_store        <= alloc_pkt_i.is_store;
            rob_q[rob_tail].exception       <= alloc_pkt_i.exception;
            rob_q[rob_tail].exception_cause <= alloc_pkt_i.exception_cause;
            rob_q[rob_tail].redirect_valid  <= 1'b0;
            rob_q[rob_tail].redirect_addr   <= '0;
            rob_q[rob_tail].result          <= '0;
            rob_q[rob_tail].sys             <= alloc_pkt_i.sys;
            rob_tail <= rob_tail + 5'd1;
        end

        if (complete_en1_i) begin
            rob_q[complete_idx1_i].complete        <= 1'b1;
            rob_q[complete_idx1_i].result          <= complete_data1_i;
            rob_q[complete_idx1_i].exception       <= complete_exception1_i;
            rob_q[complete_idx1_i].exception_cause <= complete_cause1_i;
            rob_q[complete_idx1_i].redirect_valid  <= complete_redirect_valid1_i;
            rob_q[complete_idx1_i].redirect_addr   <= complete_redirect_addr1_i;
        end
        if (complete_en2_i) begin
            rob_q[complete_idx2_i].complete        <= 1'b1;
            rob_q[complete_idx2_i].result          <= complete_data2_i;
            rob_q[complete_idx2_i].exception       <= complete_exception2_i;
            rob_q[complete_idx2_i].exception_cause <= complete_cause2_i;
            rob_q[complete_idx2_i].redirect_valid  <= complete_redirect_valid2_i;
            rob_q[complete_idx2_i].redirect_addr   <= complete_redirect_addr2_i;
        end

        if (commit_valid_o) begin
            rob_q[rob_head].valid <= 1'b0;
            rob_head <= rob_head + 5'd1;
        end

        rob_count <= rob_count + 6'(alloc_fire) - 6'(commit_fire | flush_o);
    end
end

endmodule
