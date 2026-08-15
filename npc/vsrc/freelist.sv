// 空闲列表（Free List）
// 管理 64 个物理寄存器的分配状态
// 初始：p0-p31 占用（恒等映射给架构寄存器），p32-p63 空闲
// 优先分配编号最小的空闲寄存器（低位优先）

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

    // 刷新（异常/误预测后恢复，后续改为检查点恢复）
    input               flush_i
);

// 空闲位向量：1 = 空闲，0 = 占用
logic [NUM_PHYS_REGS-1:0] free_list;

// ── 低位优先编码器：找编号最小的空闲寄存器（组合逻辑）──
// has_free 一旦置起，循环后续 if 条件不再成立，等效于 break。
logic [5:0] next_free_preg;
logic       has_free;

always_comb begin
    has_free       = 1'b0;
    next_free_preg = 6'd0;
    for (int i = NUM_ARCH_REGS; i < NUM_PHYS_REGS; i++) begin
        if (free_list[i] && !has_free) begin
            next_free_preg = 6'(i);
            has_free       = 1'b1;
        end
    end
end

assign alloc_valid_o = has_free;
assign alloc_preg_o  = next_free_preg;

// ── 时序逻辑：分配和释放 ──
always_ff @(posedge clk) begin
    if (rst || flush_i) begin
        free_list <= '0;
        for (int i = NUM_ARCH_REGS; i < NUM_PHYS_REGS; i++) begin
            free_list[i] <= 1'b1;
        end
    end else begin
        // 分配：清空对应位
        if (alloc_req_i && has_free)
            free_list[next_free_preg] <= 1'b0;
        // 释放：只释放重命名区域（p32-p63），防止误释放初始架构映射
        if (free_en_i && free_preg_i >= 6'(NUM_ARCH_REGS))
            free_list[free_preg_i] <= 1'b1;
    end
end

endmodule
