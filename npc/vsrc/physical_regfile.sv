// 物理寄存器堆（Physical Register File）
// 64 个物理寄存器，2 读 2 写端口
// p0 硬连线为 0（RISC-V x0 约定）
// 同步复位，同拍写后读返回旧值（下拍可见）

module physical_regfile #(
    parameter int NUM_PHYS_REGS = 64
)(
    input               clk,
    input               rst,

    // 读端口（组合逻辑，p0 恒为 0）
    input       [5:0]   read_addr1_i,
    input       [5:0]   read_addr2_i,
    output      [31:0]  read_data1_o,
    output      [31:0]  read_data2_o,

    // 写端口 1（ALU 写回）
    input               write_en1_i,
    input       [5:0]   write_addr1_i,
    input       [31:0]  write_data1_i,

    // 写端口 2（LSU 写回）
    input               write_en2_i,
    input       [5:0]   write_addr2_i,
    input       [31:0]  write_data2_i
);

logic [31:0] regs [0:NUM_PHYS_REGS-1] /* verilator public_flat_rd */;

// p0 硬连线为 0，其余正常读取
assign read_data1_o = (|read_addr1_i) ? regs[read_addr1_i] : 32'b0;
assign read_data2_o = (|read_addr2_i) ? regs[read_addr2_i] : 32'b0;

// 同步写入；两个写端口同时写同一地址时端口 2 优先
always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_PHYS_REGS; i++) begin
            regs[i] <= 32'b0;
        end
    end else begin
        if (write_en1_i && |write_addr1_i)
            regs[write_addr1_i] <= write_data1_i;
        // 端口 2 最后写，若与端口 1 地址相同则端口 2 覆盖
        if (write_en2_i && |write_addr2_i)
            regs[write_addr2_i] <= write_data2_i;
    end
end

endmodule
