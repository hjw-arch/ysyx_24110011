// Store Queue（FIFO）
// 不变量：
//   1. store 仅在 ROB commit 后经 drain 发出 AXI 写；issue 只入队
//   2. data 存 rs2 原值，字节摆放由 axi4_full_master 按 addr/size 完成
//   3. empty_o=0 时 LSU 不得发 load（无 STLF 时的保守内存序）
// IQ 已保证 mem 程序序，SQ 按 FIFO 与 ROB head 对齐即可

`include "./include/pipeline_pkt_pkg.sv"

module store_queue
import pipeline_pkt_pkg::*;
#(
    parameter int SQ_DEPTH = 8
)(
    input               clk,
    input               rst,
    input               flush_i,            // 丢弃未提交项；in-flight drain 跑完

    // ── issue 分配 ──
    input               alloc_en_i,
    input       [4:0]   alloc_rob_idx_i,
    input       [31:0]  alloc_addr_i,
    input       [31:0]  alloc_data_i,       // rs2 原值
    input       [3:0]   alloc_strb_i,
    input       [1:0]   alloc_size_i,
    output              alloc_ready_o,
    output              empty_o,            // 无未完成 store，允许 load issue

    // ── commit drain（ROB head 为 store 且已 complete）──
    input               commit_req_i,
    input       [4:0]   commit_rob_idx_i,
    output              commit_ready_o,     // 队头写完成，允许 ROB 退休
    output              commit_fault_o,

    // ── 与 LSU 写通道 ──
    output              drain_req_o,        // 需要启动写且尚未 fire
    output      [31:0]  drain_addr_o,
    output      [31:0]  drain_data_o,
    output      [3:0]   drain_strb_o,
    output      [1:0]   drain_size_o,
    input               drain_fire_i,
    input               drain_done_i,
    input               drain_fault_i
);

localparam int PTR_W = $clog2(SQ_DEPTH);

typedef struct packed {
    logic           valid;
    logic           committed;  // 已 fire，AXI 进行中
    logic           done;
    logic           fault;
    logic   [4:0]   rob_idx;
    logic   [31:0]  addr;
    logic   [31:0]  data;
    logic   [3:0]   strb;
    logic   [1:0]   size;
} sq_entry_t;

sq_entry_t sq [0:SQ_DEPTH-1];
logic [PTR_W:0] head, tail, count;

wire empty = (count == '0);
wire full  = (count == SQ_DEPTH[PTR_W:0]);

assign empty_o       = empty;
assign alloc_ready_o = ~full;

wire [PTR_W-1:0] head_ptr = head[PTR_W-1:0];
wire [PTR_W-1:0] tail_ptr = tail[PTR_W-1:0];

wire head_valid = ~empty & sq[head_ptr].valid;
wire head_match = head_valid & (sq[head_ptr].rob_idx == commit_rob_idx_i);

assign commit_ready_o = head_match & sq[head_ptr].done;
assign commit_fault_o = commit_ready_o & sq[head_ptr].fault;

// 尚未 fire 时请求 LSU 启动写
assign drain_req_o  = commit_req_i & head_match & ~sq[head_ptr].done & ~sq[head_ptr].committed;
assign drain_addr_o = sq[head_ptr].addr;
assign drain_data_o = sq[head_ptr].data;
assign drain_strb_o = sq[head_ptr].strb;
assign drain_size_o = sq[head_ptr].size;

wire alloc_fire = alloc_en_i & alloc_ready_o & ~flush_i;
wire pop_fire   = commit_req_i & commit_ready_o;

always_ff @(posedge clk) begin
    if (rst) begin
        head  <= '0;
        tail  <= '0;
        count <= '0;
        for (int i = 0; i < SQ_DEPTH; i++)
            sq[i].valid <= 1'b0;
    end else if (flush_i) begin
        // 仅保留已发起 AXI 且未完成的队头；其余作废
        if (head_valid && sq[head_ptr].committed && !sq[head_ptr].done) begin
            for (int i = 0; i < SQ_DEPTH; i++) begin
                if (PTR_W'(i) != head_ptr)
                    sq[i].valid <= 1'b0;
            end
            tail  <= head + 1;
            count <= 1;
        end else begin
            for (int i = 0; i < SQ_DEPTH; i++)
                sq[i].valid <= 1'b0;
            head  <= '0;
            tail  <= '0;
            count <= '0;
        end
    end else begin
        if (alloc_fire) begin
            sq[tail_ptr].valid     <= 1'b1;
            sq[tail_ptr].committed <= 1'b0;
            sq[tail_ptr].done      <= 1'b0;
            sq[tail_ptr].fault     <= 1'b0;
            sq[tail_ptr].rob_idx   <= alloc_rob_idx_i;
            sq[tail_ptr].addr      <= alloc_addr_i;
            sq[tail_ptr].data      <= alloc_data_i;
            sq[tail_ptr].strb      <= alloc_strb_i;
            sq[tail_ptr].size      <= alloc_size_i;
            tail <= tail + 1;
        end

        if (drain_fire_i && head_valid)
            sq[head_ptr].committed <= 1'b1;

        if (drain_done_i && head_valid && sq[head_ptr].committed) begin
            sq[head_ptr].done  <= 1'b1;
            sq[head_ptr].fault <= drain_fault_i;
        end

        if (pop_fire) begin
            sq[head_ptr].valid <= 1'b0;
            head <= head + 1;
        end

        count <= count + {{PTR_W{1'b0}}, alloc_fire} - {{PTR_W{1'b0}}, pop_fire};
    end
end

endmodule
