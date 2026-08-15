// Busy Table (Register Status Table)
// 跟踪物理寄存器的就绪状态
// 0 = 就绪（数据有效），1 = 忙碌（等待写回）

module busy_table #(
    parameter int NUM_PHYS_REGS = 64
) (
    input  logic                clk,
    input  logic                rst_n,
    
    // 查询接口（组合逻辑）
    input  logic [5:0]          query_preg1_i,      // 查询物理寄存器 1
    input  logic [5:0]          query_preg2_i,      // 查询物理寄存器 2
    output logic                ready1_o,           // 寄存器 1 是否就绪
    output logic                ready2_o,           // 寄存器 2 是否就绪
    
    // 设置忙碌（重命名阶段分配新物理寄存器时）
    input  logic                set_busy_en_i,
    input  logic [5:0]          set_busy_preg_i,
    
    // 清除忙碌（执行单元写回时，唤醒依赖指令）
    input  logic                clear_busy_en_i,
    input  logic [5:0]          clear_busy_preg_i,
    
    // 刷新接口
    input  logic                flush_i
);

    // 忙碌位向量：0 = 就绪，1 = 忙碌
    logic [NUM_PHYS_REGS-1:0] busy_table;
    
    // ========== 查询逻辑（组合逻辑）==========
    // 就绪 = 不忙碌
    assign ready1_o = !busy_table[query_preg1_i];
    assign ready2_o = !busy_table[query_preg2_i];
    
    // ========== 更新逻辑（时序逻辑）==========
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 初始化：所有寄存器都就绪
            busy_table <= '0;
        end else if (flush_i) begin
            // 刷新时清空忙碌表
            busy_table <= '0;
        end else begin
            // 设置忙碌（重命名时）
            if (set_busy_en_i) begin
                busy_table[set_busy_preg_i] <= 1'b1;
            end
            
            // 清除忙碌（写回时，优先级高于设置）
            if (clear_busy_en_i) begin
                busy_table[clear_busy_preg_i] <= 1'b0;
            end
        end
    end

endmodule
