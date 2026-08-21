// 空闲列表功能测试
`timescale 1ns/1ps

module tb_freelist;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

logic       alloc_req_i;
logic       alloc_valid_o;
logic [5:0] alloc_preg_o;
logic       commit_en_i;
logic [5:0] commit_preg_new_i;
logic [5:0] commit_preg_old_i;
logic       flush_i;

freelist dut (
    .clk               (clk),
    .rst               (rst),
    .alloc_req_i       (alloc_req_i),
    .alloc_valid_o     (alloc_valid_o),
    .alloc_preg_o      (alloc_preg_o),
    .commit_en_i        (commit_en_i),
    .commit_preg_new_i  (commit_preg_new_i),
    .commit_preg_old_i  (commit_preg_old_i),
    .flush_i            (flush_i)
);

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
    alloc_req_i       = 1'b0;
    commit_en_i        = 1'b0;
    commit_preg_new_i  = '0;
    commit_preg_old_i  = '0;
    flush_i            = 1'b0;

    tick;
    tick;
    rst = 1'b0;
    tick;

    // ── 测试1：初始状态 ──
    $display("\n[TEST1] 初始状态低位优先分配");
    chk ("分配有效", 1'b1, alloc_valid_o);
    chk6("首次分配 p32", 6'd32, alloc_preg_o);

    // ── 测试2：推测分配 ──
    $display("\n[TEST2] 推测分配消耗 p32");
    alloc_req_i = 1'b1;
    tick;
    alloc_req_i = 1'b0;
    #1;
    chk6("下一项为 p33", 6'd33, alloc_preg_o);

    // ── 测试3：提交新映射 p32，释放旧映射 p5 ──
    $display("\n[TEST3] 提交更新 committed FreeList");
    commit_en_i       = 1'b1;
    commit_preg_new_i = 6'd32;
    commit_preg_old_i = 6'd5;
    tick;
    commit_en_i = 1'b0;
    #1;
    chk6("提交后旧映射 p5 可分配", 6'd5, alloc_preg_o);

    // ── 测试4：Flush 撤销未提交的 p5 分配 ──
    $display("\n[TEST4] Flush 恢复 committed FreeList");
    alloc_req_i = 1'b1;
    tick;
    alloc_req_i = 1'b0;
    #1;
    chk6("错误路径分配 p5 后下一项为 p33", 6'd33, alloc_preg_o);

    flush_i = 1'b1;
    tick;
    flush_i = 1'b0;
    #1;
    chk6("Flush 后 p5 重新空闲", 6'd5, alloc_preg_o);

    // ── 测试5：同拍 Commit+Flush 必须保留 head 提交 ──
    $display("\n[TEST5] Commit+Flush 同拍旁路");
    alloc_req_i = 1'b1;
    tick;
    alloc_req_i = 1'b0;

    commit_en_i       = 1'b1;
    commit_preg_new_i = 6'd5;
    commit_preg_old_i = 6'd6;
    flush_i           = 1'b1;
    tick;
    commit_en_i = 1'b0;
    flush_i     = 1'b0;
    #1;
    chk6("同拍恢复后 p5 占用、p6 空闲", 6'd6, alloc_preg_o);

    // ── 测试6：复位后耗尽全部推测空闲寄存器 ──
    $display("\n[TEST6] 耗尽所有空闲寄存器");
    rst = 1'b1;
    tick;
    rst = 1'b0;
    tick;

    for (int i = 0; i < 32; i++) begin
        alloc_req_i = 1'b1;
        tick;
    end
    alloc_req_i = 1'b0;
    #1;
    chk("耗尽后 alloc_valid=0", 1'b0, alloc_valid_o);

    tick;
    $display("\n===== freelist: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
