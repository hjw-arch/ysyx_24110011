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
logic       snapshot_en_i;
logic [1:0] snapshot_slot_i;
logic       recover_en_i;
logic       recover_snapshot_hit_i;
logic [1:0] recover_snapshot_slot_i;
logic       walk_en_i;
logic [5:0] walk_preg_i;
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
    .snapshot_en_i           (snapshot_en_i),
    .snapshot_slot_i         (snapshot_slot_i),
    .recover_en_i            (recover_en_i),
    .recover_snapshot_hit_i  (recover_snapshot_hit_i),
    .recover_snapshot_slot_i (recover_snapshot_slot_i),
    .walk_en_i               (walk_en_i),
    .walk_preg_i             (walk_preg_i),
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
    snapshot_en_i            = 1'b0;
    snapshot_slot_i          = '0;
    recover_en_i             = 1'b0;
    recover_snapshot_hit_i   = 1'b0;
    recover_snapshot_slot_i  = '0;
    walk_en_i                = 1'b0;
    walk_preg_i              = '0;
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

    // ── 测试7：快照恢复归还快照之后分配的寄存器 ──
    $display("\n[TEST7] FreeList 稀疏快照恢复");
    rst = 1'b1;
    tick;
    rst = 1'b0;
    tick;

    alloc_req_i      = 1'b1;
    snapshot_en_i    = 1'b1;
    snapshot_slot_i  = 2'd3;
    tick;
    snapshot_en_i = 1'b0;
    tick;
    alloc_req_i = 1'b0;

    commit_en_i       = 1'b1;
    commit_preg_new_i = 6'd40;
    commit_preg_old_i = 6'd5;
    tick;
    commit_en_i = 1'b0;

    // 端口在 commit_en=0 时可保留非零旧值，恢复逻辑不得误释放它。
    commit_preg_old_i = 6'd28;
    recover_snapshot_hit_i  = 1'b1;
    recover_snapshot_slot_i = 2'd3;
    recover_en_i            = 1'b1;
    tick;
    recover_en_i = 1'b0;
    #1;

    chk("分支自身分配 p32 保持占用", 1'b0, dut.free_list[32]);
    chk("年轻路径分配 p33 被归还", 1'b1, dut.free_list[33]);
    chk("期间提交释放的 p5 仍为空闲", 1'b1, dut.free_list[5]);
    chk("无提交时 old 端口 p28 不得被误释放", 1'b0, dut.free_list[28]);

    // ── 测试8：Walk 重新占用快照之后保留指令的物理寄存器 ──
    $display("\n[TEST8] 稀疏快照 + ROB Walk");
    walk_en_i   = 1'b1;
    walk_preg_i = 6'd33;
    tick;
    walk_en_i = 1'b0;
    #1;
    chk("Walk 后 p33 重新占用", 1'b0, dut.free_list[33]);

    tick;
    $display("\n===== freelist: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
