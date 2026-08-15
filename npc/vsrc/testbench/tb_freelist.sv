// 空闲列表功能测试
`timescale 1ns/1ps

module tb_freelist;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

logic       alloc_req_i;
logic       alloc_valid_o;
logic [5:0] alloc_preg_o;
logic       free_en_i;
logic [5:0] free_preg_i;
logic       flush_i;

freelist dut (.*);

int pass_cnt = 0, fail_cnt = 0;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk6(input string name, input logic [5:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%0d  实际=%0d", name, exp, act); fail_cnt++; end
endtask

task automatic tick; @(posedge clk); #1; endtask

initial begin
    alloc_req_i = 0; free_en_i = 0; free_preg_i = 0; flush_i = 0;
    tick; tick; rst = 0; tick;

    // ── 测试1：初始状态，p32 是第一个可用寄存器 ──
    $display("\n[TEST1] 初始状态低位优先分配");
    alloc_req_i = 1; tick; alloc_req_i = 0;
    chk ("分配有效", 1'b1, alloc_valid_o);
    // 第一次分配后 p32 已被占用，下次应给 p33
    // （alloc_preg_o 在 alloc_req 拍后更新）
    // 注意：alloc_preg 是组合输出，当 alloc_req=1 时即显示待分配值
    alloc_req_i = 1;
    #1; // 等组合逻辑稳定
    chk6("第二次分配 p33", 6'd33, alloc_preg_o);
    tick; alloc_req_i = 0;  // tick 内先 posedge 才赋 0，避免同边沿竞争

    // ── 测试2：分配 alloc_req=1 时组合输出正确 ──
    $display("\n[TEST2] 分配请求组合逻辑");
    alloc_req_i = 1;
    #1;
    chk ("alloc_valid=1", 1'b1, alloc_valid_o);
    chk6("第三次分配 p34", 6'd34, alloc_preg_o);
    tick; alloc_req_i = 0;

    // ── 测试3：释放后可重新分配 ──
    $display("\n[TEST3] 释放后可再分配");
    free_en_i = 1; free_preg_i = 6'd32;
    tick; free_en_i = 0;
    // p32 重新空闲，因低位优先，下次应给 p32
    alloc_req_i = 1;
    #1;
    chk6("释放后分配到 p32", 6'd32, alloc_preg_o);
    @(posedge clk); alloc_req_i = 0; #1;

    // ── 测试4：不释放架构寄存器区域 (p0-p31) ──
    $display("\n[TEST4] 不能释放 p0-p31");
    free_en_i = 1; free_preg_i = 6'd5; // 尝试释放 p5（架构区）
    tick; free_en_i = 0;
    // 空闲列表不应变化；p32 应仍可用（刚才分配了p32，现在再分配应该是p33+）
    alloc_req_i = 1; #1;
    // 此时已分配了 p32(test1), p33(test1), p34(test2), p32(test3)
    // 空闲的应从 p35 开始（p32 刚在 test3 被分配掉）
    chk ("p0-p31释放被忽略后仍有空闲", 1'b1, alloc_valid_o);
    @(posedge clk); alloc_req_i = 0; #1;

    // ── 测试5：flush 恢复初始状态 ──
    $display("\n[TEST5] flush 恢复初始状态");
    flush_i = 1; tick; flush_i = 0; tick;
    alloc_req_i = 1; #1;
    chk ("flush后有空闲", 1'b1, alloc_valid_o);
    chk6("flush后首次分配 p32", 6'd32, alloc_preg_o);
    @(posedge clk); alloc_req_i = 0; #1;

    // ── 测试6：耗尽后 alloc_valid=0 ──
    $display("\n[TEST6] 耗尽所有空闲寄存器");
    flush_i = 1; tick; flush_i = 0; tick;
    // 分配全部 32 个空闲寄存器 (p32-p63)
    for (int i = 0; i < 32; i++) begin
        alloc_req_i = 1; tick;
    end
    alloc_req_i = 0; #1;
    chk ("耗尽后 alloc_valid=0", 1'b0, alloc_valid_o);

    tick;
    $display("\n===== freelist: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
