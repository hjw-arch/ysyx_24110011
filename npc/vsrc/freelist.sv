// 空闲列表（Free List）
// 管理 64 个物理寄存器的分配状态
// 初始：p0-p31 占用（恒等映射给架构寄存器），p32-p63 空闲
// p0 永久占用（x0）；p1-p63 均可在提交释放后重新分配
// 优先分配编号最小的空闲寄存器（低位优先）
// flush 时根据 AMT 快照重建：AMT 中出现的 preg 占用，其余空闲（p0 始终占用）

module freelist #(
    parameter int NUM_PHYS_REGS = 64,
    parameter int NUM_ARCH_REGS = 32
)(
    input               clk,
    input               rst,

    // 分配接口：请求时返回一个空闲物理寄存器
    input               alloc_req_i,
    output              alloc_valid_o,
    output      [5:0]   alloc_preg_o,

    // 释放接口：提交阶段归还旧物理寄存器
    input               free_en_i,
    input       [5:0]   free_preg_i,

    // 刷新：按 AMT 快照重建空闲列表
    input               flush_i,
    input       [5:0]   amt_snapshot_i [0:NUM_ARCH_REGS-1]
);

// 空闲位向量：1 = 空闲，0 = 占用
logic [NUM_PHYS_REGS-1:0] free_list;

// ── 低位优先编码器：找编号最小的空闲寄存器（p0 永不分配）──
localparam int GROUP_SIZE  = 8;
localparam int GROUP_COUNT = NUM_PHYS_REGS / GROUP_SIZE;

logic [5:0] next_free_preg;
logic       has_free;
logic [GROUP_COUNT-1:0] group_has_free;
logic [2:0]             group_first [0:GROUP_COUNT-1];

always_comb begin
    group_has_free = '0;
    for (int g = 0; g < GROUP_COUNT; g++) begin
        group_first[g] = '0;
        for (int b = 0; b < GROUP_SIZE; b++) begin
            if (free_list[g * GROUP_SIZE + b] && !group_has_free[g]) begin
                group_has_free[g] = 1'b1;
                group_first[g]    = 3'(b);
            end
        end
    end

    has_free       = 1'b0;
    next_free_preg = 6'd0;
    for (int g = 0; g < GROUP_COUNT; g++) begin
        if (group_has_free[g] && !has_free) begin
            next_free_preg = 6'(g * GROUP_SIZE) + 6'(group_first[g]);
            has_free       = 1'b1;
        end
    end
end

assign alloc_valid_o = has_free;
assign alloc_preg_o  = next_free_preg;

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
            free_list[next_free_preg] <= 1'b0;
        // 释放：除 p0 外均可归还（首次重命名提交后，原恒等映射 p1-p31 必须回收）
        if (free_en_i && (free_preg_i != 6'd0))
            free_list[free_preg_i] <= 1'b1;
    end
end

endmodule
