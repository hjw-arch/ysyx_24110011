// 忙碌表（Busy Table / Register Status Table）
// 跟踪物理寄存器是否就绪（0 = 就绪，1 = 忙碌等待写回）
// 重命名时标记忙碌，执行单元写回时清除（唤醒）
// 双路 clear：支持 EXU/LSU 与 CSR 提交同拍唤醒

module busy_table #(
    parameter int NUM_PHYS_REGS = 64
)(
    input               clk,
    input               rst,

    input       [5:0]   query_preg1_i,
    input       [5:0]   query_preg2_i,
    output              ready1_o,
    output              ready2_o,

    input               set_busy_en_i,
    input       [5:0]   set_busy_preg_i,

    input               clear_busy_en1_i,
    input       [5:0]   clear_busy_preg1_i,
    input               clear_busy_en2_i,
    input       [5:0]   clear_busy_preg2_i,

    input               flush_i
);

logic [NUM_PHYS_REGS-1:0] busy;

assign ready1_o = !busy[query_preg1_i];
assign ready2_o = !busy[query_preg2_i];

always_ff @(posedge clk) begin
    if (rst || flush_i) begin
        busy <= '0;
    end else begin
        // set 先、clear 后：同拍对同一寄存器 clear 优先
        if (set_busy_en_i)
            busy[set_busy_preg_i] <= 1'b1;
        if (clear_busy_en1_i)
            busy[clear_busy_preg1_i] <= 1'b0;
        if (clear_busy_en2_i)
            busy[clear_busy_preg2_i] <= 1'b0;
    end
end

endmodule
