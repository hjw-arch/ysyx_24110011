// Rename Map Table
// 维护架构寄存器到物理寄存器的映射
// 初始化为恒等映射：x0→p0, x1→p1, ..., x31→p31

module rename_map_table #(
    parameter int NUM_ARCH_REGS = 32,
    parameter int NUM_PHYS_REGS = 64
) (
    input  logic                clk,
    input  logic                rst_n,
    
    // 查询接口（组合逻辑）
    input  logic [4:0]          rs1_arch_i,         // 源寄存器 1 架构编号
    input  logic [4:0]          rs2_arch_i,         // 源寄存器 2 架构编号
    input  logic [4:0]          rd_arch_i,          // 目的寄存器架构编号
    output logic [5:0]          rs1_phys_o,         // 源寄存器 1 物理编号
    output logic [5:0]          rs2_phys_o,         // 源寄存器 2 物理编号
    output logic [5:0]          rd_phys_old_o,      // 目的寄存器旧物理编号（提交时释放）
    
    // 更新接口（时序逻辑）
    input  logic                update_en_i,        // 更新使能
    input  logic [4:0]          update_arch_i,      // 要更新的架构寄存器
    input  logic [5:0]          update_phys_i,      // 新的物理寄存器映射
    
    // 刷新接口（分支误预测恢复，暂时简化处理）
    input  logic                flush_i
);

    // 映射表：32 个架构寄存器 → 64 个物理寄存器
    logic [5:0] map_table [NUM_ARCH_REGS];
    
    // ========== 查询逻辑（组合逻辑）==========
    assign rs1_phys_o = map_table[rs1_arch_i];
    assign rs2_phys_o = map_table[rs2_arch_i];
    assign rd_phys_old_o = map_table[rd_arch_i];
    
    // ========== 更新逻辑（时序逻辑）==========
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 初始化为恒等映射
            for (int i = 0; i < NUM_ARCH_REGS; i++) begin
                map_table[i] <= i[5:0];
            end
        end else if (flush_i) begin
            // 刷新时恢复到初始状态（简化版本，后续添加检查点恢复）
            for (int i = 0; i < NUM_ARCH_REGS; i++) begin
                map_table[i] <= i[5:0];
            end
        end else begin
            // 更新映射
            if (update_en_i) begin
                map_table[update_arch_i] <= update_phys_i;
            end
        end
    end

endmodule
