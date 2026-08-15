// Free List for Physical Register Allocation
// 管理 64 个物理寄存器的分配状态
// p0-p31 初始占用（映射架构寄存器），p32-p63 初始空闲

module freelist #(
    parameter int NUM_PHYS_REGS = 64,
    parameter int NUM_ARCH_REGS = 32
) (
    input  logic                clk,
    input  logic                rst_n,
    
    // 分配接口
    input  logic                alloc_req_i,        // 请求分配
    output logic                alloc_valid_o,      // 是否有空闲寄存器
    output logic [5:0]          alloc_preg_o,       // 分配的物理寄存器编号
    
    // 释放接口
    input  logic                free_en_i,          // 释放使能
    input  logic [5:0]          free_preg_i,        // 要释放的物理寄存器编号
    
    // 刷新接口（分支误预测恢复，暂时不实现）
    input  logic                flush_i
);

    // 空闲位向量：1 表示空闲，0 表示占用
    logic [NUM_PHYS_REGS-1:0] free_list;
    
    // ========== 优先编码器：找第一个空闲寄存器（组合逻辑）==========
    logic [5:0] next_free_preg;
    logic has_free;
    
    always_comb begin
        has_free = 1'b0;
        next_free_preg = 6'd0;
        
        // 从 p32 开始查找（p0-p31 保留给初始映射）
        for (int i = NUM_PHYS_REGS-1; i >= NUM_ARCH_REGS; i--) begin
            if (free_list[i]) begin
                next_free_preg = i[5:0];
                has_free = 1'b1;
            end
        end
    end
    
    assign alloc_valid_o = has_free;
    assign alloc_preg_o = next_free_preg;
    
    // ========== 分配和释放逻辑（时序逻辑）==========
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 初始化：p0-p31 占用，p32-p63 空闲
            free_list <= '0;
            for (int i = NUM_ARCH_REGS; i < NUM_PHYS_REGS; i++) begin
                free_list[i] <= 1'b1;
            end
        end else if (flush_i) begin
            // 刷新时恢复到初始状态（简化版本）
            free_list <= '0;
            for (int i = NUM_ARCH_REGS; i < NUM_PHYS_REGS; i++) begin
                free_list[i] <= 1'b1;
            end
        end else begin
            // 分配：将对应位清零
            if (alloc_req_i && alloc_valid_o) begin
                free_list[alloc_preg_o] <= 1'b0;
            end
            
            // 释放：将对应位置位（只释放 p32-p63）
            if (free_en_i && free_preg_i >= NUM_ARCH_REGS) begin
                free_list[free_preg_i] <= 1'b1;
            end
        end
    end

endmodule
