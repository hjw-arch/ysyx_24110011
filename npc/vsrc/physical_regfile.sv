// 物理寄存器堆（Physical Register File）
// 64 个物理寄存器，2 读 3 写端口
// p0 硬连线为 0（RISC-V x0 约定）
// 同步复位，同拍写后读返回旧值（下拍可见）
// 同址优先级：port3 > port2 > port1

module physical_regfile #(
    parameter int NUM_PHYS_REGS = 64
)(
    input               clk,
    input               rst,

    input       [5:0]   read_addr1_i,
    input       [5:0]   read_addr2_i,
    output      [31:0]  read_data1_o,
    output      [31:0]  read_data2_o,

    // 写端口 1（EXU）
    input               write_en1_i,
    input       [5:0]   write_addr1_i,
    input       [31:0]  write_data1_i,

    // 写端口 2（LSU load）
    input               write_en2_i,
    input       [5:0]   write_addr2_i,
    input       [31:0]  write_data2_i,

    // 写端口 3（CSR 提交）
    input               write_en3_i,
    input       [5:0]   write_addr3_i,
    input       [31:0]  write_data3_i
);

logic [31:0] regs [0:NUM_PHYS_REGS-1] /* verilator public_flat_rd */;

assign read_data1_o = (|read_addr1_i) ? regs[read_addr1_i] : 32'b0;
assign read_data2_o = (|read_addr2_i) ? regs[read_addr2_i] : 32'b0;

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_PHYS_REGS; i++)
            regs[i] <= 32'b0;
    end else begin
        if (write_en1_i && |write_addr1_i)
            regs[write_addr1_i] <= write_data1_i;
        if (write_en2_i && |write_addr2_i)
            regs[write_addr2_i] <= write_data2_i;
        if (write_en3_i && |write_addr3_i)
            regs[write_addr3_i] <= write_data3_i;
    end
end

endmodule
