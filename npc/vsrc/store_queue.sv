// Store Queue（FIFO）+ CAM（STLF）
// 不变量：
//   1. store 仅在 ROB commit 后经 drain 发出 AXI 写；issue 只入队
//   2. data = rs2 原值；字内摆放与 master WDATA 一致，load 低位与 master rdata 一致
//   3. strb 仅 CAM/记录；drain 写通道 WSTRB 由 master 按 addr/size 再生成
//   4. load CAM（仅对齐）：全覆盖 hit / 部分重叠 stall / 无重叠 none
//   5. IQ older_mem ⇒ SQ 内均年长于当前 load；CAM 尾→头（幼优先）
//   6. empty_o 供 TB/调试；LSU load 门控用 CAM，不再依赖 empty

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
    output              empty_o,            // 调试/TB；非 load 门控

    // ── load CAM ──
    input       [31:0]  cam_addr_i,
    input       [1:0]   cam_size_i,
    output              cam_hit_o,          // 全覆盖，可前递
    output              cam_stall_o,        // 部分重叠，停 load
    output      [31:0]  cam_data_o,         // 前递数据（低位对齐，同 master rdata）

    // ── commit drain（ROB head 为 store 且已 complete）──
    input               commit_req_i,
    input       [4:0]   commit_rob_idx_i,
    output              commit_ready_o,
    output              commit_fault_o,

    // ── 与 LSU 写通道 ──
    output              drain_req_o,
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

assign drain_req_o  = commit_req_i & head_match & ~sq[head_ptr].done & ~sq[head_ptr].committed;
assign drain_addr_o = sq[head_ptr].addr;
assign drain_data_o = sq[head_ptr].data;
assign drain_strb_o = sq[head_ptr].strb;
assign drain_size_o = sq[head_ptr].size;

wire alloc_fire = alloc_en_i & alloc_ready_o & ~flush_i;
wire pop_fire   = commit_req_i & commit_ready_o;

// ── load 字节掩码（对齐）──
logic [3:0] ld_mask;
always_comb begin
    unique case (cam_size_i)
        2'b00:   ld_mask = 4'b0001 << cam_addr_i[1:0];
        2'b01:   ld_mask = 4'b0011 << {cam_addr_i[1], 1'b0};
        default: ld_mask = 4'b1111;
    endcase
end

// 每项：重叠 / 全覆盖 / 前递数据（组合）
logic [SQ_DEPTH-1:0] ent_overlap;
logic [SQ_DEPTH-1:0] ent_full;
logic [31:0]         ent_fwd [0:SQ_DEPTH-1];

genvar gi;
generate
    for (gi = 0; gi < SQ_DEPTH; gi++) begin : g_cam
        wire        v    = sq[gi].valid;
        wire [31:0] a    = sq[gi].addr;
        wire [31:0] d    = sq[gi].data;
        wire [1:0]  sz   = sq[gi].size;
        wire [3:0]  sb   = sq[gi].strb;
        wire        same = (a[31:2] == cam_addr_i[31:2]);
        wire [3:0]  ov   = sb & ld_mask;

        assign ent_overlap[gi] = v & same & (|ov);
        assign ent_full[gi]    = v & same & (ov == ld_mask);

        // rs2 → 字内字节（与 master WDATA 一致，对齐访问）
        logic [31:0] st_word;
        always_comb begin
            unique case (sz)
                2'b00: begin
                    unique case (a[1:0])
                        2'b00: st_word = {24'b0, d[7:0]};
                        2'b01: st_word = {16'b0, d[7:0], 8'b0};
                        2'b10: st_word = {8'b0, d[7:0], 16'b0};
                        default: st_word = {d[7:0], 24'b0};
                    endcase
                end
                2'b01: begin
                    unique case (a[1])
                        1'b0: st_word = {16'b0, d[15:0]};
                        default: st_word = {d[15:0], 16'b0};
                    endcase
                end
                default: st_word = d;
            endcase
        end

        // 字 → load 低位（与 master rdata 一致）
        always_comb begin
            unique case ({cam_size_i, cam_addr_i[1:0]})
                4'b0000: ent_fwd[gi] = {24'b0, st_word[7:0]};
                4'b0001: ent_fwd[gi] = {24'b0, st_word[15:8]};
                4'b0010: ent_fwd[gi] = {24'b0, st_word[23:16]};
                4'b0011: ent_fwd[gi] = {24'b0, st_word[31:24]};
                4'b0100: ent_fwd[gi] = {16'b0, st_word[15:0]};
                4'b0110: ent_fwd[gi] = {16'b0, st_word[31:16]};
                4'b1000: ent_fwd[gi] = st_word;
                default: ent_fwd[gi] = 32'b0;
            endcase
        end
    end
endgenerate

// 自幼而老选择首个重叠项。以 tail 为基准计算环形年龄，再用三级树选择，
// 避免动态下标与串行优先链落到 load→PRF 的关键路径上。
typedef struct packed {
    logic             valid;
    logic [PTR_W-1:0] age;
    logic             full;
    logic [31:0]      data;
} cam_candidate_t;

// ponytail: SQ 固定为 8 项；只有修改 SQ_DEPTH 时才泛化选择树。
cam_candidate_t cam_l0 [0:7];
cam_candidate_t cam_l1 [0:3];
cam_candidate_t cam_l2 [0:1];
cam_candidate_t cam_l3;

function automatic cam_candidate_t select_younger(
    input cam_candidate_t lhs,
    input cam_candidate_t rhs
);
    if (!lhs.valid)
        select_younger = rhs;
    else if (!rhs.valid || (lhs.age <= rhs.age))
        select_younger = lhs;
    else
        select_younger = rhs;
endfunction

always_comb begin
    for (int i = 0; i < SQ_DEPTH; i++) begin
        cam_l0[i].valid = ent_overlap[i];
        cam_l0[i].age   = tail_ptr - PTR_W'(1) - PTR_W'(i);
        cam_l0[i].full  = ent_full[i];
        cam_l0[i].data  = ent_fwd[i];
    end

    for (int i = 0; i < 4; i++)
        cam_l1[i] = select_younger(cam_l0[2*i], cam_l0[2*i+1]);
    for (int i = 0; i < 2; i++)
        cam_l2[i] = select_younger(cam_l1[2*i], cam_l1[2*i+1]);
    cam_l3 = select_younger(cam_l2[0], cam_l2[1]);
end

assign cam_hit_o   = cam_l3.valid & cam_l3.full;
assign cam_stall_o = cam_l3.valid & ~cam_l3.full;
assign cam_data_o  = cam_l3.data;

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
