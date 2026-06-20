`include "./include/pipeline_pkt_pkg.sv"

module branch_predictor
import pipeline_pkt_pkg::*;
#(
    parameter int BTB_ENTRIES = 4,
    parameter int BHT_ENTRIES = 32,

    localparam int BTB_IDX_WIDTH = (BTB_ENTRIES <= 2) ? 1 : $clog2(BTB_ENTRIES),
    localparam int BHT_IDX_WIDTH = (BHT_ENTRIES <= 2) ? 1 : $clog2(BHT_ENTRIES)
)(
    input               clk,
    input               rst,

    input   [31:0]      pc_i,
    output              pred_taken_o,
    output  [31:0]      pred_pc_o,

    input   bp_update_t update_i,
    input               inval_i
);

//============================================================
// 1. BTB/BHT 存储
//============================================================
// 当前 NPC 不实现 C 扩展，控制流目标按 4 字节对齐处理，低两位不进 BTB。
logic                       btb_valid      [BTB_ENTRIES-1:0];
logic   [29:0]              btb_pc_tag     [BTB_ENTRIES-1:0];
logic   [29:0]              btb_target     [BTB_ENTRIES-1:0];
logic                       btb_is_branch  [BTB_ENTRIES-1:0];

// 2-bit 饱和计数器：0/1 预测不跳，2/3 预测跳。
logic   [1:0]               bht_counter    [BHT_ENTRIES-1:0];
logic   [BTB_IDX_WIDTH-1:0] replace_ptr;


//============================================================
// 2. 预测路径：全相联查 BTB，BHT 只决定条件分支方向
//============================================================
wire [29:0] pc_tag  = pc_i[31:2];
wire [31:0] pc_next = pc_i + 32'd4;
wire [BHT_IDX_WIDTH-1:0] pred_bht_idx = pc_i[2 +: BHT_IDX_WIDTH];

logic                       pred_hit;
logic   [BTB_IDX_WIDTH-1:0] pred_way;

integer pred_i;

always_comb begin
    pred_hit = 1'b0;
    pred_way = '0;

    for (pred_i = 0; pred_i < BTB_ENTRIES; pred_i = pred_i + 1) begin
        if (~pred_hit & btb_valid[pred_i] & (btb_pc_tag[pred_i] == pc_tag)) begin
            pred_hit = 1'b1;
            pred_way = BTB_IDX_WIDTH'(pred_i);
        end
    end
end

wire pred_is_branch = btb_is_branch[pred_way];
wire pred_bht_taken = bht_counter[pred_bht_idx][1];

assign pred_taken_o = pred_hit & (~pred_is_branch | pred_bht_taken);
assign pred_pc_o    = pred_taken_o ? {btb_target[pred_way], 2'b00} : pc_next;


//============================================================
// 3. 更新路径：branch 训练 BHT，taken branch/JAL 写 BTB
//============================================================
wire update_is_branch = update_i.valid & update_i.is_branch;
wire update_is_jal    = update_i.valid & update_i.is_jal;
wire btb_write        = update_is_jal | (update_is_branch & update_i.taken);

wire [29:0] update_tag    = update_i.pc[31:2];
wire [29:0] update_target = update_i.target[31:2];
wire [BHT_IDX_WIDTH-1:0] update_bht_idx = update_i.pc[2 +: BHT_IDX_WIDTH];

logic                       update_hit;
logic   [BTB_IDX_WIDTH-1:0] update_hit_way;
logic                       has_invalid;
logic   [BTB_IDX_WIDTH-1:0] invalid_way;
logic   [BTB_IDX_WIDTH-1:0] write_way;

integer update_i_idx;

always_comb begin
    update_hit     = 1'b0;
    update_hit_way = '0;
    has_invalid    = 1'b0;
    invalid_way    = '0;

    for (update_i_idx = 0; update_i_idx < BTB_ENTRIES; update_i_idx = update_i_idx + 1) begin
        if (~update_hit & btb_valid[update_i_idx] & (btb_pc_tag[update_i_idx] == update_tag)) begin
            update_hit     = 1'b1;
            update_hit_way = BTB_IDX_WIDTH'(update_i_idx);
        end

        if (~has_invalid & ~btb_valid[update_i_idx]) begin
            has_invalid = 1'b1;
            invalid_way = BTB_IDX_WIDTH'(update_i_idx);
        end
    end
end

assign write_way = update_hit  ? update_hit_way :
                   has_invalid ? invalid_way    :
                                 replace_ptr;


//============================================================
// 4. 时序更新
//============================================================
integer j;

always_ff @(posedge clk) begin
    if (rst | inval_i) begin
        for (j = 0; j < BTB_ENTRIES; j = j + 1) begin
            btb_valid[j] <= 1'b0;
        end
        replace_ptr <= '0;
    end else if (btb_write) begin
        btb_valid[write_way]     <= 1'b1;
        btb_pc_tag[write_way]    <= update_tag;
        btb_target[write_way]    <= update_target;
        btb_is_branch[write_way] <= update_i.is_branch;

        // 命中或填空项不改变替换指针；真正替换有效项时才轮转。
        if (~update_hit & ~has_invalid) begin
            replace_ptr <= replace_ptr + BTB_IDX_WIDTH'(1);
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (j = 0; j < BHT_ENTRIES; j = j + 1) begin
            bht_counter[j] <= 2'b01;      // 弱不跳
        end
    end else if (update_is_branch) begin
        if (update_i.taken) begin
            if (bht_counter[update_bht_idx] != 2'b11) begin
                bht_counter[update_bht_idx] <= bht_counter[update_bht_idx] + 2'b01;
            end
        end else begin
            if (bht_counter[update_bht_idx] != 2'b00) begin
                bht_counter[update_bht_idx] <= bht_counter[update_bht_idx] - 2'b01;
            end
        end
    end
end

endmodule
