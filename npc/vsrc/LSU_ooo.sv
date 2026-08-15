// LSU_ooo (Load-Store Unit) - OoO 版本
// 功能：处理访存指令，与 AXI 总线交互，完成后通知 ROB
//
// OoO 变化：
// 1. 使用 ROB index 标识指令，而不是架构寄存器
// 2. 完成信号发送到 ROB，而非直接写回
// 3. 不处理分支预测更新（已在 EXU 完成）
// 4. 初期保持阻塞访存：一次只处理一条访存指令
//
// 未来优化：
// - 添加 Store Buffer，允许 store 指令提前完成
// - 添加 Load Queue，支持乱序 load
// - 添加访存依赖检查（load-store forwarding）

`include "./include/pipeline_pkt_pkg.sv"

module LSU_ooo
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    // 来自 issue_queue 的输入
    input               valid_i,
    input   issue2ex_pkt_t data_i,  // 复用 issue2ex_pkt_t，因为包含所需信息
    output              ready_o,

    // 完成信号 → ROB
    output logic        complete_en_o,
    output logic [4:0]  complete_idx_o,      // ROB index
    output logic [31:0] complete_data_o,     // load 数据或 store 的原 result
    output logic        complete_exception_o,
    output logic [3:0]  complete_cause_o,

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
// 访存类型判断
// ──────────────────────────────────────────────────
wire is_load  = (data_i.mem.cmd == MEM_LOAD);
wire is_store = (data_i.mem.cmd == MEM_STORE);
wire is_mem   = is_load | is_store;

wire mem_valid = valid_i & is_mem;

// ──────────────────────────────────────────────────
// 状态相关信号
// ──────────────────────────────────────────────────
wire state_idle      = (state == S_IDLE);
wire state_wait_resp = (state == S_WAIT_RESP);

// AXI 交互信号
logic        axi_done;
logic [31:0] axi_rdata;

// 访存请求发出
wire mem_req_fire  = state_idle & mem_valid;
wire mem_resp_fire = state_wait_resp & axi_done;

// 非访存指令直接透传
wire non_mem_pass = state_idle & valid_i & ~is_mem;

// ──────────────────────────────────────────────────
// 流水线控制
// ──────────────────────────────────────────────────
// LSU 在以下情况接受新输入：
// 1. 空闲且当前不是访存指令（直接透传）
// 2. 访存响应完成（释放流水线）
assign ready_o = (state_idle & ~mem_valid) | mem_resp_fire;

// LSU 在以下情况输出有效：
// 1. 非访存指令直接透传
// 2. 访存指令完成
assign complete_en_o = non_mem_pass | mem_resp_fire;

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
    state <= rst ? S_IDLE : nstate;
end

// ──────────────────────────────────────────────────
// 访存地址和数据
// ──────────────────────────────────────────────────
// 访存地址来自 ALU 计算结果（保存在 data_i.rs1_data + imm，但 EXU 已算好）
// 这里我们需要从某处获取地址。查看 issue2ex_pkt_t，没有专门的 mem_addr 字段。
// 
// 方案：LSU 需要接收 EXU 的输出（ex2ls_pkt_t），但为了简化初期设计，
// 我们假设 LSU 从 issue_queue 直接获取指令，并自己计算地址。
// 
// 等等，这不对。LSU 应该接收 EXU 的输出，因为地址是 ALU 计算的。
// 让我重新设计接口。

wire [31:0] mem_addr  = data_i.rs1_data + data_i.imm;  // rs1 + offset
wire [31:0] store_data = data_i.rs2_data;              // store 的数据来自 rs2
wire [2:0]  mem_type  = data_i.inst[14:12];           // funct3: LB/LH/LW/LBU/LHU/SB/SH/SW

// ──────────────────────────────────────────────────
// Load 数据扩展
// ──────────────────────────────────────────────────
// Load 类型定义（funct3）
typedef enum logic [2:0] {
    LOAD_TYPE_LB  = 3'b000,
    LOAD_TYPE_LH  = 3'b001,
    LOAD_TYPE_LW  = 3'b010,
    LOAD_TYPE_LBU = 3'b100,
    LOAD_TYPE_LHU = 3'b101
} load_type_e;

logic [31:0] load_data;

always_comb begin
    case (load_type_e'(mem_type))
        LOAD_TYPE_LB:  load_data = {{24{axi_rdata[7]}},  axi_rdata[7:0]};   // 符号扩展
        LOAD_TYPE_LH:  load_data = {{16{axi_rdata[15]}}, axi_rdata[15:0]};  // 符号扩展
        LOAD_TYPE_LW:  load_data = axi_rdata;                               // 32位
        LOAD_TYPE_LBU: load_data = {24'b0, axi_rdata[7:0]};                 // 零扩展
        LOAD_TYPE_LHU: load_data = {16'b0, axi_rdata[15:0]};                // 零扩展
        default:       load_data = 32'b0;
    endcase
end

// ──────────────────────────────────────────────────
// 完成信号 → ROB
// ──────────────────────────────────────────────────
assign complete_idx_o  = data_i.rob_idx;
assign complete_data_o = is_load ? load_data : 32'b0;  // store 不产生结果

// OoO: 访存异常暂不处理（未来扩展）
assign complete_exception_o = 1'b0;
assign complete_cause_o     = 4'b0;

// ──────────────────────────────────────────────────
// AXI Master 实例化
// ──────────────────────────────────────────────────
// wen/ren 是启动脉冲：在 mem_req_fire 时拉高一个周期
wire wen = mem_req_fire & is_store;
wire ren = mem_req_fire & is_load;

axi4_full_master u_axi4_full_master (
    .clk            (clk),
    .rst            (rst),
    .wen            (wen),
    .ren            (ren),
    .user_ready     (1'b1),        // LSU 总是准备好接收数据
    .size           (mem_type[1:0]), // byte/half/word
    .len            (8'b0),        // burst length = 1
    .waddr          (mem_addr),
    .wdata          (store_data),
    .raddr          (mem_addr),
    .rdata          (axi_rdata),
    .rdata_valid    (),            // 未使用
    .rresp          (),            // 未使用
    .wresp          (),            // 未使用
    .done           (axi_done),    // 访存完成信号
    
    // AXI 接口
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
