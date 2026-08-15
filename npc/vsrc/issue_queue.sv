// Issue Queue
// 存储等待执行的指令，跟踪操作数就绪状态
// 选择就绪指令发射（年龄优先：ROB index 最小）
// 8 项，单发射

`include "./include/pipeline_pkt_pkg.sv"

module issue_queue
import pipeline_pkt_pkg::*;
#(
    parameter int IQ_SIZE = 8
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // 分配接口（Rename/Dispatch）
    input  logic                    dispatch_en_i,
    input  rename2issue_pkt_t       dispatch_pkt_i,
    output logic                    dispatch_ready_o,   // 队列未满
    
    // 发射接口（到 Execute）
    output logic                    issue_valid_o,
    output issue2ex_pkt_t           issue_pkt_o,
    input  logic                    issue_ready_i,      // Execute 就绪
    
    // 唤醒接口（监听写回总线）
    input  logic                    wakeup_en_i,
    input  phys_reg_t               wakeup_preg_i,
    
    // 刷新接口
    input  logic                    flush_i
);

    // 队列项结构
    typedef struct packed {
        logic           valid;
        rob_idx_t       rob_idx;
        logic   [31:0]  pc;
        logic   [31:0]  inst;
        phys_reg_t      phys_rs1;
        phys_reg_t      phys_rs2;
        phys_reg_t      phys_rd;
        logic           rs1_ready;
        logic           rs2_ready;
        ex_ctrl_t       ex;
        mem_ctrl_t      mem;
        sys_ctrl_t      sys;
        logic   [31:0]  imm;
    } iq_entry_t;
    
    // 队列数组
    iq_entry_t iq [IQ_SIZE];
    
    // 队列项计数
    logic [3:0] iq_count;
    
    // ========== 队列未满信号（组合逻辑）==========
    assign dispatch_ready_o = (iq_count < IQ_SIZE);
    
    // ========== 选择逻辑：年龄优先（组合逻辑）==========
    // 找到就绪的、ROB index 最小的指令
    logic [2:0] selected_idx;
    logic found_ready;
    rob_idx_t min_rob_idx;
    
    always_comb begin
        found_ready = 1'b0;
        selected_idx = '0;
        min_rob_idx = '1;  // 初始化为最大值
        
        for (int i = 0; i < IQ_SIZE; i++) begin
            if (iq[i].valid && iq[i].rs1_ready && iq[i].rs2_ready) begin
                if (iq[i].rob_idx < min_rob_idx) begin
                    min_rob_idx = iq[i].rob_idx;
                    selected_idx = i[2:0];
                    found_ready = 1'b1;
                end
            end
        end
    end
    
    assign issue_valid_o = found_ready;
    
    // ========== 发射包输出（组合逻辑）==========
    assign issue_pkt_o.pc = iq[selected_idx].pc;
    assign issue_pkt_o.inst = iq[selected_idx].inst;
    assign issue_pkt_o.rob_idx = iq[selected_idx].rob_idx;
    assign issue_pkt_o.phys_rd = iq[selected_idx].phys_rd;
    assign issue_pkt_o.rs1_data = '0;  // 需要从物理寄存器堆读取
    assign issue_pkt_o.rs2_data = '0;  // 需要从物理寄存器堆读取
    assign issue_pkt_o.ex = iq[selected_idx].ex;
    assign issue_pkt_o.mem = iq[selected_idx].mem;
    assign issue_pkt_o.sys = iq[selected_idx].sys;
    assign issue_pkt_o.imm = iq[selected_idx].imm;
    
    // ========== 分配、唤醒、发射逻辑（时序逻辑）==========
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位
            iq_count <= '0;
            for (int i = 0; i < IQ_SIZE; i++) begin
                iq[i].valid <= 1'b0;
            end
        end else if (flush_i) begin
            // 刷新：清空整个队列
            iq_count <= '0;
            for (int i = 0; i < IQ_SIZE; i++) begin
                iq[i].valid <= 1'b0;
            end
        end else begin
            // 唤醒逻辑：广播写回的物理寄存器编号
            if (wakeup_en_i) begin
                for (int i = 0; i < IQ_SIZE; i++) begin
                    if (iq[i].valid) begin
                        if (iq[i].phys_rs1 == wakeup_preg_i) begin
                            iq[i].rs1_ready <= 1'b1;
                        end
                        if (iq[i].phys_rs2 == wakeup_preg_i) begin
                            iq[i].rs2_ready <= 1'b1;
                        end
                    end
                end
            end
            
            // 发射：移除已发射的指令
            if (issue_valid_o && issue_ready_i) begin
                iq[selected_idx].valid <= 1'b0;
                iq_count <= iq_count - 4'd1;
            end
            
            // 分配：找到第一个空闲位置插入新指令
            if (dispatch_en_i && dispatch_ready_o) begin
                for (int i = 0; i < IQ_SIZE; i++) begin
                    if (!iq[i].valid) begin
                        iq[i].valid <= 1'b1;
                        iq[i].rob_idx <= dispatch_pkt_i.rob_idx;
                        iq[i].pc <= dispatch_pkt_i.pc;
                        iq[i].inst <= dispatch_pkt_i.inst;
                        iq[i].phys_rs1 <= dispatch_pkt_i.phys_rs1;
                        iq[i].phys_rs2 <= dispatch_pkt_i.phys_rs2;
                        iq[i].phys_rd <= dispatch_pkt_i.phys_rd;
                        iq[i].rs1_ready <= dispatch_pkt_i.rs1_ready;
                        iq[i].rs2_ready <= dispatch_pkt_i.rs2_ready;
                        iq[i].ex <= dispatch_pkt_i.ex;
                        iq[i].mem <= dispatch_pkt_i.mem;
                        iq[i].sys <= dispatch_pkt_i.sys;
                        iq[i].imm <= dispatch_pkt_i.imm;
                        iq_count <= iq_count + 4'd1;
                        break;  // 只插入一次
                    end
                end
            end
        end
    end

endmodule
