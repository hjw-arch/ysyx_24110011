// Reorder Buffer (ROB)
// 维护程序序，支持乱序完成、顺序提交、精确异常
// 循环队列结构，32 项

`include "./include/pipeline_pkt_pkg.sv"

module rob
import pipeline_pkt_pkg::*;
#(
    parameter int ROB_SIZE = 32
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // 分配接口（Rename 阶段）
    input  logic                    alloc_en_i,
    input  rob_alloc_pkt_t          alloc_pkt_i,
    output logic [4:0]              alloc_idx_o,        // 分配的 ROB 索引
    output logic                    alloc_ready_o,      // ROB 未满
    
    // 完成接口（Execute/LSU 写回）
    input  logic                    complete_en_i,
    input  logic [4:0]              complete_idx_i,
    input  logic [31:0]             complete_data_i,
    input  logic                    complete_exception_i,
    input  logic [3:0]              complete_cause_i,
    
    // 提交接口（有序提交）
    output logic                    commit_valid_o,
    output rob_commit_t             commit_pkt_o,
    
    // 刷新接口（分支误预测、异常）
    output logic                    flush_o,
    output logic [31:0]             flush_pc_o
);

    // ROB 项数组
    rob_entry_t rob [ROB_SIZE];
    
    // 头尾指针
    logic [4:0] rob_head, rob_tail;
    
    // ROB 项数计数器
    logic [5:0] rob_count;
    
    // ========== 分配逻辑（组合逻辑）==========
    assign alloc_ready_o = (rob_count < ROB_SIZE);
    assign alloc_idx_o = rob_tail;
    
    // ========== 提交条件（组合逻辑）==========
    // 头部指令有效、已完成、无异常
    assign commit_valid_o = rob[rob_head].valid && 
                            rob[rob_head].complete && 
                            !rob[rob_head].exception;
    
    // 提交包输出
    assign commit_pkt_o.valid = commit_valid_o;
    assign commit_pkt_o.arch_rd = rob[rob_head].arch_rd;
    assign commit_pkt_o.phys_rd_old = rob[rob_head].phys_rd_old;
    assign commit_pkt_o.result = rob[rob_head].result;
    assign commit_pkt_o.rd_wen = rob[rob_head].rd_wen;
    assign commit_pkt_o.sys = rob[rob_head].sys;
    assign commit_pkt_o.redirect = '0;  // 暂不处理系统重定向
    
    // ========== 异常刷新（组合逻辑）==========
    // 头部指令有效、已完成、有异常
    assign flush_o = rob[rob_head].valid && 
                     rob[rob_head].complete && 
                     rob[rob_head].exception;
    assign flush_pc_o = rob[rob_head].pc + 4;  // 简化：异常后顺序执行
    
    // ========== 分配、完成、提交逻辑（时序逻辑）==========
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位
            rob_head <= '0;
            rob_tail <= '0;
            rob_count <= '0;
            for (int i = 0; i < ROB_SIZE; i++) begin
                rob[i].valid <= 1'b0;
            end
        end else if (flush_o) begin
            // 刷新：清空整个 ROB
            rob_head <= '0;
            rob_tail <= '0;
            rob_count <= '0;
            for (int i = 0; i < ROB_SIZE; i++) begin
                rob[i].valid <= 1'b0;
            end
        end else begin
            // 分配新 ROB 项
            if (alloc_en_i && alloc_ready_o) begin
                rob[rob_tail].valid <= 1'b1;
                rob[rob_tail].complete <= 1'b0;
                rob[rob_tail].pc <= alloc_pkt_i.pc;
                rob[rob_tail].inst <= alloc_pkt_i.inst;
                rob[rob_tail].arch_rd <= alloc_pkt_i.arch_rd;
                rob[rob_tail].phys_rd <= alloc_pkt_i.phys_rd;
                rob[rob_tail].phys_rd_old <= alloc_pkt_i.phys_rd_old;
                rob[rob_tail].rd_wen <= alloc_pkt_i.rd_wen;
                rob[rob_tail].exception <= 1'b0;
                rob[rob_tail].exception_cause <= '0;
                rob[rob_tail].sys <= alloc_pkt_i.sys;
                
                rob_tail <= rob_tail + 5'd1;
                rob_count <= rob_count + 6'd1;
            end
            
            // 完成标记
            if (complete_en_i) begin
                rob[complete_idx_i].complete <= 1'b1;
                rob[complete_idx_i].result <= complete_data_i;
                rob[complete_idx_i].exception <= complete_exception_i;
                rob[complete_idx_i].exception_cause <= complete_cause_i;
            end
            
            // 提交（释放 ROB 项）
            if (commit_valid_o) begin
                rob[rob_head].valid <= 1'b0;
                rob_head <= rob_head + 5'd1;
                rob_count <= rob_count - 6'd1;
            end
        end
    end

endmodule
