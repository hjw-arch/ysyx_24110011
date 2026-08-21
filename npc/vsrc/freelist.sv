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

    // 释放接口：提交阶段归还旧物理寄存器
    input               free_en_i,
    input       [$clog2(NUM_PHYS_REGS)-1:0] free_preg_i,

    // 刷新：按 AMT 快照重建空闲列表
    input               flush_i,
    input       [$clog2(NUM_PHYS_REGS)-1:0]
                        amt_snapshot_i [0:NUM_ARCH_REGS-1]
);

// 空闲位向量：1 = 空闲，0 = 占用
logic [NUM_PHYS_REGS-1:0] free_list;

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

// ── 时序逻辑：分配和释放 ──
always_ff @(posedge clk) begin
    if (rst) begin
        free_list <= '0;
        for (int i = NUM_ARCH_REGS; i < NUM_PHYS_REGS; i++) begin
            free_list[i] <= 1'b1;
        end
    end else if (flush_i) begin
        // 按 AMT 重建：先全部标为空闲，再把 AMT 占用的清掉；p0 始终占用
        free_list <= '1;
        free_list[0] <= 1'b0;
        for (int a = 0; a < NUM_ARCH_REGS; a++) begin
            free_list[amt_snapshot_i[a]] <= 1'b0;
        end
    end else begin
        // 分配：清空对应位
        if (alloc_req_i && has_free)
            free_list[selected_preg] <= 1'b0;
        // 释放：除 p0 外均可归还（首次重命名提交后，原恒等映射 p1-p31 必须回收）
        if (free_en_i && (free_preg_i != '0))
            free_list[free_preg_i] <= 1'b1;
    end
end

endmodule
