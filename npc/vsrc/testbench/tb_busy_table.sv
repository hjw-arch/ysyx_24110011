// 忙碌表功能测试
`timescale 1ns/1ps

module tb_busy_table;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

logic [5:0] query_preg1_i, query_preg2_i;
logic       ready1_o, ready2_o;
logic       set_busy_en_i;
logic [5:0] set_busy_preg_i;
logic       clear_busy_en_i;
logic [5:0] clear_busy_preg_i;
logic       flush_i;

busy_table dut (.*);

int pass_cnt = 0, fail_cnt = 0;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic tick; @(posedge clk); #1; endtask

initial begin
    query_preg1_i = 0; query_preg2_i = 0;
    set_busy_en_i = 0; set_busy_preg_i = 0;
    clear_busy_en_i = 0; clear_busy_preg_i = 0;
    flush_i = 0;
    tick; tick; rst = 0; tick;

    // ── 测试1：初始全部就绪 ──
    $display("\n[TEST1] 初始全部就绪");
    query_preg1_i = 6'd32; query_preg2_i = 6'd63; #1;
    chk("p32 初始就绪", 1'b1, ready1_o);
    chk("p63 初始就绪", 1'b1, ready2_o);
    query_preg1_i = 6'd0;  #1;
    chk("p0 初始就绪",  1'b1, ready1_o);

    // ── 测试2：set_busy 后不就绪 ──
    $display("\n[TEST2] set_busy 后变为不就绪");
    set_busy_en_i = 1; set_busy_preg_i = 6'd40;
    tick; set_busy_en_i = 0;
    query_preg1_i = 6'd40; #1;
    chk("p40 设为忙碌后不就绪", 1'b0, ready1_o);
    // 其他寄存器不受影响
    query_preg1_i = 6'd41; #1;
    chk("p41 未受影响仍就绪", 1'b1, ready1_o);

    // ── 测试3：clear_busy 后恢复就绪 ──
    $display("\n[TEST3] clear_busy 后恢复就绪");
    clear_busy_en_i = 1; clear_busy_preg_i = 6'd40;
    tick; clear_busy_en_i = 0;
    query_preg1_i = 6'd40; #1;
    chk("p40 清除忙碌后就绪", 1'b1, ready1_o);

    // ── 测试4：同拍 set 和 clear 同一寄存器，clear 优先 ──
    $display("\n[TEST4] 同拍 set+clear 同一寄存器，clear 优先");
    set_busy_en_i   = 1; set_busy_preg_i   = 6'd50;
    clear_busy_en_i = 1; clear_busy_preg_i = 6'd50;
    tick;
    set_busy_en_i = 0; clear_busy_en_i = 0;
    query_preg1_i = 6'd50; #1;
    chk("p50 同拍set+clear后就绪（clear优先）", 1'b1, ready1_o);

    // ── 测试5：set 两个不同寄存器 ──
    $display("\n[TEST5] 独立设置多个寄存器忙碌");
    set_busy_en_i = 1; set_busy_preg_i = 6'd32;
    tick;
    set_busy_en_i = 1; set_busy_preg_i = 6'd33;
    tick; set_busy_en_i = 0;
    query_preg1_i = 6'd32; query_preg2_i = 6'd33; #1;
    chk("p32 忙碌", 1'b0, ready1_o);
    chk("p33 忙碌", 1'b0, ready2_o);

    // ── 测试6：flush 清除所有忙碌 ──
    $display("\n[TEST6] flush 后全部就绪");
    flush_i = 1; tick; flush_i = 0; tick;
    query_preg1_i = 6'd32; query_preg2_i = 6'd33; #1;
    chk("flush后 p32 就绪", 1'b1, ready1_o);
    chk("flush后 p33 就绪", 1'b1, ready2_o);

    tick;
    $display("\n===== busy_table: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
