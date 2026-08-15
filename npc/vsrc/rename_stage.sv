// Rename Stage
// 集成映射表、空闲列表、忙碌表，完成寄存器重命名
// 将架构寄存器映射到物理寄存器，消除 WAW/WAR 冒险

`include "./include/pipeline_pkt_pkg.sv"

module rename_stage
import pipeline_pkt_pkg::*;
(
    input  logic                    clk,
    input  logic                    rst_n,
    
    // 来自 Decode 阶段
    input  logic                    decode_valid_i,
    input  decode_pkt_t             decode_pkt_i,
    output logic                    decode_ready_o,
    
    // 到 Issue Queue
    output logic                    dispatch_valid_o,
    output rename2issue_pkt_t       dispatch_pkt_o,
    input  logic                    dispatch_ready_i,
    
    // ROB 接口
    input  logic [4:0]              rob_alloc_idx_i,
    input  logic                    rob_ready_i,
    output logic                    rob_alloc_en_o,
    output rob_alloc_pkt_t          rob_alloc_pkt_o,
    
    // 提交接口（释放旧物理寄存器）
    input  logic                    commit_valid_i,
    input  logic [5:0]              commit_preg_old_i,
    
    // 唤醒接口（清除忙碌）
    input  logic                    wakeup_en_i,
    input  logic [5:0]              wakeup_preg_i,
    
    // 刷新接口
    input  logic                    flush_i
);

    // ========== 子模块连线 ==========
    
    // 映射表
    logic [4:0] map_rs1_arch, map_rs2_arch, map_rd_arch;
    logic [5:0] map_rs1_phys, map_rs2_phys, map_rd_phys_old;
    logic       map_update_en;
    logic [4:0] map_update_arch;
    logic [5:0] map_update_phys;
    
    // 空闲列表
    logic       freelist_alloc_req;
    logic       freelist_alloc_valid;
    logic [5:0] freelist_alloc_preg;
    logic       freelist_free_en;
    logic [5:0] freelist_free_preg;
    
    // 忙碌表
    logic [5:0] busy_query_preg1, busy_query_preg2;
    logic       busy_ready1, busy_ready2;
    logic       busy_set_en;
    logic [5:0] busy_set_preg;
    logic       busy_clear_en;
    logic [5:0] busy_clear_preg;
    
    // ========== 实例化子模块 ==========
    
    rename_map_table u_map_table (
        .clk            (clk),
        .rst_n          (rst_n),
        .rs1_arch_i     (map_rs1_arch),
        .rs2_arch_i     (map_rs2_arch),
        .rd_arch_i      (map_rd_arch),
        .rs1_phys_o     (map_rs1_phys),
        .rs2_phys_o     (map_rs2_phys),
        .rd_phys_old_o  (map_rd_phys_old),
        .update_en_i    (map_update_en),
        .update_arch_i  (map_update_arch),
        .update_phys_i  (map_update_phys),
        .flush_i        (flush_i)
    );
    
    freelist u_freelist (
        .clk            (clk),
        .rst_n          (rst_n),
        .alloc_req_i    (freelist_alloc_req),
        .alloc_valid_o  (freelist_alloc_valid),
        .alloc_preg_o   (freelist_alloc_preg),
        .free_en_i      (freelist_free_en),
        .free_preg_i    (freelist_free_preg),
        .flush_i        (flush_i)
    );
    
    busy_table u_busy_table (
        .clk                (clk),
        .rst_n              (rst_n),
        .query_preg1_i      (busy_query_preg1),
        .query_preg2_i      (busy_query_preg2),
        .ready1_o           (busy_ready1),
        .ready2_o           (busy_ready2),
        .set_busy_en_i      (busy_set_en),
        .set_busy_preg_i    (busy_set_preg),
        .clear_busy_en_i    (busy_clear_en),
        .clear_busy_preg_i  (busy_clear_preg),
        .flush_i            (flush_i)
    );
    
    // ========== 重命名逻辑（组合逻辑）==========
    
    // 查询映射表
    assign map_rs1_arch = decode_pkt_i.rs1_arch;
    assign map_rs2_arch = decode_pkt_i.rs2_arch;
    assign map_rd_arch = decode_pkt_i.rd_arch;
    
    // 请求分配新物理寄存器（只有写寄存器的指令才需要）
    assign freelist_alloc_req = decode_valid_i && decode_pkt_i.rd_wen;
    
    // 查询忙碌表
    assign busy_query_preg1 = map_rs1_phys;
    assign busy_query_preg2 = map_rs2_phys;
    
    // 操作数就绪状态（如果不使用该操作数，则认为就绪）
    logic rs1_ready, rs2_ready;
    assign rs1_ready = !decode_pkt_i.rs1_used || busy_ready1;
    assign rs2_ready = !decode_pkt_i.rs2_used || busy_ready2;
    
    // 流水线握手：需要 ROB 有空间、IQ 有空间、空闲列表有寄存器（如果需要分配）
    logic can_proceed;
    assign can_proceed = rob_ready_i && 
                         dispatch_ready_i && 
                         (!decode_pkt_i.rd_wen || freelist_alloc_valid);
    
    assign decode_ready_o = can_proceed;
    assign dispatch_valid_o = decode_valid_i && can_proceed;
    
    // 更新映射表（时序逻辑会在下个周期生效）
    assign map_update_en = dispatch_valid_o && decode_pkt_i.rd_wen;
    assign map_update_arch = decode_pkt_i.rd_arch;
    assign map_update_phys = freelist_alloc_preg;
    
    // 设置新物理寄存器为忙碌
    assign busy_set_en = dispatch_valid_o && decode_pkt_i.rd_wen;
    assign busy_set_preg = freelist_alloc_preg;
    
    // 提交时释放旧物理寄存器
    assign freelist_free_en = commit_valid_i;
    assign freelist_free_preg = commit_preg_old_i;
    
    // 唤醒时清除忙碌
    assign busy_clear_en = wakeup_en_i;
    assign busy_clear_preg = wakeup_preg_i;
    
    // ========== 组装输出包（组合逻辑）==========
    
    // 到 Issue Queue 的包
    assign dispatch_pkt_o.pc = decode_pkt_i.pc;
    assign dispatch_pkt_o.inst = decode_pkt_i.inst;
    assign dispatch_pkt_o.rob_idx = rob_alloc_idx_i;
    assign dispatch_pkt_o.phys_rs1 = map_rs1_phys;
    assign dispatch_pkt_o.phys_rs2 = map_rs2_phys;
    assign dispatch_pkt_o.phys_rd = decode_pkt_i.rd_wen ? freelist_alloc_preg : 6'd0;
    assign dispatch_pkt_o.rs1_ready = rs1_ready;
    assign dispatch_pkt_o.rs2_ready = rs2_ready;
    assign dispatch_pkt_o.ex = decode_pkt_i.ex;
    assign dispatch_pkt_o.mem = decode_pkt_i.mem;
    assign dispatch_pkt_o.sys = decode_pkt_i.sys;
    assign dispatch_pkt_o.imm = decode_pkt_i.imm;
    
    // ROB 分配
    assign rob_alloc_en_o = dispatch_valid_o;
    assign rob_alloc_pkt_o.pc = decode_pkt_i.pc;
    assign rob_alloc_pkt_o.inst = decode_pkt_i.inst;
    assign rob_alloc_pkt_o.arch_rd = decode_pkt_i.rd_arch;
    assign rob_alloc_pkt_o.phys_rd = decode_pkt_i.rd_wen ? freelist_alloc_preg : 6'd0;
    assign rob_alloc_pkt_o.phys_rd_old = map_rd_phys_old;
    assign rob_alloc_pkt_o.rd_wen = decode_pkt_i.rd_wen;
    assign rob_alloc_pkt_o.sys = decode_pkt_i.sys;

endmodule
