// 重命名映射表功能测试
`timescale 1ns/1ps

module tb_rename_map_table;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

logic [4:0] rs1_arch_i, rs2_arch_i, rd_arch_i;
logic [5:0] rs1_phys_o, rs2_phys_o, rd_phys_old_o;
logic       update_en_i;
logic [4:0] update_arch_i;
logic [5:0] update_phys_i;
logic       commit_en_i;
logic [4:0] commit_arch_i;
logic [5:0] commit_phys_i;
logic       flush_i;

rename_map_table dut (
    .clk(clk), .rst(rst),
    .rs1_arch_i(rs1_arch_i), .rs2_arch_i(rs2_arch_i), .rd_arch_i(rd_arch_i),
    .rs1_phys_o(rs1_phys_o), .rs2_phys_o(rs2_phys_o), .rd_phys_old_o(rd_phys_old_o),
    .update_en_i(update_en_i), .update_arch_i(update_arch_i), .update_phys_i(update_phys_i),
    .commit_en_i(commit_en_i), .commit_arch_i(commit_arch_i), .commit_phys_i(commit_phys_i),
    .flush_i(flush_i)
);

int pass_cnt = 0, fail_cnt = 0;

task automatic chk6(input string name, input logic [5:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=p%0d  实际=p%0d", name, exp, act); fail_cnt++; end
endtask

task automatic tick; @(posedge clk); #1; endtask

initial begin
    rs1_arch_i = 0; rs2_arch_i = 0; rd_arch_i = 0;
    update_en_i = 0; update_arch_i = 0; update_phys_i = 0;
    commit_en_i = 0; commit_arch_i = 0; commit_phys_i = 0; flush_i = 0;
    tick; tick; rst = 0; tick;

    // ── 测试1：初始恒等映射 ──
    $display("\n[TEST1] 初始恒等映射");
    rs1_arch_i = 5'd1;  rs2_arch_i = 5'd2;  rd_arch_i = 5'd3;
    #1;
    chk6("x1 → p1",  6'd1,  rs1_phys_o);
    chk6("x2 → p2",  6'd2,  rs2_phys_o);
    chk6("x3 旧映射 p3", 6'd3, rd_phys_old_o);

    rs1_arch_i = 5'd0;
    #1;
    chk6("x0 → p0",  6'd0,  rs1_phys_o);

    rs1_arch_i = 5'd31;
    #1;
    chk6("x31 → p31", 6'd31, rs1_phys_o);

    // ── 测试2：更新后新映射生效（下拍可见） ──
    $display("\n[TEST2] 更新映射表");
    update_en_i = 1; update_arch_i = 5'd5; update_phys_i = 6'd40;
    tick; update_en_i = 0;
    rs1_arch_i = 5'd5; #1;
    chk6("x5 更新后 → p40", 6'd40, rs1_phys_o);

    // ── 测试3：rd_phys_old 在更新前组合输出旧值 ──
    $display("\n[TEST3] rd_phys_old 读旧映射");
    rd_arch_i = 5'd5; #1;
    chk6("rd_phys_old(x5) = p40（已更新后的当前值）", 6'd40, rd_phys_old_o);
    // 再次更新 x5 → p50，此拍 rd_phys_old 应返回 p40（旧值）
    update_en_i = 1; update_arch_i = 5'd5; update_phys_i = 6'd50;
    rd_arch_i   = 5'd5; #1;
    chk6("更新前 rd_phys_old(x5) = p40", 6'd40, rd_phys_old_o);
    tick; update_en_i = 0;
    rd_arch_i = 5'd5; #1;
    chk6("更新后 rd_phys_old(x5) = p50", 6'd50, rd_phys_old_o);

    // ── 测试4：多个架构寄存器独立更新 ──
    $display("\n[TEST4] 多寄存器独立更新");
    update_en_i = 1; update_arch_i = 5'd10; update_phys_i = 6'd42;
    tick; update_en_i = 0;
    update_en_i = 1; update_arch_i = 5'd11; update_phys_i = 6'd43;
    tick; update_en_i = 0;
    rs1_arch_i = 5'd10; rs2_arch_i = 5'd11; #1;
    chk6("x10 → p42", 6'd42, rs1_phys_o);
    chk6("x11 → p43", 6'd43, rs2_phys_o);

    // ── 测试5：无 commit 时 flush 恢复恒等映射（AMT 仍是恒等）──
    $display("\n[TEST5] flush 恢复恒等映射");
    flush_i = 1; tick; flush_i = 0; tick;
    rs1_arch_i = 5'd5; rs2_arch_i = 5'd10; #1;
    chk6("flush后 x5 → p5",  6'd5,  rs1_phys_o);
    chk6("flush后 x10 → p10", 6'd10, rs2_phys_o);

    // ── 测试6：commit 更新 AMT 后 flush 恢复到已提交映射 ──
    $display("\n[TEST6] commit + flush 恢复 AMT");
    // 推测更新 x7→p55
    update_en_i = 1; update_arch_i = 5'd7; update_phys_i = 6'd55;
    tick; update_en_i = 0;
    // 提交 x7→p55
    commit_en_i = 1; commit_arch_i = 5'd7; commit_phys_i = 6'd55;
    tick; commit_en_i = 0;
    // 再推测更新 x7→p60
    update_en_i = 1; update_arch_i = 5'd7; update_phys_i = 6'd60;
    tick; update_en_i = 0;
    rs1_arch_i = 5'd7; #1;
    chk6("推测映射 x7 → p60", 6'd60, rs1_phys_o);
    // flush 应回到 AMT 的 p55
    flush_i = 1; tick; flush_i = 0; tick;
    rs1_arch_i = 5'd7; #1;
    chk6("flush后 x7 → p55(AMT)", 6'd55, rs1_phys_o);

    tick;
    $display("\n===== rename_map_table: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
