// 重排序缓冲（Reorder Buffer）
// 维护程序序，支持乱序完成、顺序提交、精确异常和分支误预测恢复
// 循环队列，32 项，单发射单提交

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
    output      [4:0]   alloc_idx_o,    // 分配的 ROB 槽号
    output              alloc_ready_o,  // ROB 未满

    // ── 完成接口（Execute/LSU 写回）──
    input               complete_en_i,
    input       [4:0]   complete_idx_i,
    input       [31:0]  complete_data_i,
    input               complete_exception_i,
    input       [3:0]   complete_cause_i,
    input               complete_redirect_valid_i,  // 分支误预测
    input       [31:0]  complete_redirect_addr_i,

    // ── 提交接口（有序提交）──
    output              commit_valid_o,
    output  rob_commit_t    commit_pkt_o,

    // ── 刷新接口（提交时发现异常或分支误预测）──
    output              flush_o,
    output      [31:0]  flush_pc_o
);

// ROB 项
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
    logic           exception;
    logic   [3:0]   exception_cause;
    logic           redirect_valid;
    logic   [31:0]  redirect_addr;
    sys_ctrl_t      sys;
} rob_entry_t;

rob_entry_t rob_q [0:ROB_SIZE-1];

logic [4:0] rob_head, rob_tail;
logic [5:0] rob_count;  // 多一位，避免满判断溢出

// ── 分配逻辑（组合）──
assign alloc_ready_o = (rob_count < ROB_SIZE[5:0]);
assign alloc_idx_o   = rob_tail;

// ── 提交条件（组合）──
// 头部指令有效、已完成、无异常、无分支误预测
wire head_valid    = rob_q[rob_head].valid;
wire head_complete = rob_q[rob_head].complete;
wire head_excpt    = rob_q[rob_head].exception;
wire head_redir    = rob_q[rob_head].redirect_valid;

assign commit_valid_o = head_valid & head_complete & !head_excpt & !head_redir;

assign commit_pkt_o.valid       = commit_valid_o;
assign commit_pkt_o.arch_rd     = rob_q[rob_head].arch_rd;
assign commit_pkt_o.phys_rd_old = rob_q[rob_head].phys_rd_old;
assign commit_pkt_o.result      = rob_q[rob_head].result;
assign commit_pkt_o.rd_wen      = rob_q[rob_head].rd_wen;
assign commit_pkt_o.sys         = rob_q[rob_head].sys;
assign commit_pkt_o.redirect    = '0;

// ── 刷新：异常或分支误预测到达头部时触发 ──
assign flush_o  = head_valid & head_complete & (head_excpt | head_redir);
assign flush_pc_o = head_redir ? rob_q[rob_head].redirect_addr
                               : rob_q[rob_head].pc + 4; // 异常后续 PC 由 CSR/WBU 提供，此处暂简化

// ── 时序逻辑 ──
wire alloc_fire  = alloc_en_i & alloc_ready_o;
wire commit_fire = commit_valid_o | flush_o;  // 无论正常提交还是刷新，头指针前进

always_ff @(posedge clk) begin
    if (rst) begin
        rob_head  <= '0;
        rob_tail  <= '0;
        rob_count <= '0;
        for (int i = 0; i < ROB_SIZE; i++)
            rob_q[i].valid <= 1'b0;
    end else if (flush_o) begin
        // 刷新：清空整个 ROB
        rob_head  <= '0;
        rob_tail  <= '0;
        rob_count <= '0;
        for (int i = 0; i < ROB_SIZE; i++)
            rob_q[i].valid <= 1'b0;
    end else begin
        // 分配新 ROB 项
        if (alloc_fire) begin
            rob_q[rob_tail].valid           <= 1'b1;
            rob_q[rob_tail].complete        <= 1'b0;
            rob_q[rob_tail].pc              <= alloc_pkt_i.pc;
            rob_q[rob_tail].inst            <= alloc_pkt_i.inst;
            rob_q[rob_tail].arch_rd         <= alloc_pkt_i.arch_rd;
            rob_q[rob_tail].phys_rd         <= alloc_pkt_i.phys_rd;
            rob_q[rob_tail].phys_rd_old     <= alloc_pkt_i.phys_rd_old;
            rob_q[rob_tail].rd_wen          <= alloc_pkt_i.rd_wen;
            rob_q[rob_tail].exception       <= 1'b0;
            rob_q[rob_tail].exception_cause <= '0;
            rob_q[rob_tail].redirect_valid  <= 1'b0;
            rob_q[rob_tail].redirect_addr   <= '0;
            rob_q[rob_tail].sys             <= alloc_pkt_i.sys;
            rob_tail <= rob_tail + 5'd1;
        end

        // 完成标记（乱序写回）
        if (complete_en_i) begin
            rob_q[complete_idx_i].complete        <= 1'b1;
            rob_q[complete_idx_i].result          <= complete_data_i;
            rob_q[complete_idx_i].exception       <= complete_exception_i;
            rob_q[complete_idx_i].exception_cause <= complete_cause_i;
            rob_q[complete_idx_i].redirect_valid  <= complete_redirect_valid_i;
            rob_q[complete_idx_i].redirect_addr   <= complete_redirect_addr_i;
        end

        // 正常提交：释放头部项
        if (commit_valid_o) begin
            rob_q[rob_head].valid <= 1'b0;
            rob_head <= rob_head + 5'd1;
        end

        // 计数：alloc 和 commit 可以同拍发生
        rob_count <= rob_count + alloc_fire - commit_fire;
    end
end

endmodule
