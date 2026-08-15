// 物理寄存器堆功能测试
`timescale 1ns/1ps

module tb_physical_regfile;

logic clk = 0;
logic rst = 1;
always #5 clk = ~clk;

// DUT 信号
logic [5:0]  read_addr1_i, read_addr2_i;
logic [31:0] read_data1_o, read_data2_o;
logic        write_en1_i,  write_en2_i;
logic [5:0]  write_addr1_i, write_addr2_i;
logic [31:0] write_data1_i, write_data2_i;

physical_regfile dut (.*);

// 测试统计
int pass_cnt = 0, fail_cnt = 0;

task automatic chk32(input string name, input logic [31:0] exp, act);
    if (exp === act) begin
        $display("  [PASS] %s", name);
        pass_cnt++;
    end else begin
        $display("  [FAIL] %s  期望=0x%08x  实际=0x%08x", name, exp, act);
        fail_cnt++;
    end
endtask

task automatic tick; @(posedge clk); #1; endtask

initial begin
    // 初始状态
    read_addr1_i = 0; read_addr2_i = 0;
    write_en1_i  = 0; write_en2_i  = 0;
    write_addr1_i = 0; write_addr2_i = 0;
    write_data1_i = 0; write_data2_i = 0;

    tick; tick;          // 复位2拍
    rst = 0; tick;

    // ── 测试1：p0 永远为 0，无论是否写入 ──
    $display("\n[TEST1] p0 硬连线为0");
    write_en1_i = 1; write_addr1_i = 6'd0; write_data1_i = 32'hDEAD_BEEF;
    tick;
    write_en1_i = 0;
    read_addr1_i = 6'd0;
    tick;
    chk32("p0 读值为0", 32'h0, read_data1_o);

    // ── 测试2：基本写后读 ──
    $display("\n[TEST2] 基本写后读");
    write_en1_i = 1; write_addr1_i = 6'd32; write_data1_i = 32'hAABBCCDD;
    tick;
    write_en1_i = 0;
    read_addr1_i = 6'd32;
    tick;
    chk32("p32 写入后读出", 32'hAABBCCDD, read_data1_o);

    // ── 测试3：两个写端口同时写不同地址 ──
    $display("\n[TEST3] 双端口同时写不同寄存器");
    write_en1_i = 1; write_addr1_i = 6'd33; write_data1_i = 32'h1111_1111;
    write_en2_i = 1; write_addr2_i = 6'd34; write_data2_i = 32'h2222_2222;
    tick;
    write_en1_i = 0; write_en2_i = 0;
    read_addr1_i = 6'd33; read_addr2_i = 6'd34;
    tick;
    chk32("p33 写入端口1", 32'h1111_1111, read_data1_o);
    chk32("p34 写入端口2", 32'h2222_2222, read_data2_o);

    // ── 测试4：端口2 覆盖端口1（同地址同拍） ──
    $display("\n[TEST4] 双端口写同一寄存器，端口2覆盖端口1");
    write_en1_i = 1; write_addr1_i = 6'd35; write_data1_i = 32'hAAAA_AAAA;
    write_en2_i = 1; write_addr2_i = 6'd35; write_data2_i = 32'hBBBB_BBBB;
    tick;
    write_en1_i = 0; write_en2_i = 0;
    read_addr1_i = 6'd35;
    tick;
    chk32("p35 端口2覆盖端口1", 32'hBBBB_BBBB, read_data1_o);

    // ── 测试5：复位清零 ──
    $display("\n[TEST5] 复位后寄存器清零");
    rst = 1; tick; tick; rst = 0; tick;
    read_addr1_i = 6'd32; read_addr2_i = 6'd33;
    tick;
    chk32("p32 复位后为0", 32'h0, read_data1_o);
    chk32("p33 复位后为0", 32'h0, read_data2_o);

    // ── 测试6：高地址寄存器（p63） ──
    $display("\n[TEST6] 最高地址 p63");
    write_en2_i = 1; write_addr2_i = 6'd63; write_data2_i = 32'hFFFF_FFFF;
    tick;
    write_en2_i = 0;
    read_addr2_i = 6'd63;
    tick;
    chk32("p63 读写正常", 32'hFFFF_FFFF, read_data2_o);

    tick;
    $display("\n===== physical_regfile: %0d通过, %0d失败 =====\n", pass_cnt, fail_cnt);
    $finish;
end

endmodule
