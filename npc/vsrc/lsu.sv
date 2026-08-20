// lsu — Load/Store
// Load：CAM 全覆盖 → STLF 同拍 complete；部分重叠 → stall；无重叠 → 阻塞 AXI 读
// Store：issue 入 SQ（data=rs2 原值）同拍 complete；AXI 写仅 commit drain
// 不变量：
//   1. store 不得在 commit 前进入 AXI
//   2. 子字摆放只在 master / SQ CAM；SQ 存 rs2 原值
//   3. drain 优先占 AXI；STLF 不占 AXI，可与 drain 同拍 complete
//   4. sq_alloc_strb 仅供 CAM；写通道 WSTRB 由 master 按 addr/size 生成
//   5. drain_strb 不驱动总线（同上）；保留口便于调试/对齐 SQ

`include "./include/pipeline_pkt_pkg.sv"

module lsu
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    // 来自 issue_queue
    input               valid_i,
    input   issue2ex_pkt_t data_i,
    output              ready_o,

    input               flush_i,

    // 完成 → ROB（load AXI/STLF；store 入 SQ 后同拍 complete）
    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,
    output logic [31:0] complete_data_o,
    output logic        complete_exception_o,
    output logic [3:0]  complete_cause_o,
    output logic        complete_rd_wen_o,
    output logic [5:0]  complete_phys_rd_o,

    // ── SQ alloc（store issue）──
    output logic        sq_alloc_en_o,
    output logic [4:0]  sq_alloc_rob_idx_o,
    output logic [31:0] sq_alloc_addr_o,
    output logic [31:0] sq_alloc_data_o,
    output logic [3:0]  sq_alloc_strb_o,
    output logic [1:0]  sq_alloc_size_o,
    input               sq_alloc_ready_i,

    // ── SQ CAM（load）──
    output logic [31:0] cam_addr_o,
    output logic [1:0]  cam_size_o,
    input               cam_hit_i,
    input               cam_stall_i,
    input       [31:0]  cam_data_i,

    // ── SQ drain（commit 后写）──
    input               drain_req_i,
    input       [31:0]  drain_addr_i,
    input       [31:0]  drain_data_i,
    input       [3:0]   drain_strb_i,
    input       [1:0]   drain_size_i,
    output logic        drain_fire_o,
    output logic        drain_done_o,
    output logic        drain_fault_o,

    // AXI 读
    output logic [31:0] ARADDR,
    output logic [3:0]  ARID,
    output logic [7:0]  ARLEN,
    output logic [2:0]  ARSIZE,
    output logic [1:0]  ARBURST,
    output logic        ARVALID,
    input               ARREADY,

    input        [3:0]  RID,
    input        [31:0] RDATA,
    input        [1:0]  RRESP,
    input               RVALID,
    input               RLAST,
    output logic        RREADY,

    // AXI 写
    output logic [31:0] AWADDR,
    output logic [7:0]  AWLEN,
    output logic [2:0]  AWSIZE,
    output logic [3:0]  AWID,
    output logic [1:0]  AWBURST,
    output logic        AWVALID,
    input               AWREADY,

    output logic [31:0] WDATA,
    output logic        WLAST,
    output logic [3:0]  WSTRB,
    output logic        WVALID,
    input               WREADY,

    input        [3:0]  BID,
    input        [1:0]  BRESP,
    input               BVALID,
    output logic        BREADY
);

// 状态：空闲 / load 等响应 / store drain 等 B
typedef enum logic [1:0] {
    S_IDLE,
    S_LOAD,
    S_DRAIN
} state_t;

state_t state, nstate;

typedef struct packed {
    logic        is_load;
    logic        is_store;
    logic [4:0]  rob_idx;
    logic [5:0]  phys_rd;
    logic        rd_wen;
    logic [2:0]  mem_type;
    logic [31:0] mem_addr;
    logic [31:0] store_data;
} lsu_req_t;

lsu_req_t req_stage_in;
lsu_req_t req_stage_out;
wire      req_stage_pre_valid;
wire      req_stage_pre_ready;
wire      req_stage_valid;
wire      req_stage_ready;

wire pre_is_load  = data_i.mem.cmd == MEM_LOAD;
wire pre_is_store = data_i.mem.cmd == MEM_STORE;

assign req_stage_in.is_load    = pre_is_load;
assign req_stage_in.is_store   = pre_is_store;
assign req_stage_in.rob_idx    = data_i.rob_idx;
assign req_stage_in.phys_rd    = data_i.phys_rd;
assign req_stage_in.rd_wen     = data_i.rd_wen;
assign req_stage_in.mem_type   = data_i.funct3;
assign req_stage_in.mem_addr   = data_i.rs1_data + data_i.imm;
assign req_stage_in.store_data = data_i.rs2_data;
assign req_stage_pre_valid     = valid_i & (pre_is_load | pre_is_store) & ~flush_i;

pip_reg #(
    .WIDTH ($bits(lsu_req_t))
) u_req_stage (
    .clk        (clk),
    .rst        (rst),
    .flush      (flush_i),
    .pre_valid  (req_stage_pre_valid),
    .pre_data   (req_stage_in),
    .pre_ready  (req_stage_pre_ready),
    .next_valid (req_stage_valid),
    .next_data  (req_stage_out),
    .next_ready (req_stage_ready)
);

wire is_load   = req_stage_out.is_load;
wire is_store  = req_stage_out.is_store;
wire mem_valid = req_stage_valid;

wire state_idle  = (state == S_IDLE);
wire state_load  /* verilator public_flat_rd */ = (state == S_LOAD);
wire state_drain /* verilator public_flat_rd */ = (state == S_DRAIN);

logic        axi_done;
logic [31:0] axi_rdata /* verilator public_flat_rd */;
logic [1:0]  axi_rresp;
logic [1:0]  axi_wresp;

// load 锁存（仅 AXI 路径）
logic        hold_is_load /* verilator public_flat_rd */;
logic [4:0]  hold_rob_idx;
logic [5:0]  hold_phys_rd;
logic        hold_rd_wen;
logic [2:0]  hold_mem_type;
logic [31:0] hold_mem_addr /* verilator public_flat_rd */;
logic        hold_flushed;

wire [31:0] req_mem_addr   = req_stage_out.mem_addr;
wire [31:0] req_store_data = req_stage_out.store_data;
wire [2:0]  req_mem_type   = req_stage_out.mem_type;
wire [1:0]  req_size       = req_mem_type[1:0];

// CAM 查询口（组合）
assign cam_addr_o = req_mem_addr;
assign cam_size_o = req_size;

// strb：入 SQ 供 CAM；不驱动 AXI WSTRB
logic [3:0] req_strb;
always_comb begin
    unique case (req_size)
        2'b00:   req_strb = 4'b0001 << req_mem_addr[1:0];
        2'b01:   req_strb = 4'b0011 << {req_mem_addr[1], 1'b0};
        default: req_strb = 4'b1111;
    endcase
end

// store：idle + SQ 有槽 + 本拍无 drain（commit 写优先）
wire store_issue_ok = state_idle & mem_valid & is_store
                    & sq_alloc_ready_i & ~flush_i & ~drain_req_i;

// STLF：全覆盖命中；不占 AXI，idle/drain 均可同拍 complete
wire load_stlf_ok = mem_valid & is_load & cam_hit_i & ~flush_i
                  & (state_idle | state_drain);

// AXI load：无重叠、idle、无 drain
wire load_axi_ok  = state_idle & mem_valid & is_load
                  & ~cam_hit_i & ~cam_stall_i
                  & ~flush_i & ~drain_req_i;

wire load_req_fire  /* verilator public_flat_rd */ = load_axi_ok;
wire load_resp_fire /* verilator public_flat_rd */ = state_load & axi_done;

// drain：idle 接受；与 AXI load/store issue 互斥
wire drain_accept = state_idle & drain_req_i & ~flush_i;
assign drain_fire_o = drain_accept;

wire drain_resp_fire = state_drain & axi_done;
assign drain_done_o  = drain_resp_fire;
assign drain_fault_o = drain_resp_fire & (axi_wresp != 2'b00);

// SQ alloc
assign sq_alloc_en_o      = store_issue_ok;
assign sq_alloc_rob_idx_o = req_stage_out.rob_idx;
assign sq_alloc_addr_o    = req_mem_addr;
assign sq_alloc_data_o    = req_store_data;
assign sq_alloc_strb_o    = req_strb;
assign sq_alloc_size_o    = req_size;

// request register 对上游提供独立 ready；后级只有真正消费当前请求时才出队：
//   store/STLF 同拍 complete，AXI load 则由 hold_* 接管。
// cam_stall 会保留 request register 内的 load；flush 清空未消费请求。
// 已发出的 AXI load 在 flush 后只收尾事务，不再产生完成与写回。
assign req_stage_ready = store_issue_ok | load_stlf_ok | load_req_fire;
assign ready_o         = flush_i | req_stage_pre_ready;

always_comb begin
    nstate = state;
    unique case (state)
        S_IDLE: begin
            if (drain_accept)
                nstate = S_DRAIN;
            else if (load_req_fire)
                nstate = S_LOAD;
            else
                nstate = S_IDLE;
        end
        S_LOAD:  nstate = load_resp_fire  ? S_IDLE : S_LOAD;
        S_DRAIN: nstate = drain_resp_fire ? S_IDLE : S_DRAIN;
        default: nstate = S_IDLE;
    endcase
end

always_ff @(posedge clk) begin
    if (rst)
        state <= S_IDLE;
    else
        state <= nstate;
end

always_ff @(posedge clk) begin
    if (rst) begin
        hold_is_load  <= 1'b0;
        hold_rob_idx  <= '0;
        hold_phys_rd  <= '0;
        hold_rd_wen   <= 1'b0;
        hold_mem_type <= '0;
        hold_mem_addr <= '0;
        hold_flushed  <= 1'b0;
    end else begin
        if (load_req_fire) begin
            hold_is_load  <= 1'b1;
            hold_rob_idx  <= req_stage_out.rob_idx;
            hold_phys_rd  <= req_stage_out.phys_rd;
            hold_rd_wen   <= req_stage_out.rd_wen;
            hold_mem_type <= req_mem_type;
            hold_mem_addr <= req_mem_addr;
            hold_flushed  <= 1'b0;
        end else if (state_load && flush_i) begin
            hold_flushed <= 1'b1;
        end
    end
end

// 仿真 mtrace / difftest
wire [31:0] mem_addr /* verilator public_flat_rd */ =
    state_load  ? hold_mem_addr :
    state_drain ? drain_addr_i  :
                  req_mem_addr;
wire input_is_load /* verilator public_flat_rd */ =
    state_load ? 1'b1 : (state_drain ? 1'b0 : is_load);
wire axi_activity_done /* verilator public_flat_rd */ = load_resp_fire | drain_resp_fire;

// load 数据扩展（master/CAM 已将目标字节归到低位）
typedef enum logic [2:0] {
    LOAD_TYPE_LB  = 3'b000,
    LOAD_TYPE_LH  = 3'b001,
    LOAD_TYPE_LW  = 3'b010,
    LOAD_TYPE_LBU = 3'b100,
    LOAD_TYPE_LHU = 3'b101
} load_type_e;

logic [31:0] load_data_axi;
always_comb begin
    case (load_type_e'(hold_mem_type))
        LOAD_TYPE_LB:  load_data_axi = {{24{axi_rdata[7]}},  axi_rdata[7:0]};
        LOAD_TYPE_LH:  load_data_axi = {{16{axi_rdata[15]}}, axi_rdata[15:0]};
        LOAD_TYPE_LW:  load_data_axi = axi_rdata;
        LOAD_TYPE_LBU: load_data_axi = {24'b0, axi_rdata[7:0]};
        LOAD_TYPE_LHU: load_data_axi = {16'b0, axi_rdata[15:0]};
        default:       load_data_axi = 32'b0;
    endcase
end

logic [31:0] load_data_stlf;
always_comb begin
    case (load_type_e'(req_mem_type))
        LOAD_TYPE_LB:  load_data_stlf = {{24{cam_data_i[7]}},  cam_data_i[7:0]};
        LOAD_TYPE_LH:  load_data_stlf = {{16{cam_data_i[15]}}, cam_data_i[15:0]};
        LOAD_TYPE_LW:  load_data_stlf = cam_data_i;
        LOAD_TYPE_LBU: load_data_stlf = {24'b0, cam_data_i[7:0]};
        LOAD_TYPE_LHU: load_data_stlf = {16'b0, cam_data_i[15:0]};
        default:       load_data_stlf = 32'b0;
    endcase
end

wire load_fault = load_resp_fire & (axi_rresp != 2'b00);

// complete：store / STLF 同拍；AXI load 等响应
wire axi_load_complete = load_resp_fire & ~hold_flushed;

assign complete_en_o        = store_issue_ok | load_stlf_ok | axi_load_complete;
assign complete_idx_o       = (store_issue_ok | load_stlf_ok) ? req_stage_out.rob_idx : hold_rob_idx;
assign complete_data_o      = store_issue_ok ? 32'b0 :
                              load_stlf_ok   ? load_data_stlf : load_data_axi;
assign complete_exception_o = store_issue_ok ? 1'b0 :
                              load_stlf_ok   ? 1'b0 : load_fault;
assign complete_cause_o     = load_fault ? CAUSE_LOAD_ACCESS_FAULT : 4'b0;
assign complete_rd_wen_o    = store_issue_ok ? 1'b0 :
                              load_stlf_ok   ? req_stage_out.rd_wen :
                                               (hold_rd_wen & hold_is_load & ~load_fault);
assign complete_phys_rd_o   = (store_issue_ok | load_stlf_ok) ? req_stage_out.phys_rd : hold_phys_rd;

// AXI master：load 用 ren；drain 用 wen；store/STLF 不写总线
// master 的 AXADDR/AXSIZE/WSTRB/WDATA 全程直通、不锁存：
//   - S_LOAD：raddr/rsize 必须用 hold_*
//   - S_DRAIN：size 在 drain_accept|state_drain 整段选 drain_size_i
wire ren = load_req_fire;
wire wen = drain_accept;
wire drain_active = drain_accept | state_drain;

wire [31:0] axi_waddr = drain_addr_i;
wire [31:0] axi_wdata = drain_data_i;
wire [31:0] axi_raddr = state_load ? hold_mem_addr : req_mem_addr;
wire [1:0]  axi_rsize = state_load ? hold_mem_type[1:0] : req_size;
wire [1:0]  axi_size  = drain_active ? drain_size_i : axi_rsize;

axi4_full_master u_axi4_full_master (
    .clk            (clk),
    .rst            (rst),
    .wen            (wen),
    .ren            (ren),
    .user_ready     (1'b1),
    .size           (axi_size),
    .len            (8'b0),
    .waddr          (axi_waddr),
    .wdata          (axi_wdata),
    .raddr          (axi_raddr),
    .rdata          (axi_rdata),
    .rdata_valid    (),
    .rresp          (axi_rresp),
    .wresp          (axi_wresp),
    .done           (axi_done),

    .ARREADY        (ARREADY),
    .ARVALID        (ARVALID),
    .ARADDR         (ARADDR),
    .ARID           (ARID),
    .ARLEN          (ARLEN),
    .ARSIZE         (ARSIZE),
    .ARBURST        (ARBURST),
    .RREADY         (RREADY),
    .RVALID         (RVALID),
    .RDATA          (RDATA),
    .RLAST          (RLAST),
    .RID            (RID),
    .RRESP          (RRESP),
    .AWADDR         (AWADDR),
    .AWVALID        (AWVALID),
    .AWID           (AWID),
    .AWLEN          (AWLEN),
    .AWSIZE         (AWSIZE),
    .AWBURST        (AWBURST),
    .AWREADY        (AWREADY),
    .WDATA          (WDATA),
    .WSTRB          (WSTRB),
    .WLAST          (WLAST),
    .WVALID         (WVALID),
    .WREADY         (WREADY),
    .BRESP          (BRESP),
    .BVALID         (BVALID),
    .BID            (BID),
    .BREADY         (BREADY)
);

// drain_strb 与 SQ 队头 strb 同源，总线侧不用
wire _unused_drain_strb = |drain_strb_i;

// 轻量观测（PMC / 调试）
wire stlf_fire_o /* verilator public_flat_rd */ = load_stlf_ok;
wire cam_stall_block /* verilator public_flat_rd */ =
    mem_valid & is_load & cam_stall_i & ~flush_i;
wire load_axi_issue /* verilator public_flat_rd */ = load_req_fire;

endmodule
