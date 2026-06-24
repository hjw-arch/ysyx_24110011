module BPU #(
    parameter   ADDR_WIDTH  =   32,
    parameter   BTB_ENTRIES =   4,
    parameter   BHT_ENTRIES =   32,

    localparam  BTB_INDEX_WIDTH     =   $clog2(BTB_ENTRIES),
    localparam  BHT_INDEX_WIDTH     =   $clog2(BHT_ENTRIES),
    localparam  TAG_WIDTH           =   ADDR_WIDTH - 2,
    localparam  TARGET_WIDTH        =   ADDR_WIDTH - 2
)(
    input                       clk,
    input                       rst,

    // predict
    input   [ADDR_WIDTH-1:0]    pc_i,
    output                      pred_taken_o,
    output  [ADDR_WIDTH-1:0]    pred_pc_o,

    // update
    input                       update_valid_i,
    input                       update_type_i,      // 0: branch   1: jal       不预测jalr
    input                       update_taken_i,
    input   [ADDR_WIDTH-1:0]    update_pc_i,
    input   [ADDR_WIDTH-1:0]    update_target_i,

    input                       inval_i
);

// ============================================================
// BPU = BTB target lookup + BHT direction lookup
//
// update_type_i:
//   0: branch
//   1: jal
//
// jalr 暂不进入 BPU，外部不应对 jalr 拉高 update_valid_i。
// ============================================================
wire                        btb_lookup_hit;
wire    [ADDR_WIDTH-1:0]    btb_lookup_target;
wire                        btb_lookup_type;        // 0: branch    1: jal

wire                        bht_lookup_valid;
wire                        bht_lookup_taken;

wire                        btb_update_valid;
wire                        bht_update_valid;

assign bht_lookup_valid = btb_lookup_hit & ~btb_lookup_type;

// BTB 只保存会跳到 target 的 direct CFI：
//   jal          : 总是写 BTB
//   taken branch : 写 BTB
//   not-taken branch 不写 BTB，顺序 pc+4 就是正确路径。
assign btb_update_valid = update_valid_i & (update_type_i | update_taken_i);

// BHT 只训练条件分支方向。
assign bht_update_valid = update_valid_i & ~update_type_i;

BTB #(
    .PC_WIDTH   (ADDR_WIDTH),
    .ENTRIES    (BTB_ENTRIES)
) u_BTB (
    .clk                (clk),
    .rst                (rst),
    .lookup_pc_i        (pc_i),
    .lookup_hit_o       (btb_lookup_hit),
    .lookup_target_o    (btb_lookup_target),
    .lookup_type_o      (btb_lookup_type),
    .update_valid_i     (btb_update_valid),
    .update_type_i      (update_type_i),
    .update_pc_i        (update_pc_i),
    .update_target_i    (update_target_i),
    .inval_i            (inval_i)
);

BHT #(
    .PC_WIDTH   (ADDR_WIDTH),
    .ENTRIES    (BHT_ENTRIES)
) u_BHT (
    .clk                (clk),
    .rst                (rst),
    .lookup_valid_i     (bht_lookup_valid),
    .lookup_pc_i        (pc_i),
    .lookup_taken_o     (bht_lookup_taken),
    .update_valid_i     (bht_update_valid),
    .update_pc_i        (update_pc_i),
    .update_taken_i     (update_taken_i)
);

assign pred_taken_o = btb_lookup_hit & (btb_lookup_type | bht_lookup_taken);
assign pred_pc_o    = pred_taken_o ? btb_lookup_target : pc_i + 32'd4;



endmodule




module BTB #(
    parameter   PC_WIDTH    =   32,
    parameter   ENTRIES     =   2
) (
    input                               clk,
    input                               rst,

    input   logic   [PC_WIDTH-1:0]      lookup_pc_i,

    output  logic                       lookup_hit_o,
    output  logic   [PC_WIDTH-1:0]      lookup_target_o,
    output  logic                       lookup_type_o,          // 0: branch    1: jal

    input   logic                       update_valid_i,
    input   logic                       update_type_i,          // 0: branch    1: jal
    input   logic   [PC_WIDTH-1:0]      update_pc_i,
    input   logic   [PC_WIDTH-1:0]      update_target_i,

    input   logic                       inval_i
);

localparam  TAG_WIDTH   =   PC_WIDTH - 2;           // 4字节对齐
localparam  RR_PTR_INIT =   'd1;

// ============================================================
// BTB entry storage
// ============================================================
logic   [ENTRIES-1:0]                   valid_q;
logic   [ENTRIES-1:0][PC_WIDTH-1:0]     target_q;
logic   [ENTRIES-1:0][TAG_WIDTH-1:0]    tag_q;
logic   [ENTRIES-1:0]                   br_type_q;          // 0: branch    1: jal

logic   [ENTRIES-1:0]                   rr_ptr_q;           // round-robin replacement pointer

// ============================================================
// tag generation
// ============================================================
logic   [TAG_WIDTH-1:0]     lookup_tag;
logic   [TAG_WIDTH-1:0]     update_tag;

assign  lookup_tag  =   lookup_pc_i[PC_WIDTH-1:2];
assign  update_tag  =   update_pc_i[PC_WIDTH-1:2];


// ============================================================
// lookup compare
// ============================================================
logic                   lookup_enable;
logic   [ENTRIES-1:0]   lookup_match;

assign  lookup_enable   =   ~inval_i;

genvar  i;
generate
    for (i = 0; i < ENTRIES; i = i + 1) begin : gen_lookup_compare
        assign  lookup_match[i] = lookup_enable & valid_q[i] & (tag_q[i] == lookup_tag);
    end 
endgenerate

assign  lookup_hit_o    =   |lookup_match;

Mux1H #(
    .WIDTH   (PC_WIDTH),
    .ENTRIES (ENTRIES)
) u_lookup_target_mux (
    .sel_i  (lookup_match),
    .data_i (target_q),
    .data_o (lookup_target_o)
);

assign  lookup_type_o   =   |(lookup_match & br_type_q);

// ============================================================
// update compare
//
// 命中已有项：更新原 entry
// miss：写 rr_ptr_q 指向的 entry
// ============================================================

logic               update_en;
logic [ENTRIES-1:0] update_match;
logic               update_hit;

assign  update_en   =   update_valid_i & ~inval_i;

generate
    for (i = 0; i < ENTRIES; i = i + 1) begin : gen_update_match
        assign update_match[i] = update_en & valid_q[i] & (tag_q[i] == update_tag);
    end
endgenerate

assign update_hit = |update_match;


// one-hot round-robin pointer
logic [ENTRIES-1:0]                 rr_ptr_next;

generate
    if (ENTRIES == 1) begin
        assign rr_ptr_next = 1'b1;
    end else begin
        assign rr_ptr_next = {rr_ptr_q[ENTRIES-2:0], rr_ptr_q[ENTRIES-1]};
    end
endgenerate

logic                   new_alloc;
logic [ENTRIES-1:0]     write_oh;

assign  new_alloc   =   update_en & ~update_hit;
assign  write_oh    =   update_match | ({ENTRIES{new_alloc}} & rr_ptr_q);   // 如果 hit，write_oh = update_match, 如果 miss，write_oh = rr_ptr_q


always_ff @(posedge clk) begin
    if (rst | inval_i) begin
        valid_q <= '0;
    end else begin
        valid_q <= write_oh | valid_q;
    end 
end 


always_ff @(posedge clk) begin
    for (int k = 0; k < ENTRIES; k = k + 1) begin
        if (write_oh[k]) begin
            tag_q[k] <= update_tag;
        end 
    end 
end 

always_ff @(posedge clk) begin
    for (int k = 0; k < ENTRIES; k = k + 1) begin
        if (write_oh[k]) begin
            target_q[k] <= update_target_i;
        end 
    end 
end 

always_ff @(posedge clk) begin
    for (int k = 0; k < ENTRIES; k = k + 1) begin
        if (write_oh[k]) begin
            br_type_q[k] <= update_type_i;
        end 
    end 
end 

always_ff @(posedge clk) begin
    if (rst | inval_i) begin
        rr_ptr_q <= RR_PTR_INIT;
    end else begin
        rr_ptr_q <= new_alloc ? rr_ptr_next : rr_ptr_q;
    end 
end 


endmodule




module BHT # (
    parameter   PC_WIDTH    =   32,
    parameter   ENTRIES     =   32
) (
    input                               clk,
    input                               rst,

    input   logic                       lookup_valid_i,
    input   logic   [PC_WIDTH-1:0]      lookup_pc_i,
    output  logic                       lookup_taken_o,
    
    
    input   logic                       update_valid_i,
    input   logic   [PC_WIDTH-1:0]      update_pc_i,
    input   logic                       update_taken_i
);

localparam      INIT_STATE      =   2'b01;
localparam      INDEX_W         =   $clog2(ENTRIES);


logic   [1:0]   bht_q   [0:ENTRIES-1];      // bht 本体

/*****************************************************
**  查找
******************************************************/

wire    [INDEX_W-1:0]   lookup_idx;
assign  lookup_idx  =   lookup_pc_i[2+INDEX_W-1:2];


wire    [1:0]   lookup_counter;
assign  lookup_counter  =   bht_q[lookup_idx];
assign  lookup_taken_o  =   lookup_counter[1] & lookup_valid_i;         // 几乎没有时序压力


/*****************************************************
**  更新
******************************************************/

wire    [INDEX_W-1:0]   update_idx;
assign  update_idx  =   update_pc_i[2+INDEX_W-1:2];

wire    [1:0]   update_counter_old;
assign  update_counter_old  =   bht_q[update_idx];

wire    [1:0]   update_counter_next;

// 直接真值表计算：
// taken：              not taken:
// 00 -> 01             // 00 -> 00
// 01 -> 10             // 01 -> 00
// 10 -> 11             // 10 -> 01
// 11 -> 11             // 11 -> 10

wire    c1;
wire    c0;
assign  c1  =   update_counter_old[1];
assign  c0  =   update_counter_old[0];

wire    [1:0]   update_counter_next_taken;
wire    [1:0]   update_counter_next_not_taken;

assign  update_counter_next_taken[1]    =   c1 | c0;
assign  update_counter_next_taken[0]    =   c1 | ~c0;
assign  update_counter_next_not_taken[1]    =   c1 & c0;
assign  update_counter_next_not_taken[0]    =   c1 & ~c0;

assign  update_counter_next     =   update_taken_i ? update_counter_next_taken : update_counter_next_not_taken;

integer k;

always_ff @(posedge clk) begin 
    if (rst) begin
        for (k = 0; k < ENTRIES; k = k + 1) begin
            bht_q[k] <= INIT_STATE;
        end
    end else begin
        if (update_valid_i) begin
            bht_q[update_idx] <= update_counter_next;
        end
    end
end


endmodule



module Mux1H #(
    parameter int WIDTH   = 32,
    parameter int ENTRIES = 2
) (
    input  logic [ENTRIES-1:0]             sel_i,
    input  logic [ENTRIES-1:0][WIDTH-1:0]  data_i,
    output logic [WIDTH-1:0]               data_o
);
    integer i;

    always_comb begin
        data_o = '0;

        for (i = 0; i < ENTRIES; i = i + 1) begin
            data_o = data_o | ({WIDTH{sel_i[i]}} & data_i[i]);
        end
    end
endmodule
