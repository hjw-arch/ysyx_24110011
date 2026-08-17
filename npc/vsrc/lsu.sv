// lsu (Load-Store Unit) — Tier2
// Load：SQ 空时阻塞 AXI 读，complete → ROB/PRF
// Store：issue 只算地址入 SQ（data=rs2 原值），立即 complete；AXI 写仅 commit drain
// 不变量：
//   1. store 不得在 commit 前进入 AXI
//   2. SQ 非空时不得发 load（无 STLF；与 IQ mem 序一起保证读到提交后的内存）
//   3. 子字摆放只在 axi4_full_master 做一次，SQ 存 rs2 原值

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

    // 完成 → ROB（load 等 AXI；store 入 SQ 后同拍 complete）
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
    input               sq_empty_i,         // 1 = 无未完成 store，允许 load

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

wire is_load  = (data_i.mem.cmd == MEM_LOAD);
wire is_store = (data_i.mem.cmd == MEM_STORE);
wire is_mem   = is_load | is_store;
wire mem_valid = valid_i & is_mem;

wire state_idle  = (state == S_IDLE);
wire state_load  /* verilator public_flat_rd */ = (state == S_LOAD);
wire state_drain = (state == S_DRAIN);

logic        axi_done;
logic [31:0] axi_rdata /* verilator public_flat_rd */;
logic [1:0]  axi_rresp;
logic [1:0]  axi_wresp;

// load 锁存
logic        hold_is_load /* verilator public_flat_rd */;
logic [4:0]  hold_rob_idx;
logic [5:0]  hold_phys_rd;
logic        hold_rd_wen;
logic [2:0]  hold_mem_type;
logic [31:0] hold_mem_addr /* verilator public_flat_rd */;
logic        hold_flushed;

wire [31:0] req_mem_addr   = data_i.rs1_data + data_i.imm;
wire [31:0] req_store_data = data_i.rs2_data;   // 原值；master 按 addr/size 摆放
wire [2:0]  req_mem_type   = data_i.inst[14:12];
wire [1:0]  req_size       = req_mem_type[1:0];

// strb 仅记录（STLF/调试）；写通道 WSTRB 由 master 生成
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

// load：idle + SQ 空（无更老未退休 store）+ 本拍无 drain
wire load_issue_ok  = state_idle & mem_valid & is_load
                    & sq_empty_i & ~flush_i & ~drain_req_i;

wire load_req_fire  /* verilator public_flat_rd */ = load_issue_ok;
wire load_resp_fire /* verilator public_flat_rd */ = state_load & axi_done;

// drain：idle 接受；与 load/store issue 互斥（drain_req 优先）
wire drain_accept = state_idle & drain_req_i & ~flush_i;
assign drain_fire_o = drain_accept;

wire drain_resp_fire = state_drain & axi_done;
assign drain_done_o  = drain_resp_fire;
assign drain_fault_o = drain_resp_fire & (axi_wresp != 2'b00);

// SQ alloc
assign sq_alloc_en_o      = store_issue_ok;
assign sq_alloc_rob_idx_o = data_i.rob_idx;
assign sq_alloc_addr_o    = req_mem_addr;
assign sq_alloc_data_o    = req_store_data;
assign sq_alloc_strb_o    = req_strb;
assign sq_alloc_size_o    = req_size;

// ready：非 mem 直通；store 入队成功；load 完成；flush
// load 因 SQ 非空 / drain 占用而停在 issue 口时 ready=0，IQ 保持该项
assign ready_o = flush_i
               | (state_idle & ~mem_valid)
               | store_issue_ok
               | load_resp_fire;

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
            hold_rob_idx  <= data_i.rob_idx;
            hold_phys_rd  <= data_i.phys_rd;
            hold_rd_wen   <= data_i.rd_wen;
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

// load 数据扩展（master 已按 addr 将目标字节归到低位）
typedef enum logic [2:0] {
    LOAD_TYPE_LB  = 3'b000,
    LOAD_TYPE_LH  = 3'b001,
    LOAD_TYPE_LW  = 3'b010,
    LOAD_TYPE_LBU = 3'b100,
    LOAD_TYPE_LHU = 3'b101
} load_type_e;

logic [31:0] load_data;
always_comb begin
    case (load_type_e'(hold_mem_type))
        LOAD_TYPE_LB:  load_data = {{24{axi_rdata[7]}},  axi_rdata[7:0]};
        LOAD_TYPE_LH:  load_data = {{16{axi_rdata[15]}}, axi_rdata[15:0]};
        LOAD_TYPE_LW:  load_data = axi_rdata;
        LOAD_TYPE_LBU: load_data = {24'b0, axi_rdata[7:0]};
        LOAD_TYPE_LHU: load_data = {16'b0, axi_rdata[15:0]};
        default:       load_data = 32'b0;
    endcase
end

wire load_fault = load_resp_fire & (axi_rresp != 2'b00);

// complete：store 入队即完成；load 等 AXI
assign complete_en_o        = store_issue_ok | (load_resp_fire & ~hold_flushed);
assign complete_idx_o       = store_issue_ok ? data_i.rob_idx : hold_rob_idx;
assign complete_data_o      = store_issue_ok ? 32'b0 : load_data;
assign complete_exception_o = store_issue_ok ? 1'b0 : load_fault;
assign complete_cause_o     = load_fault ? CAUSE_LOAD_ACCESS_FAULT : 4'b0;
assign complete_rd_wen_o    = store_issue_ok ? 1'b0 : (hold_rd_wen & hold_is_load & ~load_fault);
assign complete_phys_rd_o   = store_issue_ok ? data_i.phys_rd : hold_phys_rd;

// AXI master：load 用 ren；drain 用 wen；store issue 不写总线
// master 的 AXADDR/AXSIZE/WSTRB/WDATA 全程直通、不锁存：
//   - S_LOAD：raddr/rsize 必须用 hold_*（OoO 下 data_i 会被 EXU issue 覆盖）
//   - S_DRAIN：wsize 不能只在 wen 脉冲拍有效；wen 仅 fire 一拍，
//     之后 drain_req 也会因 committed 拉低，但 SQ 队头数据仍稳定，
//     故 size 在 drain_accept|state_drain 整段选 drain_size_i
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

wire _unused_drain_strb = |drain_strb_i;

endmodule
