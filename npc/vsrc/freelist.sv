// 低位优先编码器。
// WIDTH 必须是 >= 2 的 2 次幂；递归 generate 展开为平衡二分树。
module priority_encoder_lsb #(
    parameter int WIDTH = 2
) (
    input  [WIDTH-1:0]         request_i,
    output                     valid_o,
    output [$clog2(WIDTH)-1:0] index_o
);

generate
    if (WIDTH == 2) begin : g_leaf
        assign valid_o = |request_i;
        assign index_o = ~request_i[0];
    end else begin : g_tree
        localparam int HALF_WIDTH = WIDTH / 2;

        wire                         low_valid;
        wire                         high_valid;
        wire [$clog2(HALF_WIDTH)-1:0] low_index;
        wire [$clog2(HALF_WIDTH)-1:0] high_index;

        priority_encoder_lsb #(
            .WIDTH (HALF_WIDTH)
        ) u_low (
            .request_i (request_i[HALF_WIDTH-1:0]),
            .valid_o   (low_valid),
            .index_o   (low_index)
        );

        priority_encoder_lsb #(
            .WIDTH (HALF_WIDTH)
        ) u_high (
            .request_i (request_i[WIDTH-1:HALF_WIDTH]),
            .valid_o   (high_valid),
            .index_o   (high_index)
        );

        assign valid_o = low_valid | high_valid;
        assign index_o = low_valid ? {1'b0, low_index}
                                   : {1'b1, high_index};
    end
endgenerate

endmodule

// 空闲列表（Free List）
// 复位后，架构恒等映射占用低 NUM_ARCH_REGS 项，其余物理寄存器空闲。
// 组合选择由 priority_encoder_lsb 生成，状态只在 always_ff 中更新。
// committed_free_list 保存已提交状态；flush 时直接恢复，不扫描 AMT。
module freelist #(
    parameter int NUM_PHYS_REGS = 64,
    parameter int NUM_ARCH_REGS = 32
) (
    input               clk,
    input               rst,

    // 分配接口：请求时返回一个空闲物理寄存器
    input               alloc_req_i,
    output              alloc_valid_o,
    output      [$clog2(NUM_PHYS_REGS)-1:0] alloc_preg_o,

    // 提交接口：新映射转为已提交占用，旧映射归还空闲列表
    input               commit_en_i,
    input       [$clog2(NUM_PHYS_REGS)-1:0] commit_preg_new_i,
    input       [$clog2(NUM_PHYS_REGS)-1:0] commit_preg_old_i,

    // 刷新：恢复到包含本拍提交的 committed_free_list
    input               flush_i
);

// 1 = 空闲，0 = 占用
logic [NUM_PHYS_REGS-1:0] free_list;
logic [NUM_PHYS_REGS-1:0] committed_free_list;

localparam logic [NUM_PHYS_REGS-1:0] INITIAL_FREE_LIST =
    {NUM_PHYS_REGS{1'b1}} << NUM_ARCH_REGS;
localparam logic [NUM_PHYS_REGS-1:0] ONE_HOT_LSB =
    {{(NUM_PHYS_REGS-1){1'b0}}, 1'b1};

wire                              has_free;
wire [$clog2(NUM_PHYS_REGS)-1:0] selected_preg;

priority_encoder_lsb #(
    .WIDTH (NUM_PHYS_REGS)
) u_priority_encoder (
    .request_i (free_list),
    .valid_o   (has_free),
    .index_o   (selected_preg)
);

assign alloc_valid_o = has_free;
assign alloc_preg_o  = selected_preg;

// 提交时：新映射占用，旧映射释放；p0 永不进入空闲集合。
wire [NUM_PHYS_REGS-1:0] commit_preg_new_mask =
    ONE_HOT_LSB << commit_preg_new_i;
wire [NUM_PHYS_REGS-1:0] commit_preg_old_mask =
    ONE_HOT_LSB << commit_preg_old_i;
wire [NUM_PHYS_REGS-1:0] committed_free_list_next = commit_en_i
    ? ((committed_free_list & ~commit_preg_new_mask)
      | (commit_preg_old_mask & {NUM_PHYS_REGS{|commit_preg_old_i}}))
    : committed_free_list;

// ── 时序逻辑：推测分配、提交释放和 flush 恢复 ──
always_ff @(posedge clk) begin
    if (rst) begin
        free_list           <= INITIAL_FREE_LIST;
        committed_free_list <= INITIAL_FREE_LIST;
    end else begin
        committed_free_list <= committed_free_list_next;

        if (flush_i) begin
            // 使用 next 值，保留同拍提交指令的映射变化。
            free_list <= committed_free_list_next;
        end else begin
            if (alloc_req_i && has_free)
                free_list[selected_preg] <= 1'b0;
            if (commit_en_i && (commit_preg_old_i != '0))
                free_list[commit_preg_old_i] <= 1'b1;
        end
    end
end

endmodule
