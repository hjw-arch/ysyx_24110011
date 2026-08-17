// 发射队列功能测试
// 覆盖：分派、唤醒、年龄优先选择、同拍 issue+dispatch 复用槽、flush

`include "../include/pipeline_pkt_pkg.sv"

module tb_issue_queue;
import pipeline_pkt_pkg::*;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

logic              dispatch_en_i;
rename2issue_pkt_t dispatch_pkt_i;
logic              dispatch_ready_o;
logic              issue_valid_o;
issue2ex_pkt_t     issue_pkt_o;
logic              issue_ready_i;
logic [5:0]        issue_phys_rs1_o;
logic [5:0]        issue_phys_rs2_o;
logic              wakeup_en_i;
logic [5:0]        wakeup_preg_i;
logic [4:0]        rob_head_i;
logic              flush_i;

issue_queue dut (.*);

int pass_cnt = 0, fail_cnt = 0;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk5(input string name, input logic [4:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%0d  实际=%0d", name, exp, act); fail_cnt++; end
endtask

// 辅助：分派一条双操作数都就绪的指令
task automatic dispatch_ready_instr(input rob_idx_t rob_idx, input [5:0] phys_rd);
    dispatch_en_i              = 1;
    dispatch_pkt_i.rob_idx     = rob_idx;
    dispatch_pkt_i.pred_taken = 1'b0;
    dispatch_pkt_i.pc          = 32'h1000 + {27'b0, rob_idx} * 4;
    dispatch_pkt_i.inst        = 32'h0;
    dispatch_pkt_i.phys_rs1    = 6'd0;   // p0 永远就绪
    dispatch_pkt_i.phys_rs2    = 6'd0;
    dispatch_pkt_i.phys_rd     = phys_rd;
    dispatch_pkt_i.rs1_ready   = 1'b1;
    dispatch_pkt_i.rs2_ready   = 1'b1;
    dispatch_pkt_i.ex          = '0;
    dispatch_pkt_i.mem         = '0;
    dispatch_pkt_i.sys         = '0;
    dispatch_pkt_i.imm         = '0;
    @(posedge clk); #1;
    dispatch_en_i = 0;
endtask

// 辅助：分派一条 rs1 不就绪的指令
task automatic dispatch_waiting_instr(input rob_idx_t rob_idx, input [5:0] phys_rs1, phys_rd);
    dispatch_en_i              = 1;
    dispatch_pkt_i.rob_idx     = rob_idx;
    dispatch_pkt_i.pred_taken = 1'b0;
    dispatch_pkt_i.pc          = 32'h2000 + {27'b0, rob_idx} * 4;
    dispatch_pkt_i.inst        = 32'h0;
    dispatch_pkt_i.phys_rs1    = phys_rs1;
    dispatch_pkt_i.phys_rs2    = 6'd0;
    dispatch_pkt_i.phys_rd     = phys_rd;
    dispatch_pkt_i.rs1_ready   = 1'b0;  // 等待写回
    dispatch_pkt_i.rs2_ready   = 1'b1;
    dispatch_pkt_i.ex          = '0;
    dispatch_pkt_i.mem         = '0;
    dispatch_pkt_i.sys         = '0;
    dispatch_pkt_i.imm         = '0;
    @(posedge clk); #1;
    dispatch_en_i = 0;
endtask

task automatic tick; @(posedge clk); #1; endtask

initial begin
    dispatch_en_i = 0; dispatch_pkt_i = '0;
    issue_ready_i = 1;
    wakeup_en_i = 0; wakeup_preg_i = 0;
    rob_head_i = 5'd0;
    flush_i = 0;
    tick; tick; rst = 0; tick;

    // ── 测试1：就绪指令立即发射 ──
    $display("\n[TEST1] 就绪指令立即可发射");
    chk("初始 issue_valid=0", 1'b0, issue_valid_o);
    dispatch_ready_instr(5'd10, 6'd32);
    chk("分派后 issue_valid=1", 1'b1, issue_valid_o);
    chk5("发射的 rob_idx=10", 5'd10, issue_pkt_o.rob_idx);
    // 等一拍，指令被发射并从队列移除
    issue_ready_i = 1; tick;
    chk("发射后队列为空 issue_valid=0", 1'b0, issue_valid_o);

    // ── 测试2：不就绪指令等待唤醒 ──
    $display("\n[TEST2] 不就绪指令等待唤醒");
    dispatch_waiting_instr(5'd5, 6'd40, 6'd33); // rs1=p40 不就绪
    chk("rs1 不就绪时 issue_valid=0", 1'b0, issue_valid_o);
    // 唤醒 p40
    wakeup_en_i = 1; wakeup_preg_i = 6'd40;
    tick; wakeup_en_i = 0; #1;
    chk("唤醒后 issue_valid=1", 1'b1, issue_valid_o);
    tick; // 发射

    // ── 测试3：年龄优先选择——较老的指令（rob_idx 小）优先 ──
    $display("\n[TEST3] 年龄优先：rob_idx 小的先发射");
    issue_ready_i = 0; // 暂停发射，填入两条指令
    dispatch_ready_instr(5'd7, 6'd34);  // 分派较新（rob_idx=7）
    dispatch_ready_instr(5'd3, 6'd35);  // 分派较老（rob_idx=3）
    issue_ready_i = 0; #1;
    chk5("应选 rob_idx=3（较老）", 5'd3, issue_pkt_o.rob_idx);
    issue_ready_i = 1; tick;  // 发射 idx=3
    chk5("第二条发射 rob_idx=7", 5'd7, issue_pkt_o.rob_idx);
    tick;

    // ── 测试4：同拍 issue + dispatch，队列大小不变（槽复用）──
    $display("\n[TEST4] 同拍 issue+dispatch 槽复用");
    // 先填满至1项
    dispatch_ready_instr(5'd1, 6'd36);
    issue_ready_i = 0; #1; // 暂停发射，观察队列有1条
    chk("队列有1项，issue_valid=1", 1'b1, issue_valid_o);
    // 同拍发射+分派新指令
    issue_ready_i = 1; dispatch_en_i = 1;
    dispatch_pkt_i.rob_idx   = 5'd20;
    dispatch_pkt_i.phys_rs1  = 6'd0;
    dispatch_pkt_i.phys_rs2  = 6'd0;
    dispatch_pkt_i.rs1_ready = 1'b1;
    dispatch_pkt_i.rs2_ready = 1'b1;
    dispatch_pkt_i.phys_rd   = 6'd37;
    dispatch_pkt_i.pred_taken = 1'b0;
    dispatch_pkt_i.pc        = 32'h3000;
    dispatch_pkt_i.inst      = '0;
    dispatch_pkt_i.ex        = '0;
    dispatch_pkt_i.mem       = '0;
    dispatch_pkt_i.sys       = '0;
    dispatch_pkt_i.imm       = '0;
    @(posedge clk); #1;
    dispatch_en_i = 0; issue_ready_i = 1;
    // 新指令 rob_idx=20 应在队列中
    chk("同拍后队列仍有一项（新指令）", 1'b1, issue_valid_o);
    chk5("新指令 rob_idx=20", 5'd20, issue_pkt_o.rob_idx);
    tick;

    // ── 测试5：flush 清空队列 ──
    $display("\n[TEST5] flush 清空队列");
    issue_ready_i = 0;
    dispatch_ready_instr(5'd2, 6'd38);
    dispatch_ready_instr(5'd4, 6'd39);
    issue_ready_i = 0; #1;
    chk("flush前有指令", 1'b1, issue_valid_o);
    flush_i = 1; tick; flush_i = 0; #1;
    chk("flush后队列为空", 1'b0, issue_valid_o);

    // ── 测试6：队列满时 dispatch_ready=0 ──
    $display("\n[TEST6] 队列满后拒绝分派");
    issue_ready_i = 0;  // 停止发射
    for (int i = 0; i < 8; i++) begin
        if (dispatch_ready_o)
            dispatch_ready_instr(5'(i), 6'(32+i));
        else tick;
    end
    #1;
    chk("队列满后 dispatch_ready=0", 1'b0, dispatch_ready_o);
    issue_ready_i = 1;  // 恢复发射

    tick;
    $display("\n===== issue_queue: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
