// lsu (Load-Store Unit)
// 功能：处理访存指令，与 AXI 总线交互，完成后通知 ROB
//
// OoO 变化：
// 1. 使用 ROB index 标识指令，而不是架构寄存器
// 2. 完成信号发送到 ROB，而非直接写回
// 3. 不处理分支预测更新（已在 EXU 完成）
// 4. 初期保持阻塞访存：一次只处理一条访存指令
// 5. WAIT_RESP 期间锁存关键字段，避免依赖 IQ 输入保持稳定
//
// 握手参考经典五级 LSU.sv：
//   ready = idle 且当前非访存（可透传） | 访存响应完成
//   访存发出后 ready=0，反压上游直到 resp_fire

`include "./include/pipeline_pkt_pkg.sv"

module lsu
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    // 来自 issue_queue 的输入
    input               valid_i,
    input   issue2ex_pkt_t data_i,
    output              ready_o,

    // flush：丢弃 in-flight 完成（AXI 事务仍跑完，但不向 ROB 报告）
    input               flush_i,

    // 完成信号 → ROB
    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,      // ROB index
    output logic [31:0] complete_data_o,     // load 数据；store 为 0
    output logic        complete_exception_o,
    output logic [3:0]  complete_cause_o,

    // 写回物理寄存器信息（供顶层 PRF / wakeup）
    output logic        complete_rd_wen_o,
    output logic [5:0]  complete_phys_rd_o,

    // AXI 读通道
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

    // AXI 写通道
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

// ──────────────────────────────────────────────────
// 状态机：IDLE → WAIT_RESP → IDLE
// ──────────────────────────────────────────────────
typedef enum logic {
    S_IDLE,
    S_WAIT_RESP
} state_t;

state_t state, nstate;

// ──────────────────────────────────────────────────
// 访存类型判断（组合，仅在 IDLE 接受时使用）
// ──────────────────────────────────────────────────
wire is_load  = (data_i.mem.cmd == MEM_LOAD);
wire is_store = (data_i.mem.cmd == MEM_STORE);
wire is_mem   = is_load | is_store;

wire mem_valid = valid_i & is_mem;

// ──────────────────────────────────────────────────
// 状态相关信号
// ──────────────────────────────────────────────────
wire state_idle      = (state == S_IDLE);
wire state_wait_resp /* verilator public_flat_rd */ = (state == S_WAIT_RESP);

// AXI 交互信号
logic        axi_done;
logic [31:0] axi_rdata /* verilator public_flat_rd */;

// 锁存：请求发出后保存关键字段，不依赖上游保持 valid/data
logic        hold_is_load /* verilator public_flat_rd */;
logic [4:0]  hold_rob_idx;
logic [5:0]  hold_phys_rd;
logic        hold_rd_wen;
logic [2:0]  hold_mem_type;
logic [31:0] hold_mem_addr /* verilator public_flat_rd */;
logic [31:0] hold_store_data;
logic        hold_flushed;   // 请求发出后若 flush，完成时不报告 ROB

// 访存请求发出
wire mem_req_fire  /* verilator public_flat_rd */ = state_idle & mem_valid & ~flush_i;
wire mem_resp_fire /* verilator public_flat_rd */ = state_wait_resp & axi_done;

// 非访存指令：LSU 不处理，ready 放开让 EXU 路径处理
// （顶层保证只有 mem 指令才拉 valid_i）

// ──────────────────────────────────────────────────
// 流水线控制（参考 LSU.sv）
// ──────────────────────────────────────────────────
// LSU 接受新输入：
// 1. 空闲且当前不是访存请求
// 2. 访存响应完成（释放流水线）
// flush 时也 ready，避免卡死上游
assign ready_o = flush_i | (state_idle & ~mem_valid) | mem_resp_fire;

// ──────────────────────────────────────────────────
// 状态转移
// ──────────────────────────────────────────────────
always_comb begin
    case (state)
        S_IDLE:      nstate = mem_req_fire  ? S_WAIT_RESP : S_IDLE;
        S_WAIT_RESP: nstate = mem_resp_fire ? S_IDLE      : S_WAIT_RESP;
        default:     nstate = S_IDLE;
    endcase
end

always_ff @(posedge clk) begin
    if (rst) begin
        state <= S_IDLE;
    end else begin
        state <= nstate;
    end
end

// ──────────────────────────────────────────────────
// 锁存请求字段
// ──────────────────────────────────────────────────
wire [31:0] req_mem_addr  = data_i.rs1_data + data_i.imm;
wire [31:0] req_store_data = data_i.rs2_data;
wire [2:0]  req_mem_type  = data_i.inst[14:12];

always_ff @(posedge clk) begin
    if (rst) begin
        hold_is_load    <= 1'b0;
        hold_rob_idx    <= '0;
        hold_phys_rd    <= '0;
        hold_rd_wen     <= 1'b0;
        hold_mem_type   <= '0;
        hold_mem_addr   <= '0;
        hold_store_data <= '0;
        hold_flushed    <= 1'b0;
    end else begin
        if (mem_req_fire) begin
            hold_is_load    <= is_load;
            hold_rob_idx    <= data_i.rob_idx;
            hold_phys_rd    <= data_i.phys_rd;
            hold_rd_wen     <= data_i.rd_wen;
            hold_mem_type   <= req_mem_type;
            hold_mem_addr   <= req_mem_addr;
            hold_store_data <= req_store_data;
            hold_flushed    <= 1'b0;
        end else if (state_wait_resp && flush_i) begin
            // AXI 事务已发出不可取消，标记完成时丢弃
            hold_flushed <= 1'b1;
        end
    end
end

// 对外暴露当前有效地址（仿真 mtrace / difftest skip）
// 请求拍用组合地址，等待响应拍用锁存地址
wire [31:0] mem_addr /* verilator public_flat_rd */ =
    state_wait_resp ? hold_mem_addr : req_mem_addr;
wire input_is_load /* verilator public_flat_rd */ =
    state_wait_resp ? hold_is_load : is_load;

// ──────────────────────────────────────────────────
// Load 数据扩展
// ──────────────────────────────────────────────────
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

// ──────────────────────────────────────────────────
// 完成信号 → ROB / PRF
// ──────────────────────────────────────────────────
// flush 后完成的 in-flight 访存不再报告
assign complete_en_o        = mem_resp_fire & ~hold_flushed;
assign complete_idx_o       = hold_rob_idx;
assign complete_data_o      = hold_is_load ? load_data : 32'b0;
assign complete_exception_o = 1'b0;
assign complete_cause_o     = 4'b0;
assign complete_rd_wen_o    = hold_rd_wen & hold_is_load; // store 不写寄存器
assign complete_phys_rd_o   = hold_phys_rd;

// ──────────────────────────────────────────────────
// AXI Master
// ──────────────────────────────────────────────────
// wen/ren 是启动脉冲：在 mem_req_fire 时拉高一个周期
// 地址/数据在 fire 拍用组合值；master 内部会锁存
wire wen = mem_req_fire & is_store;
wire ren = mem_req_fire & is_load;

axi4_full_master u_axi4_full_master (
    .clk            (clk),
    .rst            (rst),
    .wen            (wen),
    .ren            (ren),
    .user_ready     (1'b1),
    .size           (req_mem_type[1:0]),
    .len            (8'b0),
    .waddr          (req_mem_addr),
    .wdata          (req_store_data),
    .raddr          (req_mem_addr),
    .rdata          (axi_rdata),
    .rdata_valid    (),
    .rresp          (),
    .wresp          (),
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

endmodule
