// 忙碌表（Busy Table / Register Status Table）
// 跟踪物理寄存器是否就绪（0 = 就绪，1 = 忙碌等待写回）
// 重命名时标记忙碌，执行单元写回时清除（唤醒）

module busy_table #(
    parameter int NUM_PHYS_REGS = 64
)(
    input               clk,
    input               rst,

    // 查询接口（组合逻辑）
    input       [5:0]   query_preg1_i,
    input       [5:0]   query_preg2_i,
    output              ready1_o,
    output              ready2_o,

    // 设置忙碌（重命名阶段分配新物理寄存器时）
    input               set_busy_en_i,
    input       [5:0]   set_busy_preg_i,

    // 清除忙碌（执行单元写回时，唤醒依赖指令）
    input               clear_busy_en_i,
    input       [5:0]   clear_busy_preg_i,

    // 刷新
    input               flush_i
);

logic [NUM_PHYS_REGS-1:0] busy;

// 就绪 = 不忙碌；p0 永远就绪（物理寄存器堆保证其恒为 0）
assign ready1_o = !busy[query_preg1_i];
assign ready2_o = !busy[query_preg2_i];

always_ff @(posedge clk) begin
    if (rst || flush_i) begin
        busy <= '0;
    end else begin
        // set 先写、clear 后写：同拍对同一寄存器同时操作时，clear 优先。
        // 实践中不会出现对同一寄存器同时 set+clear，但 clear 优先更安全，
        // 避免因极端情况导致寄存器永久阻塞。
        if (set_busy_en_i)
            busy[set_busy_preg_i]   <= 1'b1;
        if (clear_busy_en_i)
            busy[clear_busy_preg_i] <= 1'b0;
    end
end

endmodule
