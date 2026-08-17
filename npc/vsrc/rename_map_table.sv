// 重命名映射表（Rename Map Table）
// 维护架构寄存器到物理寄存器的推测映射（speculative RAT）
// 同时维护架构映射表（Architectural Map Table, AMT）：
//   - commit 时更新 AMT
//   - flush 时用 AMT 恢复 RAT
// 同拍 commit+flush（分支误预测提交）：先把 commit 合入 AMT，再恢复 RAT
// 初始恒等映射：x0→p0 ... x31→p31

module rename_map_table #(
    parameter int NUM_ARCH_REGS = 32
)(
    input               clk,
    input               rst,

    input       [4:0]   rs1_arch_i,
    input       [4:0]   rs2_arch_i,
    input       [4:0]   rd_arch_i,
    output      [5:0]   rs1_phys_o,
    output      [5:0]   rs2_phys_o,
    output      [5:0]   rd_phys_old_o,

    input               update_en_i,
    input       [4:0]   update_arch_i,
    input       [5:0]   update_phys_i,

    input               commit_en_i,
    input       [4:0]   commit_arch_i,
    input       [5:0]   commit_phys_i,

    input               flush_i,

    // 给 freelist 的 AMT 快照（含本拍 commit bypass）
    output      [5:0]   amt_snapshot_o [0:NUM_ARCH_REGS-1]
);

logic [5:0] map_table [0:NUM_ARCH_REGS-1];
logic [5:0] arch_map  [0:NUM_ARCH_REGS-1];

assign rs1_phys_o    = map_table[rs1_arch_i];
assign rs2_phys_o    = map_table[rs2_arch_i];
assign rd_phys_old_o = map_table[rd_arch_i];

// next AMT = arch_map 合入本拍 commit（组合），供 freelist flush 重建
logic [5:0] next_amt [0:NUM_ARCH_REGS-1];
always_comb begin
    for (int i = 0; i < NUM_ARCH_REGS; i++) begin
        next_amt[i] = arch_map[i];
    end
    if (commit_en_i)
        next_amt[commit_arch_i] = commit_phys_i;
end

genvar gi;
generate
    for (gi = 0; gi < NUM_ARCH_REGS; gi++) begin : g_amt
        assign amt_snapshot_o[gi] = next_amt[gi];
    end
endgenerate

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_ARCH_REGS; i++) begin
            map_table[i] <= 6'(i);
            arch_map[i]  <= 6'(i);
        end
    end else begin
        // 1) 先提交到 AMT（即使同拍 flush 也要提交 head）
        if (commit_en_i)
            arch_map[commit_arch_i] <= commit_phys_i;

        // 2) flush：RAT 恢复到 next AMT（含本拍 commit）
        if (flush_i) begin
            for (int i = 0; i < NUM_ARCH_REGS; i++) begin
                if (commit_en_i && (commit_arch_i == 5'(i)))
                    map_table[i] <= commit_phys_i;
                else
                    map_table[i] <= arch_map[i];
            end
        end else if (update_en_i) begin
            map_table[update_arch_i] <= update_phys_i;
        end
    end
end

endmodule
