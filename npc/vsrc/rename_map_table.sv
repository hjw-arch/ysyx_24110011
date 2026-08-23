// 重命名映射表（Rename Map Table）
//
// map_table：推测映射，Rename 查询和更新。
// arch_map ：已提交映射，异常/全局 flush 时恢复。
// snapshots：四份稀疏推测快照；分支误预测先恢复最近的旧快照，再由
//            Rename 控制器按 ROB 顺序重放快照之后的目的寄存器映射。

module rename_map_table #(
    parameter int NUM_ARCH_REGS = 32,
    parameter int NUM_SNAPSHOTS = 4
) (
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

    input               snapshot_en_i,
    input       [$clog2(NUM_SNAPSHOTS)-1:0] snapshot_slot_i,

    input               recover_en_i,
    input               recover_snapshot_hit_i,
    input       [$clog2(NUM_SNAPSHOTS)-1:0] recover_snapshot_slot_i,

    input               walk_en_i,
    input       [4:0]   walk_arch_i,
    input       [5:0]   walk_phys_i,

    input               flush_i
);

logic [5:0] map_table    [0:NUM_ARCH_REGS-1];
logic [5:0] arch_map     [0:NUM_ARCH_REGS-1];
logic [5:0] snapshot_map [0:NUM_SNAPSHOTS-1][0:NUM_ARCH_REGS-1];

assign rs1_phys_o    = map_table[rs1_arch_i];
assign rs2_phys_o    = map_table[rs2_arch_i];
assign rd_phys_old_o = map_table[rd_arch_i];

always_ff @(posedge clk) begin
    if (rst) begin
        for (int i = 0; i < NUM_ARCH_REGS; i++) begin
            map_table[i] <= 6'(i);
            arch_map[i]  <= 6'(i);
        end
    end else begin
        if (commit_en_i)
            arch_map[commit_arch_i] <= commit_phys_i;

        if (flush_i) begin
            // 同拍提交必须进入恢复后的推测映射。
            for (int i = 0; i < NUM_ARCH_REGS; i++) begin
                map_table[i] <= (commit_en_i && (commit_arch_i == 5'(i)))
                    ? commit_phys_i
                    : arch_map[i];
            end
        end else if (recover_en_i) begin
            // 未命中快照时从包含本拍提交的体系结构映射开始 Walk。
            for (int i = 0; i < NUM_ARCH_REGS; i++) begin
                if (recover_snapshot_hit_i)
                    map_table[i] <= snapshot_map[recover_snapshot_slot_i][i];
                else
                    map_table[i] <= (commit_en_i && (commit_arch_i == 5'(i)))
                        ? commit_phys_i
                        : arch_map[i];
            end
        end else begin
            if (walk_en_i)
                map_table[walk_arch_i] <= walk_phys_i;
            else if (update_en_i)
                map_table[update_arch_i] <= update_phys_i;
        end

        if (snapshot_en_i) begin
            // 快照对应“本条指令完成重命名之后”的状态。
            for (int i = 0; i < NUM_ARCH_REGS; i++) begin
                snapshot_map[snapshot_slot_i][i] <=
                    (update_en_i && (update_arch_i == 5'(i)))
                        ? update_phys_i
                        : map_table[i];
            end
        end
    end
end

endmodule
