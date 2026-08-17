// 发射队列（Issue Queue）
// 存储等待执行的指令，跟踪操作数就绪状态，乱序选择发射
// 8 项，年龄优先（ROB index 最小的就绪指令先发射）
// 修正：
//   1. 用优先编码器替代 break 实现空闲槽查找（可综合）
//   2. 同拍 issue + dispatch 时直接复用被发射的槽（无气泡）

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

    // ── 唤醒接口（执行单元写回，广播物理寄存器编号）──
    input               wakeup_en_i,
    input       [5:0]   wakeup_preg_i,

    // ── ROB head：年龄比较用（(rob_idx - head) mod 32，避免 tail 回绕后年龄颠倒）──
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
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic   [31:0]  imm;
} iq_entry_t;

iq_entry_t iq [0:IQ_SIZE-1];

// ── 发射选择：年龄优先（相对 ROB head 的距离最小）──
// 不能直接比绝对 rob_idx：ROB 回绕后 younger 的 idx 可能数值更小。
logic [2:0] selected_idx;
logic       found_ready;
logic [4:0] min_age;
logic [4:0] cand_age;

always_comb begin
    found_ready  = 1'b0;
    selected_idx = '0;
    min_age      = '1;
    cand_age     = '0;
    for (int i = 0; i < IQ_SIZE; i++) begin
        // mod-32 无符号减法 = 相对 head 的年龄
        cand_age = iq[i].rob_idx - rob_head_i;
        if (iq[i].valid & iq[i].rs1_ready & iq[i].rs2_ready) begin
            if (!found_ready || (cand_age < min_age)) begin
                min_age      = cand_age;
                selected_idx = 3'(i);
                found_ready  = 1'b1;
            end
        end
    end
end

wire issue_fire   = found_ready & issue_ready_i;
wire dispatch_fire = dispatch_en_i & dispatch_ready_o;

assign issue_valid_o     = found_ready;
assign issue_phys_rs1_o  = iq[selected_idx].phys_rs1;
assign issue_phys_rs2_o  = iq[selected_idx].phys_rs2;

// rs1/rs2 data 由顶层从物理寄存器堆读取后填入，此处先输出地址
assign issue_pkt_o.pc         = iq[selected_idx].pc;
assign issue_pkt_o.inst       = iq[selected_idx].inst;
assign issue_pkt_o.rob_idx    = iq[selected_idx].rob_idx;
assign issue_pkt_o.phys_rd    = iq[selected_idx].phys_rd;
assign issue_pkt_o.rs1_data   = '0; // 由顶层用物理寄存器堆读出后覆盖
assign issue_pkt_o.rs2_data   = '0;
assign issue_pkt_o.pred_taken = iq[selected_idx].pred_taken;
assign issue_pkt_o.rd_wen     = iq[selected_idx].rd_wen;
assign issue_pkt_o.ex         = iq[selected_idx].ex;
assign issue_pkt_o.mem        = iq[selected_idx].mem;
assign issue_pkt_o.sys        = iq[selected_idx].sys;
assign issue_pkt_o.imm        = iq[selected_idx].imm;

// ── 空闲槽优先编码器 ──
// 关键优化：若本拍正在发射某槽（issue_fire），则该槽视为空闲可直接复用，
// 避免 dispatch 等到下拍才能写入（消除一拍气泡）。
logic [2:0] alloc_idx;
logic       alloc_has_slot;

always_comb begin
    alloc_has_slot = 1'b0;
    alloc_idx      = '0;
    for (int i = 0; i < IQ_SIZE; i++) begin
        // 该槽为空，或本拍正在发射该槽（同拍复用）
        if ((!iq[i].valid || (3'(i) == selected_idx && issue_fire)) && !alloc_has_slot) begin
            alloc_idx      = 3'(i);
            alloc_has_slot = 1'b1;
        end
    end
end

assign dispatch_ready_o = alloc_has_slot;

// ── 时序逻辑：唤醒、发射、分配 ──
always_ff @(posedge clk) begin
    if (rst || flush_i) begin
        for (int i = 0; i < IQ_SIZE; i++)
            iq[i].valid <= 1'b0;
    end else begin
        // 1. 唤醒：广播写回的物理寄存器，更新队列中所有匹配项的就绪位
        if (wakeup_en_i) begin
            for (int i = 0; i < IQ_SIZE; i++) begin
                if (iq[i].valid) begin
                    if (iq[i].phys_rs1 == wakeup_preg_i) iq[i].rs1_ready <= 1'b1;
                    if (iq[i].phys_rs2 == wakeup_preg_i) iq[i].rs2_ready <= 1'b1;
                end
            end
        end

        // 2. 发射：将对应槽标为无效（若 dispatch 也在同拍写同槽，dispatch 最终覆盖 valid=1）
        if (issue_fire)
            iq[selected_idx].valid <= 1'b0;

        // 3. 分配：将新指令写入空闲槽
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
            iq[alloc_idx].ex         <= dispatch_pkt_i.ex;
            iq[alloc_idx].mem        <= dispatch_pkt_i.mem;
            iq[alloc_idx].sys        <= dispatch_pkt_i.sys;
            iq[alloc_idx].imm        <= dispatch_pkt_i.imm;
        end
    end
end

endmodule
