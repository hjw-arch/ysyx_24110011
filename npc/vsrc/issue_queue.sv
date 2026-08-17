// 发射队列（Issue Queue）
// 存储等待执行的指令，跟踪操作数就绪状态，乱序选择发射
// 8 项，年龄优先（相对 ROB head 的距离最小）
// 约束（对齐五级语义的保守实现，面积远小于 LSQ）：
//   1. 访存指令按程序序发射：存在更老 mem 时不可发 mem
//   2. 系统指令（CSR/ecall/mret/fence.i）仅在 ROB head 时发射（提交点串行化）

`include "./include/pipeline_pkt_pkg.sv"

module issue_queue
import pipeline_pkt_pkg::*;
#(
    parameter int IQ_SIZE = 8
)(
    input               clk,
    input               rst,

    // ── 分配接口（Rename/Dispatch）──
    input               dispatch_en_i,
    input   rename2issue_pkt_t  dispatch_pkt_i,
    output              dispatch_ready_o,

    // ── 发射接口（到 RegRead + Execute）──
    output              issue_valid_o,
    output  issue2ex_pkt_t      issue_pkt_o,
    input               issue_ready_i,

    // 发射的物理源寄存器地址（供顶层读物理寄存器堆）
    output      [5:0]   issue_phys_rs1_o,
    output      [5:0]   issue_phys_rs2_o,

    // ── 唤醒接口（双路广播）──
    input               wakeup_en1_i,
    input       [5:0]   wakeup_preg1_i,
    input               wakeup_en2_i,
    input       [5:0]   wakeup_preg2_i,

    // ── ROB head：年龄比较 + 系统指令 oldest 约束 ──
    input       [4:0]   rob_head_i,

    // ── 刷新接口 ──
    input               flush_i
);

// 队列项结构
typedef struct packed {
    logic           valid;
    rob_idx_t       rob_idx;
    logic   [31:0]  pc;
    logic   [31:0]  inst;
    logic           pred_taken;
    phys_reg_t      phys_rs1;
    phys_reg_t      phys_rs2;
    phys_reg_t      phys_rd;
    logic           rd_wen;
    logic           rs1_ready;
    logic           rs2_ready;
    logic           exception;
    exc_cause_t     exception_cause;
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic   [31:0]  imm;
} iq_entry_t;

iq_entry_t iq [0:IQ_SIZE-1];

// ── 每项属性（组合）──
wire [IQ_SIZE-1:0] ent_valid;
wire [IQ_SIZE-1:0] ent_ready_ops;
wire [IQ_SIZE-1:0] ent_is_mem;
wire [IQ_SIZE-1:0] ent_is_sys;
wire [IQ_SIZE-1:0] ent_is_head;
wire [4:0]         ent_age [0:IQ_SIZE-1];

genvar gi;
generate
    for (gi = 0; gi < IQ_SIZE; gi++) begin : g_ent
        assign ent_valid[gi]     = iq[gi].valid;
        assign ent_ready_ops[gi] = iq[gi].rs1_ready & iq[gi].rs2_ready;
        assign ent_is_mem[gi]    = iq[gi].mem.cmd != MEM_NONE;
        // CSR / ecall / mret / fence.i：必须在 head 串行，对齐五级提交点
        assign ent_is_sys[gi]    = (iq[gi].sys.csr_cmd != CSR_CMD_NONE)
                                 | (iq[gi].sys.priv_redir != PRIV_REDIR_NONE)
                                 | iq[gi].sys.fence_i;
        assign ent_is_head[gi]   = (iq[gi].rob_idx == rob_head_i);
        assign ent_age[gi]       = iq[gi].rob_idx - rob_head_i;
    end
endgenerate

// 是否存在更老的 mem（年龄更小）—— 用于访存序
// older_mem_before[i] = 1 表示 i 之前还有未发 mem，i 不可发 mem
wire [IQ_SIZE-1:0] older_mem_before;
generate
    for (gi = 0; gi < IQ_SIZE; gi++) begin : g_ord
        logic any_older_mem;
        always_comb begin
            any_older_mem = 1'b0;
            for (int j = 0; j < IQ_SIZE; j++) begin
                if (j != gi)
                    any_older_mem = any_older_mem
                        | (ent_valid[j] & ent_is_mem[j] & (ent_age[j] < ent_age[gi]));
            end
        end
        assign older_mem_before[gi] = any_older_mem;
    end
endgenerate

// 可发射：操作数就绪 + mem 序 + sys 仅 head
wire [IQ_SIZE-1:0] ent_issuable;
generate
    for (gi = 0; gi < IQ_SIZE; gi++) begin : g_iss
        assign ent_issuable[gi] = ent_valid[gi] & ent_ready_ops[gi]
                                & (~ent_is_mem[gi] | ~older_mem_before[gi])
                                & (~ent_is_sys[gi] | ent_is_head[gi]);
    end
endgenerate

// ── 发射选择：issuable 中年龄最小 ──
logic [2:0] selected_idx;
logic       found_ready;
logic [4:0] min_age;

always_comb begin
    found_ready  = 1'b0;
    selected_idx = '0;
    min_age      = '1;
    for (int i = 0; i < IQ_SIZE; i++) begin
        if (ent_issuable[i] && (!found_ready || (ent_age[i] < min_age))) begin
            min_age      = ent_age[i];
            selected_idx = 3'(i);
            found_ready  = 1'b1;
        end
    end
end

wire issue_fire    = found_ready & issue_ready_i;
wire dispatch_fire = dispatch_en_i & dispatch_ready_o;

assign issue_valid_o    = found_ready;
assign issue_phys_rs1_o = iq[selected_idx].phys_rs1;
assign issue_phys_rs2_o = iq[selected_idx].phys_rs2;

assign issue_pkt_o.pc         = iq[selected_idx].pc;
assign issue_pkt_o.inst       = iq[selected_idx].inst;
assign issue_pkt_o.rob_idx    = iq[selected_idx].rob_idx;
assign issue_pkt_o.phys_rd    = iq[selected_idx].phys_rd;
assign issue_pkt_o.rs1_data   = '0;
assign issue_pkt_o.rs2_data   = '0;
assign issue_pkt_o.pred_taken = iq[selected_idx].pred_taken;
assign issue_pkt_o.rd_wen     = iq[selected_idx].rd_wen;
assign issue_pkt_o.exception  = iq[selected_idx].exception;
assign issue_pkt_o.exception_cause = iq[selected_idx].exception_cause;
assign issue_pkt_o.ex         = iq[selected_idx].ex;
assign issue_pkt_o.mem        = iq[selected_idx].mem;
assign issue_pkt_o.sys        = iq[selected_idx].sys;
assign issue_pkt_o.imm        = iq[selected_idx].imm;

// ── 空闲槽：优先编码器；同拍 issue 槽可复用 ──
logic [2:0] alloc_idx;
logic       alloc_has_slot;

always_comb begin
    alloc_has_slot = 1'b0;
    alloc_idx      = '0;
    for (int i = 0; i < IQ_SIZE; i++) begin
        if ((!iq[i].valid || (3'(i) == selected_idx && issue_fire)) && !alloc_has_slot) begin
            alloc_idx      = 3'(i);
            alloc_has_slot = 1'b1;
        end
    end
end

assign dispatch_ready_o = alloc_has_slot;

// ── 时序：唤醒 / 发射 / 分配 ──
// valid 与 payload 同步更新，保持同一 always_ff 语义一致
always_ff @(posedge clk) begin
    if (rst || flush_i) begin
        for (int i = 0; i < IQ_SIZE; i++)
            iq[i].valid <= 1'b0;
    end else begin
        if (wakeup_en1_i || wakeup_en2_i) begin
            for (int i = 0; i < IQ_SIZE; i++) begin
                if (iq[i].valid) begin
                    if (wakeup_en1_i && iq[i].phys_rs1 == wakeup_preg1_i) iq[i].rs1_ready <= 1'b1;
                    if (wakeup_en1_i && iq[i].phys_rs2 == wakeup_preg1_i) iq[i].rs2_ready <= 1'b1;
                    if (wakeup_en2_i && iq[i].phys_rs1 == wakeup_preg2_i) iq[i].rs1_ready <= 1'b1;
                    if (wakeup_en2_i && iq[i].phys_rs2 == wakeup_preg2_i) iq[i].rs2_ready <= 1'b1;
                end
            end
        end

        if (issue_fire)
            iq[selected_idx].valid <= 1'b0;

        if (dispatch_fire) begin
            iq[alloc_idx].valid      <= 1'b1;
            iq[alloc_idx].rob_idx    <= dispatch_pkt_i.rob_idx;
            iq[alloc_idx].pc         <= dispatch_pkt_i.pc;
            iq[alloc_idx].inst       <= dispatch_pkt_i.inst;
            iq[alloc_idx].pred_taken <= dispatch_pkt_i.pred_taken;
            iq[alloc_idx].phys_rs1   <= dispatch_pkt_i.phys_rs1;
            iq[alloc_idx].phys_rs2   <= dispatch_pkt_i.phys_rs2;
            iq[alloc_idx].phys_rd    <= dispatch_pkt_i.phys_rd;
            iq[alloc_idx].rd_wen     <= dispatch_pkt_i.rd_wen;
            iq[alloc_idx].rs1_ready  <= dispatch_pkt_i.rs1_ready;
            iq[alloc_idx].rs2_ready  <= dispatch_pkt_i.rs2_ready;
            iq[alloc_idx].exception  <= dispatch_pkt_i.exception;
            iq[alloc_idx].exception_cause <= dispatch_pkt_i.exception_cause;
            iq[alloc_idx].ex         <= dispatch_pkt_i.ex;
            iq[alloc_idx].mem        <= dispatch_pkt_i.mem;
            iq[alloc_idx].sys        <= dispatch_pkt_i.sys;
            iq[alloc_idx].imm        <= dispatch_pkt_i.imm;
        end
    end
end

endmodule
