// 重命名映射表（Rename Map Table）
// 维护架构寄存器到物理寄存器的映射
// 初始恒等映射：x0→p0, x1→p1, ..., x31→p31
// 组合读、时序写；x0 的映射始终为 p0（由物理寄存器堆保证 p0=0）

module rename_map_table #(
    parameter int NUM_ARCH_REGS = 32
)(
    input               clk,
    input               rst,

    // 查询接口（组合逻辑，单拍出结果）
    input       [4:0]   rs1_arch_i,
    input       [4:0]   rs2_arch_i,
    input       [4:0]   rd_arch_i,
    output      [5:0]   rs1_phys_o,      // rs1 当前物理映射
    output      [5:0]   rs2_phys_o,      // rs2 当前物理映射
    output      [5:0]   rd_phys_old_o,   // rd 旧物理映射，提交时用于释放

    // 更新接口（时序，下拍生效）
    input               update_en_i,
    input       [4:0]   update_arch_i,
    input       [5:0]   update_phys_i,

    // 刷新（异常/误预测后恢复到初始恒等映射，后续改为检查点恢复）
    input               flush_i
);

logic [5:0] map_table [0:NUM_ARCH_REGS-1];

// 组合读
assign rs1_phys_o    = map_table[rs1_arch_i];
assign rs2_phys_o    = map_table[rs2_arch_i];
assign rd_phys_old_o = map_table[rd_arch_i];

always_ff @(posedge clk) begin
    if (rst || flush_i) begin
        // 恢复恒等映射
        for (int i = 0; i < NUM_ARCH_REGS; i++) begin
            map_table[i] <= 6'(i);
        end
    end else begin
        if (update_en_i)
            map_table[update_arch_i] <= update_phys_i;
    end
end

endmodule
