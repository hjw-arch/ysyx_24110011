// Store Queue + CAM 功能测试
// 覆盖：alloc/drain/empty、STLF 全覆盖、部分重叠 stall、不同字 none、幼项优先

`include "../include/pipeline_pkt_pkg.sv"

module tb_store_queue;
import pipeline_pkt_pkg::*;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

logic        flush_i;
logic        branch_recover_valid_i;
logic [4:0]  branch_recover_idx_i;
logic        alloc_en_i;
logic [4:0]  alloc_rob_idx_i;
logic [31:0] alloc_addr_i, alloc_data_i;
logic [3:0]  alloc_strb_i;
logic [1:0]  alloc_size_i;
logic        alloc_ready_o, empty_o;

logic [31:0] cam_addr_i;
logic [1:0]  cam_size_i;
logic        cam_hit_o, cam_stall_o;
logic [31:0] cam_data_o;

logic        commit_req_i;
logic [4:0]  commit_rob_idx_i;
logic        commit_ready_o, commit_fault_o;

logic        drain_req_o;
logic [31:0] drain_addr_o, drain_data_o;
logic [1:0]  drain_size_o;
logic        drain_fire_i, drain_done_i, drain_fault_i;

store_queue #(.SQ_DEPTH(8)) dut (.*);

int pass_cnt = 0, fail_cnt = 0;

task automatic chk(input string name, input logic exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=%b  实际=%b", name, exp, act); fail_cnt++; end
endtask

task automatic chk32(input string name, input logic [31:0] exp, act);
    if (exp === act) begin $display("  [PASS] %s", name); pass_cnt++; end
    else begin $display("  [FAIL] %s  期望=0x%08x  实际=0x%08x", name, exp, act); fail_cnt++; end
endtask

task automatic tick; @(posedge clk); #1; endtask

task automatic do_alloc(
    input [4:0]  rob,
    input [31:0] addr,
    input [31:0] data,
    input [3:0]  strb,
    input [1:0]  size
);
    alloc_en_i = 1;
    alloc_rob_idx_i = rob;
    alloc_addr_i = addr;
    alloc_data_i = data;
    alloc_strb_i = strb;
    alloc_size_i = size;
    tick;
    alloc_en_i = 0;
endtask

initial begin
    flush_i = 0; branch_recover_valid_i = 0; branch_recover_idx_i = 0;
    alloc_en_i = 0; alloc_rob_idx_i = 0;
    alloc_addr_i = 0; alloc_data_i = 0; alloc_strb_i = 0; alloc_size_i = 0;
    cam_addr_i = 0; cam_size_i = 0;
    commit_req_i = 0; commit_rob_idx_i = 0;
    drain_fire_i = 0; drain_done_i = 0; drain_fault_i = 0;

    tick; tick; rst = 0; tick;

    // ── TEST1: 空 SQ，CAM none ──
    $display("\n[TEST1] 空 SQ → empty=1, CAM none");
    chk("empty", 1'b1, empty_o);
    cam_addr_i = 32'h8000_0000; cam_size_i = 2'b10;
    #1;
    chk("cam_hit empty",   1'b0, cam_hit_o);
    chk("cam_stall empty", 1'b0, cam_stall_o);

    // ── TEST2: SW 全覆盖 LW → hit ──
    $display("\n[TEST2] SW 全覆盖 LW → STLF hit");
    do_alloc(5'd1, 32'h8000_1000, 32'hDEAD_BEEF, 4'b1111, 2'b10);
    chk("empty after alloc", 1'b0, empty_o);
    cam_addr_i = 32'h8000_1000; cam_size_i = 2'b10;
    #1;
    chk("cam_hit SW→LW", 1'b1, cam_hit_o);
    chk("cam_stall SW→LW", 1'b0, cam_stall_o);
    chk32("cam_data SW→LW", 32'hDEAD_BEEF, cam_data_o);

    // ── TEST3: 不同字 → none ──
    $display("\n[TEST3] 不同字 → none（允许 AXI）");
    cam_addr_i = 32'h8000_2000; cam_size_i = 2'b10;
    #1;
    chk("cam_hit diff word",   1'b0, cam_hit_o);
    chk("cam_stall diff word", 1'b0, cam_stall_o);

    // ── TEST4: SB 对 LW 部分重叠 → stall ──
    $display("\n[TEST4] SB 对 LW 部分重叠 → stall");
    // 清 SQ：commit+drain 完成 pop
    commit_req_i = 1; commit_rob_idx_i = 5'd1;
    #1;
    chk("drain_req", 1'b1, drain_req_o);
    drain_fire_i = 1; tick; drain_fire_i = 0;
    drain_done_i = 1; drain_fault_i = 0; tick; drain_done_i = 0;
    // commit_ready 应拉高，本拍 pop
    #1;
    chk("commit_ready", 1'b1, commit_ready_o);
    tick; // pop
    commit_req_i = 0;
    chk("empty after pop", 1'b1, empty_o);

    // SB 写 byte0
    do_alloc(5'd2, 32'h8000_3000, 32'h0000_00AA, 4'b0001, 2'b00);
    cam_addr_i = 32'h8000_3000; cam_size_i = 2'b10; // LW 同字
    #1;
    chk("cam_hit SB→LW",   1'b0, cam_hit_o);
    chk("cam_stall SB→LW", 1'b1, cam_stall_o);

    // ── TEST5: SB 全覆盖 LBU 同字节 → hit ──
    $display("\n[TEST5] SB 全覆盖 LBU → hit，数据低位");
    cam_addr_i = 32'h8000_3000; cam_size_i = 2'b00; // LB/LBU byte0
    #1;
    chk("cam_hit SB→LBU",   1'b1, cam_hit_o);
    chk("cam_stall SB→LBU", 1'b0, cam_stall_o);
    chk32("cam_data SB→LBU", 32'h0000_00AA, cam_data_o);

    // ── TEST6: 幼项优先（后 alloc 的覆盖）──
    $display("\n[TEST6] 两笔同字 SW，幼项优先");
    // 先 pop 掉 SB
    commit_req_i = 1; commit_rob_idx_i = 5'd2;
    #1; drain_fire_i = 1; tick; drain_fire_i = 0;
    drain_done_i = 1; tick; drain_done_i = 0;
    #1; tick; commit_req_i = 0;

    do_alloc(5'd3, 32'h8000_4000, 32'h1111_1111, 4'b1111, 2'b10);
    do_alloc(5'd4, 32'h8000_4000, 32'h2222_2222, 4'b1111, 2'b10);
    cam_addr_i = 32'h8000_4000; cam_size_i = 2'b10;
    #1;
    chk("cam_hit younger", 1'b1, cam_hit_o);
    chk32("cam_data younger", 32'h2222_2222, cam_data_o);

    // ── TEST7: 幼项部分重叠压制老项全覆盖 → stall ──
    $display("\n[TEST7] 幼 SB 部分重叠压制老 SW → stall");
    // pop 两笔
    commit_req_i = 1; commit_rob_idx_i = 5'd3;
    #1; drain_fire_i = 1; tick; drain_fire_i = 0;
    drain_done_i = 1; tick; drain_done_i = 0; #1; tick;
    commit_rob_idx_i = 5'd4;
    #1; drain_fire_i = 1; tick; drain_fire_i = 0;
    drain_done_i = 1; tick; drain_done_i = 0; #1; tick;
    commit_req_i = 0;

    do_alloc(5'd5, 32'h8000_5000, 32'hAAAA_AAAA, 4'b1111, 2'b10); // 老 SW
    do_alloc(5'd6, 32'h8000_5001, 32'h0000_00BB, 4'b0010, 2'b00); // 幼 SB byte1
    cam_addr_i = 32'h8000_5000; cam_size_i = 2'b10; // LW
    #1;
    chk("cam_hit young partial",   1'b0, cam_hit_o);
    chk("cam_stall young partial", 1'b1, cam_stall_o);

    // ── TEST8: SH 全覆盖 LHU ──
    $display("\n[TEST8] SH 全覆盖 LHU");
    commit_req_i = 1; commit_rob_idx_i = 5'd5;
    #1; drain_fire_i = 1; tick; drain_fire_i = 0;
    drain_done_i = 1; tick; drain_done_i = 0; #1; tick;
    commit_rob_idx_i = 5'd6;
    #1; drain_fire_i = 1; tick; drain_fire_i = 0;
    drain_done_i = 1; tick; drain_done_i = 0; #1; tick;
    commit_req_i = 0;

    do_alloc(5'd7, 32'h8000_6000, 32'h0000_CDEF, 4'b0011, 2'b01); // SH
    cam_addr_i = 32'h8000_6000; cam_size_i = 2'b01; // LH/LHU
    #1;
    chk("cam_hit SH→LHU", 1'b1, cam_hit_o);
    chk32("cam_data SH→LHU", 32'h0000_CDEF, cam_data_o);

    // 高半字 SH
    do_alloc(5'd8, 32'h8000_6002, 32'h0000_AB12, 4'b1100, 2'b01);
    cam_addr_i = 32'h8000_6002; cam_size_i = 2'b01;
    #1;
    chk("cam_hit SH hi→LHU", 1'b1, cam_hit_o);
    chk32("cam_data SH hi→LHU", 32'h0000_AB12, cam_data_o);

    // ── TEST9: 分支恢复只裁掉年轻 store 后缀 ──
    $display("\n[TEST9] 分支选择性恢复");
    flush_i = 1; tick; flush_i = 0;
    do_alloc(5'd10, 32'h8000_7000, 32'h1010_1010, 4'b1111, 2'b10);
    do_alloc(5'd12, 32'h8000_7004, 32'h1212_1212, 4'b1111, 2'b10);
    do_alloc(5'd13, 32'h8000_7008, 32'h1313_1313, 4'b1111, 2'b10);

    branch_recover_valid_i = 1'b1;
    branch_recover_idx_i   = 5'd11;
    tick;
    branch_recover_valid_i = 1'b0;

    chk("恢复后仅保留更老 store", 1'b1, dut.count == 1);
    cam_addr_i = 32'h8000_7000; cam_size_i = 2'b10; #1;
    chk("更老 store 仍可 CAM 命中", 1'b1, cam_hit_o);
    cam_addr_i = 32'h8000_7004; #1;
    chk("年轻 store 已从 CAM 清除", 1'b0, cam_hit_o);

    tick;
    $display("\n===== store_queue: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    if (fail_cnt != 0) $fatal(1, "store_queue TB failed");
    $finish;
end

endmodule
