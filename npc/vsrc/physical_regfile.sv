// 物理寄存器堆（Physical Register File）
// 64 个物理寄存器，提供 2 个异步读端口和 2 个同步写端口。
// p0 的读数据恒为 0，写请求会被忽略；同步复位仅清零初始架构映射 p1-p31。
// p32-p63 分配后先写回、再唤醒消费者，不需要复位门控。
// 两个写端口同拍写同一地址时，端口 2 优先。
// 端口 1 的 EXU/CSR 写请求由顶层保证互斥，本模块不负责仲裁写入源。

module physical_regfile #(
    parameter int NUM_PHYS_REGS = 64
)(
    input               clk,
    input               rst,

    input       [5:0]   read_addr1_i,
    input       [5:0]   read_addr2_i,
    output      [31:0]  read_data1_o,
    output      [31:0]  read_data2_o,

    // 端口 1：EXU 完成或 CSR 提交的快写回
    input               write_en1_i,
    input       [5:0]   write_addr1_i,
    input       [31:0]  write_data1_i,

    // 端口 2：LSU load 完成的慢写回
    input               write_en2_i,
    input       [5:0]   write_addr2_i,
    input       [31:0]  write_data2_i
);

logic [31:0] regs [0:NUM_PHYS_REGS-1] /* verilator public_flat_rd */;

assign read_data1_o = (|read_addr1_i) ? regs[read_addr1_i] : 32'b0;
assign read_data2_o = (|read_addr2_i) ? regs[read_addr2_i] : 32'b0;

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 1; i < 32; i++)
            regs[i] <= 32'b0;
    end else begin
        if (write_en1_i && |write_addr1_i)
            regs[write_addr1_i] <= write_data1_i;
        if (write_en2_i && |write_addr2_i)
            regs[write_addr2_i] <= write_data2_i;
    end
end

endmodule
