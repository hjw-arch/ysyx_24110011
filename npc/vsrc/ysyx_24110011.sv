// ysyx_24110011.sv  —  单发射乱序执行处理器顶层
//
// 流水线结构：
//   IFU → idu → rename_stage → issue_queue → exu / lsu → rob → 写回物理寄存器堆
//
// 与旧五级流水线的主要区别：
//   1. 不再有 hazard_unit / 前递网络：RAW 由重命名消除，WAW/WAR 不可能发生
//   2. 不再有 pip_reg 级间寄存器 + flush：ROB 是顺序提交点，flush 以 rob.flush_o 为准
//   3. 寄存器堆换成 physical_regfile（64 物理寄存器）；旧 registerfile 不再使用
//   4. exu / lsu 完成后写 ROB，commit 时才写物理寄存器堆
//   5. lsu 的 bpu_update / redirect 信号合并到 exu 输出（EXU 已处理分支）
//
// AXI 互联结构与旧版相同：IFU(m0) + LSU(m1) → arbiter → Xbar → io_master / CLINT

`include "./include/pipeline_pkt_pkg.sv"

module ysyx_24110011
import pipeline_pkt_pkg::*;
(
    input           clock,
    input           reset,
    /* verilator lint_off UNUSEDSIGNAL */
    input           io_interrupt,

    // AXI4 Master
    input           io_master_awready,
    output          io_master_awvalid,
    output [31:0]   io_master_awaddr,
    output [3:0]    io_master_awid,
    output [7:0]    io_master_awlen,
    output [2:0]    io_master_awsize,
    output [1:0]    io_master_awburst,
    input           io_master_wready,
    output          io_master_wvalid,
    output [31:0]   io_master_wdata,
    output [3:0]    io_master_wstrb,
    output          io_master_wlast,
    output          io_master_bready,
    input           io_master_bvalid,
    input  [1:0]    io_master_bresp,
    input  [3:0]    io_master_bid,
    input           io_master_arready,
    output          io_master_arvalid,
    output [31:0]   io_master_araddr,
    output [3:0]    io_master_arid,
    output [7:0]    io_master_arlen,
    output [2:0]    io_master_arsize,
    output [1:0]    io_master_arburst,
    output          io_master_rready,
    input           io_master_rvalid,
    input  [1:0]    io_master_rresp,
    input  [31:0]   io_master_rdata,
    input           io_master_rlast,
    input  [3:0]    io_master_rid,

    // AXI4 Slave（全部 tie-off）
    output          io_slave_awready,
    input           io_slave_awvalid,
    input  [31:0]   io_slave_awaddr,
    input  [3:0]    io_slave_awid,
    input  [7:0]    io_slave_awlen,
    input  [2:0]    io_slave_awsize,
    input  [1:0]    io_slave_awburst,
    output          io_slave_wready,
    input           io_slave_wvalid,
    input  [31:0]   io_slave_wdata,
    input  [3:0]    io_slave_wstrb,
    input           io_slave_wlast,
    input           io_slave_bready,
    output          io_slave_bvalid,
    output [1:0]    io_slave_bresp,
    output [3:0]    io_slave_bid,
    output          io_slave_arready,
    input           io_slave_arvalid,
    input  [31:0]   io_slave_araddr,
    input  [3:0]    io_slave_arid,
    input  [7:0]    io_slave_arlen,
    input  [2:0]    io_slave_arsize,
    input  [1:0]    io_slave_arburst,
    input           io_slave_rready,
    output          io_slave_rvalid,
    output [1:0]    io_slave_rresp,
    output [31:0]   io_slave_rdata,
    output          io_slave_rlast,
    output [3:0]    io_slave_rid
);

// ─── slave 接口全部 tie-off ─────────────────────────────
assign io_slave_awready = 1'b0;
assign io_slave_wready  = 1'b0;
assign io_slave_bvalid  = 1'b0;
assign io_slave_bresp   = 2'b0;
assign io_slave_bid     = 4'b0;
assign io_slave_arready = 1'b0;
assign io_slave_rvalid  = 1'b0;
assign io_slave_rresp   = 2'b0;
assign io_slave_rdata   = 32'b0;
assign io_slave_rlast   = 1'b0;
assign io_slave_rid     = 4'b0;

// ─── 全局 flush / redirect ────────────────────────────────
// flush 来源：
//   1. ROB 检测到异常（ecall/mret/fence.i）→ rob.flush_o
//   2. exu 检测到分支误预测 → exu.redirect_valid_o
// 两者均触发 IFU redirect；ROB flush 同时清空整条流水线
wire        exu_redirect_valid;
wire [31:0] exu_redirect_addr;
wire        rob_flush;
wire [31:0] rob_flush_pc;

wire        pipeline_flush  = rob_flush | exu_redirect_valid;
wire [31:0] redirect_pc     = rob_flush ? rob_flush_pc : exu_redirect_addr;

// ─── BPU 更新（来自 exu）──────────────────────────────────
wire        bpu_update_valid;
wire        bpu_update_btb_type;
wire        bpu_update_taken;
wire [31:0] bpu_update_target;

// ─── IF → DEC ─────────────────────────────────────────────
wire        if2dec_valid;
if2id_pkt_t if2dec_data;
wire        if2dec_ready;

// ─── DEC → RENAME ─────────────────────────────────────────
wire        dec2ren_valid;
decode_pkt_t dec2ren_data;
wire        dec2ren_ready;

// ─── RENAME → IQ ──────────────────────────────────────────
wire              ren2iq_valid;
rename2issue_pkt_t ren2iq_pkt;
wire              ren2iq_ready;

// ─── ROB 分配接口 ──────────────────────────────────────────
wire [4:0]        rob_alloc_idx;
wire              rob_alloc_ready;
wire              rob_alloc_en;
rob_alloc_pkt_t   rob_alloc_pkt;

// ─── IQ → EXU ─────────────────────────────────────────────
wire              iq_issue_valid;
issue2ex_pkt_t    iq_issue_pkt;
wire              iq_issue_ready;    // exu 总是 ready（纯组合）
wire [5:0]        iq_phys_rs1;      // 需要从 physical_regfile 读取的物理寄存器
wire [5:0]        iq_phys_rs2;

// ─── 物理寄存器堆 ──────────────────────────────────────────
wire [31:0] prf_rs1_data;
wire [31:0] prf_rs2_data;
// 写端口1：EXU 完成时写（ALU/branch/jump 结果）
// 写端口2：ROB commit 时写（用于确保提交顺序，同时处理 CSR/exception）
wire        prf_wen1;
wire [5:0]  prf_waddr1;
wire [31:0] prf_wdata1;
wire        prf_wen2;
wire [5:0]  prf_waddr2;
wire [31:0] prf_wdata2;

// ─── 唤醒信号（exu/lsu → issue_queue + rename_stage）─────
wire        wakeup_en;
wire [5:0]  wakeup_preg;

// ─── EXU 完成信号 → ROB ────────────────────────────────────
wire        exu_complete_en;
wire [4:0]  exu_complete_idx;
wire [31:0] exu_complete_data;
wire        exu_complete_exc;
wire [3:0]  exu_complete_cause;
wire        exu_complete_redir_valid;
wire [31:0] exu_complete_redir_addr;

// ─── ROB commit ────────────────────────────────────────────
wire        commit_valid;
rob_commit_t commit_pkt;

// ─── icache invalidate（fence.i 由 ROB commit 触发）────────
wire        icache_inval;
assign icache_inval = commit_valid & commit_pkt.sys.fence_i;

// ================================================================
//  IFU
// ================================================================
logic [31:0] IFU_ARADDR;  logic IFU_ARVALID, IFU_RREADY;
logic [3:0]  IFU_ARID;    logic [7:0] IFU_ARLEN; logic [2:0] IFU_ARSIZE; logic [1:0] IFU_ARBURST;
logic IFU_ARREADY, IFU_RVALID, IFU_RLAST;
logic [3:0] IFU_RID;  logic [31:0] IFU_RDATA;  logic [1:0] IFU_RRESP;

IFU u_ifu (
    .clk                (clock),
    .rst                (reset),
    .ARADDR             (IFU_ARADDR),  .ARVALID    (IFU_ARVALID),
    .ARID               (IFU_ARID),    .ARLEN      (IFU_ARLEN),
    .ARSIZE             (IFU_ARSIZE),  .ARBURST    (IFU_ARBURST),
    .ARREADY            (IFU_ARREADY), .RVALID     (IFU_RVALID),
    .RDATA              (IFU_RDATA),   .RRESP      (IFU_RRESP),
    .RLAST              (IFU_RLAST),   .RID        (IFU_RID),
    .RREADY             (IFU_RREADY),
    .icache_inval_i     (icache_inval),
    .redirect_valid_i   (pipeline_flush),
    .redirect_pc_i      (redirect_pc),
    .bpu_update_valid_i (bpu_update_valid),
    .bpu_update_type_i  (bpu_update_btb_type),
    .bpu_update_taken_i (bpu_update_taken),
    .bpu_update_pc_i    (32'b0),       // exu 未输出 bpu_update_pc，用 redirect_addr 近似
    .bpu_update_target_i(bpu_update_target),
    .valid_o            (if2dec_valid),
    .data_o             (if2dec_data),
    .ready_i            (if2dec_ready)
);

// ================================================================
//  IDU（Instruction Decode Unit）
// ================================================================
idu u_idu (
    .valid_i  (if2dec_valid),
    .data_i   (if2dec_data),
    .ready_o  (if2dec_ready),
    .valid_o  (dec2ren_valid),
    .data_o   (dec2ren_data),
    .ready_i  (dec2ren_ready)
);

// ================================================================
//  Rename Stage（重命名 + 分发）
// ================================================================
rename_stage u_rename (
    .clk                (clock),
    .rst                (reset),
    // 上游（来自 IDU）
    .decode_valid_i     (dec2ren_valid),
    .decode_pkt_i       (dec2ren_data),
    .decode_ready_o     (dec2ren_ready),
    // 下游（到 IQ）
    .dispatch_valid_o   (ren2iq_valid),
    .dispatch_pkt_o     (ren2iq_pkt),
    .dispatch_ready_i   (ren2iq_ready),
    // ROB 分配
    .rob_alloc_idx_i    (rob_alloc_idx),
    .rob_ready_i        (rob_alloc_ready),
    .rob_alloc_en_o     (rob_alloc_en),
    .rob_alloc_pkt_o    (rob_alloc_pkt),
    // 提交（释放旧物理寄存器）
    .commit_valid_i     (commit_valid),
    .commit_preg_old_i  (commit_pkt.phys_rd_old),
    // 唤醒广播
    .wakeup_en_i        (wakeup_en),
    .wakeup_preg_i      (wakeup_preg),
    // 全局 flush
    .flush_i            (pipeline_flush)
);

// ================================================================
//  ROB（Reorder Buffer）
// ================================================================
rob u_rob (
    .clk                        (clock),
    .rst                        (reset),
    // 分配（来自 rename_stage）
    .alloc_en_i                 (rob_alloc_en),
    .alloc_pkt_i                (rob_alloc_pkt),
    .alloc_idx_o                (rob_alloc_idx),
    .alloc_ready_o              (rob_alloc_ready),
    // 完成（来自 exu；lsu 完成合并后接入）
    .complete_en_i              (exu_complete_en),
    .complete_idx_i             (exu_complete_idx),
    .complete_data_i            (exu_complete_data),
    .complete_exception_i       (exu_complete_exc),
    .complete_cause_i           (exu_complete_cause),
    .complete_redirect_valid_i  (exu_complete_redir_valid),
    .complete_redirect_addr_i   (exu_complete_redir_addr),
    // 提交
    .commit_valid_o             (commit_valid),
    .commit_pkt_o               (commit_pkt),
    // flush
    .flush_o                    (rob_flush),
    .flush_pc_o                 (rob_flush_pc)
);

// ================================================================
//  Issue Queue
// ================================================================
issue_queue u_iq (
    .clk            (clock),
    .rst            (reset),
    // 分发（来自 rename_stage）
    .dispatch_en_i      (ren2iq_valid),
    .dispatch_pkt_i     (ren2iq_pkt),
    .dispatch_ready_o   (ren2iq_ready),
    // 发射（到 physical_regfile 读取 + exu/lsu）
    .issue_valid_o      (iq_issue_valid),
    .issue_pkt_o        (iq_issue_pkt),
    .issue_ready_i      (iq_issue_ready),
    .issue_phys_rs1_o   (iq_phys_rs1),
    .issue_phys_rs2_o   (iq_phys_rs2),
    // 唤醒
    .wakeup_en_i        (wakeup_en),
    .wakeup_preg_i      (wakeup_preg),
    // flush
    .flush_i            (pipeline_flush)
);

// ================================================================
//  Physical Register File
// ================================================================
// 读端口：issue_queue 发射时读取 rs1/rs2 数据，填入 issue_pkt.rs1_data/rs2_data
// 写端口1：exu 完成时写（wakeup_en 同拍即写，无需等 commit）
// 写端口2：commit 时如有异常/CSR 需要写（此时 phys_rd 是新映射的寄存器）
physical_regfile u_prf (
    .clk          (clock),
    .rst          (reset),
    .read_addr1_i (iq_phys_rs1),
    .read_data1_o (prf_rs1_data),
    .read_addr2_i (iq_phys_rs2),
    .read_data2_o (prf_rs2_data),
    .write_en1_i  (prf_wen1),
    .write_addr1_i(prf_waddr1),
    .write_data1_i(prf_wdata1),
    .write_en2_i  (prf_wen2),
    .write_addr2_i(prf_waddr2),
    .write_data2_i(prf_wdata2)
);

// EXU 完成时直接写物理寄存器堆（非 CSR/异常结果）
assign prf_wen1   = exu_complete_en & iq_issue_pkt.rd_wen;
assign prf_waddr1 = iq_issue_pkt.phys_rd;
assign prf_wdata1 = exu_complete_data;

// commit 时写 CSR/异常结果（rd_wen 有效时）
assign prf_wen2   = commit_valid & commit_pkt.rd_wen;
assign prf_waddr2 = commit_pkt.phys_rd_old;  // 旧物理寄存器（arch_rd 当前持有的）
assign prf_wdata2 = commit_pkt.result;

// ================================================================
//  EXU（Execution Unit）
//  issue_queue 发射的 pkt 中 rs1_data/rs2_data 需要从 PRF 填入
// ================================================================
// 将 PRF 读出的数据填入 issue pkt（issue_queue 输出的 pkt 里 rs1/rs2 是 0）
issue2ex_pkt_t exu_input_pkt;
always_comb begin
    exu_input_pkt          = iq_issue_pkt;
    exu_input_pkt.rs1_data = prf_rs1_data;
    exu_input_pkt.rs2_data = prf_rs2_data;
end

assign iq_issue_ready = 1'b1;  // exu 总是 ready

exu u_exu (
    .clk                        (clock),
    .rst                        (reset),
    .valid_i                    (iq_issue_valid),
    .data_i                     (exu_input_pkt),
    .ready_o                    (),  // 总是 ready，忽略
    // 完成 → ROB
    .complete_en_o              (exu_complete_en),
    .complete_idx_o             (exu_complete_idx),
    .complete_data_o            (exu_complete_data),
    .complete_exception_o       (exu_complete_exc),
    .complete_cause_o           (exu_complete_cause),
    .complete_redirect_valid_o  (exu_complete_redir_valid),
    .complete_redirect_addr_o   (exu_complete_redir_addr),
    // 唤醒 → issue_queue + rename
    .wakeup_en_o                (wakeup_en),
    .wakeup_preg_o              (wakeup_preg),
    // redirect → IFU
    .redirect_valid_o           (exu_redirect_valid),
    .redirect_addr_o            (exu_redirect_addr),
    // BPU 更新
    .bpu_update_valid_o         (bpu_update_valid),
    .bpu_update_btb_type_o      (bpu_update_btb_type),
    .bpu_update_taken_o         (bpu_update_taken),
    .bpu_update_target_o        (bpu_update_target)
);

// ================================================================
//  AXI 总线（IFU + LSU → arbiter → Xbar → io_master / CLINT）
//  结构与旧版完全相同，直接复用
// ================================================================
logic [31:0] LSU_ARADDR, LSU_AWADDR, LSU_WDATA, LSU_RDATA;
logic [3:0]  LSU_ARID, LSU_AWID, LSU_RID, LSU_BID, LSU_WSTRB;
logic [7:0]  LSU_ARLEN, LSU_AWLEN;
logic [2:0]  LSU_ARSIZE, LSU_AWSIZE;
logic [1:0]  LSU_ARBURST, LSU_AWBURST, LSU_RRESP, LSU_BRESP;
logic        LSU_ARVALID, LSU_ARREADY, LSU_RVALID, LSU_RLAST, LSU_RREADY;
logic        LSU_AWVALID, LSU_AWREADY, LSU_WLAST, LSU_WVALID, LSU_WREADY;
logic        LSU_BVALID, LSU_BREADY;

// LSU（访存单元，初期阻塞，访存指令从 IQ 直接发射过来）
// 注意：当前 issue_queue 只有一个发射端口，exu 和 lsu 复用同一条流水线。
// 访存指令由 lsu 处理，非访存指令由 exu 处理。
// 简化：exu 对非访存指令有效，lsu 对访存指令有效；两者共享 IQ 发射端口。
// TODO: 后续改为 exu/lsu 各自独立发射端口（两条执行流水）

// 访存指令路由到 lsu
wire is_mem_inst = iq_issue_valid & (iq_issue_pkt.mem.cmd != MEM_NONE);

lsu u_lsu (
    .clk    (clock), .rst    (reset),
    .valid_i(is_mem_inst),
    .data_i (exu_input_pkt),  // 已填入 PRF 数据
    .ready_o(),               // 用 rob_alloc_ready 控制整体反压
    // lsu 完成信号（暂时 OR 进 ROB，后续需要仲裁）
    .complete_en_o          (),   // TODO: 接入 ROB 第二完成端口
    .complete_idx_o         (),
    .complete_data_o        (),
    .complete_exception_o   (),
    .complete_cause_o       (),
    // AXI
    .ARADDR  (LSU_ARADDR),  .ARID    (LSU_ARID),    .ARLEN   (LSU_ARLEN),
    .ARSIZE  (LSU_ARSIZE),  .ARBURST (LSU_ARBURST), .ARVALID (LSU_ARVALID),
    .ARREADY (LSU_ARREADY), .RID     (LSU_RID),     .RDATA   (LSU_RDATA),
    .RRESP   (LSU_RRESP),   .RVALID  (LSU_RVALID),  .RLAST   (LSU_RLAST),
    .RREADY  (LSU_RREADY),
    .AWADDR  (LSU_AWADDR),  .AWLEN   (LSU_AWLEN),   .AWSIZE  (LSU_AWSIZE),
    .AWID    (LSU_AWID),    .AWBURST (LSU_AWBURST), .AWVALID (LSU_AWVALID),
    .AWREADY (LSU_AWREADY), .WDATA   (LSU_WDATA),   .WLAST   (LSU_WLAST),
    .WSTRB   (LSU_WSTRB),   .WVALID  (LSU_WVALID),  .WREADY  (LSU_WREADY),
    .BID     (LSU_BID),     .BRESP   (LSU_BRESP),   .BVALID  (LSU_BVALID),
    .BREADY  (LSU_BREADY)
);

// ================================================================
//  AXI Arbiter：IFU(m0) + LSU(m1) → 单主端口(s)
// ================================================================
logic [3:0]  m0_arid,  m0_awid,  m0_rid,  m0_bid;
logic [31:0] m0_araddr,m0_awaddr,m0_rdata,m0_wdata;
logic [7:0]  m0_arlen, m0_awlen;
logic [2:0]  m0_arsize,m0_awsize;
logic [1:0]  m0_arburst,m0_awburst,m0_rresp,m0_bresp;
logic        m0_arvalid,m0_arready,m0_rvalid,m0_rlast,m0_rready;
logic        m0_awvalid,m0_awready,m0_wlast,m0_wvalid,m0_wready,m0_bvalid,m0_bready;

logic [3:0]  m1_arid,  m1_awid,  m1_rid,  m1_bid;
logic [31:0] m1_araddr,m1_awaddr,m1_rdata,m1_wdata;
logic [7:0]  m1_arlen, m1_awlen;
logic [2:0]  m1_arsize,m1_awsize;
logic [1:0]  m1_arburst,m1_awburst,m1_rresp,m1_bresp;
logic        m1_arvalid,m1_arready,m1_rvalid,m1_rlast,m1_rready;
logic        m1_awvalid,m1_awready,m1_wlast,m1_wvalid,m1_wready,m1_bvalid,m1_bready;
logic [3:0]  m1_wstrb;

logic [3:0]  s_arid,   s_awid,   s_rid,   s_bid;
logic [31:0] s_araddr, s_awaddr, s_rdata, s_wdata;
logic [7:0]  s_arlen,  s_awlen;
logic [2:0]  s_arsize, s_awsize;
logic [1:0]  s_arburst,s_awburst,s_rresp, s_bresp;
logic        s_arvalid,s_arready,s_rvalid,s_rlast, s_rready;
logic        s_awvalid,s_awready,s_wlast, s_wvalid,s_wready, s_bvalid,s_bready;
logic [3:0]  s_wstrb;

// IFU → m0（只读）
assign m0_arid    = IFU_ARID;    assign m0_araddr  = IFU_ARADDR;
assign m0_arlen   = IFU_ARLEN;   assign m0_arsize  = IFU_ARSIZE;
assign m0_arburst = IFU_ARBURST; assign m0_arvalid = IFU_ARVALID;
assign m0_rready  = IFU_RREADY;
assign IFU_ARREADY= m0_arready;  assign IFU_RID    = m0_rid;
assign IFU_RDATA  = m0_rdata;    assign IFU_RRESP  = m0_rresp;
assign IFU_RLAST  = m0_rlast;    assign IFU_RVALID = m0_rvalid;
// m0 写通道 tie-off
assign m0_awid=4'b0; assign m0_awaddr=32'b0; assign m0_awlen=8'b0;
assign m0_awsize=3'b0; assign m0_awburst=2'b0; assign m0_awvalid=1'b0;
assign m0_wdata=32'b0; assign m0_wlast=1'b0;
assign m0_wvalid=1'b0; assign m0_bready=1'b1;

// LSU → m1
assign m1_arid    = LSU_ARID;    assign m1_araddr  = LSU_ARADDR;
assign m1_arlen   = LSU_ARLEN;   assign m1_arsize  = LSU_ARSIZE;
assign m1_arburst = LSU_ARBURST; assign m1_arvalid = LSU_ARVALID;
assign m1_rready  = LSU_RREADY;
assign m1_awid    = LSU_AWID;    assign m1_awaddr  = LSU_AWADDR;
assign m1_awlen   = LSU_AWLEN;   assign m1_awsize  = LSU_AWSIZE;
assign m1_awburst = LSU_AWBURST; assign m1_awvalid = LSU_AWVALID;
assign m1_wdata   = LSU_WDATA;   assign m1_wstrb   = LSU_WSTRB;
assign m1_wlast   = LSU_WLAST;   assign m1_wvalid  = LSU_WVALID;
assign m1_bready  = LSU_BREADY;
assign LSU_ARREADY= m1_arready;  assign LSU_RID    = m1_rid;
assign LSU_RDATA  = m1_rdata;    assign LSU_RRESP  = m1_rresp;
assign LSU_RLAST  = m1_rlast;    assign LSU_RVALID = m1_rvalid;
assign LSU_AWREADY= m1_awready;  assign LSU_WREADY = m1_wready;
assign LSU_BID    = m1_bid;      assign LSU_BRESP  = m1_bresp;
assign LSU_BVALID = m1_bvalid;

axi4_full_arbiter u_arbiter (
    .clk          (clock),       .rst          (reset),
    .m0_prerequest(1'b0),        .m1_prerequest(1'b0),
    .m0_arid      (m0_arid),     .m0_araddr    (m0_araddr),
    .m0_arlen     (m0_arlen),    .m0_arsize    (m0_arsize),
    .m0_arburst   (m0_arburst),  .m0_arvalid   (m0_arvalid),
    .m0_arready   (m0_arready),  .m0_rid       (m0_rid),
    .m0_rdata     (m0_rdata),    .m0_rresp     (m0_rresp),
    .m0_rlast     (m0_rlast),    .m0_rvalid    (m0_rvalid),
    .m0_rready    (m0_rready),
    .m0_awid      (m0_awid),     .m0_awaddr    (m0_awaddr),
    .m0_awlen     (m0_awlen),    .m0_awsize    (m0_awsize),
    .m0_awburst   (m0_awburst),  .m0_awvalid   (m0_awvalid),
    .m0_awready   (m0_awready),  .m0_wdata     (m0_wdata),
    .m0_wstrb     (4'b0),        .m0_wlast     (m0_wlast),
    .m0_wvalid    (m0_wvalid),   .m0_wready    (m0_wready),
    .m0_bid       (m0_bid),      .m0_bresp     (m0_bresp),
    .m0_bvalid    (m0_bvalid),   .m0_bready    (m0_bready),
    .m1_arid      (m1_arid),     .m1_araddr    (m1_araddr),
    .m1_arlen     (m1_arlen),    .m1_arsize    (m1_arsize),
    .m1_arburst   (m1_arburst),  .m1_arvalid   (m1_arvalid),
    .m1_arready   (m1_arready),  .m1_rid       (m1_rid),
    .m1_rdata     (m1_rdata),    .m1_rresp     (m1_rresp),
    .m1_rlast     (m1_rlast),    .m1_rvalid    (m1_rvalid),
    .m1_rready    (m1_rready),
    .m1_awid      (m1_awid),     .m1_awaddr    (m1_awaddr),
    .m1_awlen     (m1_awlen),    .m1_awsize    (m1_awsize),
    .m1_awburst   (m1_awburst),  .m1_awvalid   (m1_awvalid),
    .m1_awready   (m1_awready),  .m1_wdata     (m1_wdata),
    .m1_wstrb     (m1_wstrb),    .m1_wlast     (m1_wlast),
    .m1_wvalid    (m1_wvalid),   .m1_wready    (m1_wready),
    .m1_bid       (m1_bid),      .m1_bresp     (m1_bresp),
    .m1_bvalid    (m1_bvalid),   .m1_bready    (m1_bready),
    .s_arid       (s_arid),      .s_araddr     (s_araddr),
    .s_arlen      (s_arlen),     .s_arsize     (s_arsize),
    .s_arburst    (s_arburst),   .s_arvalid    (s_arvalid),
    .s_arready    (s_arready),   .s_rid        (s_rid),
    .s_rdata      (s_rdata),     .s_rresp      (s_rresp),
    .s_rlast      (s_rlast),     .s_rvalid     (s_rvalid),
    .s_rready     (s_rready),
    .s_awid       (s_awid),      .s_awaddr     (s_awaddr),
    .s_awlen      (s_awlen),     .s_awsize     (s_awsize),
    .s_awburst    (s_awburst),   .s_awvalid    (s_awvalid),
    .s_awready    (s_awready),   .s_wdata      (s_wdata),
    .s_wstrb      (s_wstrb),     .s_wlast      (s_wlast),
    .s_wvalid     (s_wvalid),    .s_wready     (s_wready),
    .s_bid        (s_bid),       .s_bresp      (s_bresp),
    .s_bvalid     (s_bvalid),    .s_bready     (s_bready)
);

// ================================================================
//  Xbar：arbiter → S0(io_master) + S1(CLINT)
// ================================================================
logic [3:0]  m_arid,  m_awid,  m_rid,  m_bid;
logic [31:0] m_araddr,m_awaddr,m_rdata,m_wdata;
logic [7:0]  m_arlen, m_awlen;
logic [2:0]  m_arsize,m_awsize;
logic [1:0]  m_arburst,m_awburst,m_rresp,m_bresp;
logic        m_arvalid,m_arready,m_rvalid,m_rlast,m_rready;
logic        m_awvalid,m_awready,m_wlast,m_wvalid,m_wready,m_bvalid,m_bready;
logic [3:0]  m_wstrb;

// arbiter slave → Xbar master（直连）
assign m_arid=s_arid; assign m_araddr=s_araddr; assign m_arlen=s_arlen;
assign m_arsize=s_arsize; assign m_arburst=s_arburst; assign m_arvalid=s_arvalid;
assign s_arready=m_arready;
assign s_rid=m_rid; assign s_rdata=m_rdata; assign s_rresp=m_rresp;
assign s_rlast=m_rlast; assign s_rvalid=m_rvalid; assign m_rready=s_rready;
assign m_awid=s_awid; assign m_awaddr=s_awaddr; assign m_awlen=s_awlen;
assign m_awsize=s_awsize; assign m_awburst=s_awburst; assign m_awvalid=s_awvalid;
assign s_awready=m_awready;
assign m_wdata=s_wdata; assign m_wstrb=s_wstrb; assign m_wlast=s_wlast;
assign m_wvalid=s_wvalid; assign s_wready=m_wready;
assign s_bid=m_bid; assign s_bresp=m_bresp; assign s_bvalid=m_bvalid;
assign m_bready=s_bready;

// Xbar S0 ↔ io_master
logic [3:0]  s0_arid,s0_awid,s0_bid;     logic [31:0] s0_araddr,s0_awaddr,s0_wdata;
logic [7:0]  s0_arlen,s0_awlen;          logic [2:0]  s0_arsize,s0_awsize;
logic [1:0]  s0_arburst,s0_awburst;      logic [3:0]  s0_wstrb;
logic        s0_arvalid,s0_arready,s0_awvalid,s0_awready;
logic        s0_wlast,s0_wvalid,s0_wready,s0_bvalid,s0_bready;
logic        s0_rready;
logic [1:0]  s0_bresp;

// Xbar S1 ↔ CLINT
logic [3:0]  s1_arid,s1_awid,s1_bid,s1_rid;
logic [31:0] s1_araddr,s1_awaddr,s1_wdata,s1_rdata;
logic [7:0]  s1_arlen,s1_awlen;  logic [2:0] s1_arsize,s1_awsize;
logic [1:0]  s1_arburst,s1_awburst,s1_rresp,s1_bresp; logic [3:0] s1_wstrb;
logic        s1_arvalid,s1_arready,s1_rvalid,s1_rlast,s1_rready;
logic        s1_awvalid,s1_awready,s1_wlast,s1_wvalid,s1_wready,s1_bvalid,s1_bready;

Xbar u_xbar (
    .m_arid    (m_arid),   .m_araddr  (m_araddr), .m_arlen   (m_arlen),
    .m_arsize  (m_arsize), .m_arburst (m_arburst),.m_arvalid (m_arvalid),
    .m_arready (m_arready),.m_rid     (m_rid),    .m_rdata   (m_rdata),
    .m_rresp   (m_rresp),  .m_rlast   (m_rlast),  .m_rvalid  (m_rvalid),
    .m_rready  (m_rready),
    .m_awid    (m_awid),   .m_awaddr  (m_awaddr), .m_awlen   (m_awlen),
    .m_awsize  (m_awsize), .m_awburst (m_awburst),.m_awvalid (m_awvalid),
    .m_awready (m_awready),.m_wdata   (m_wdata),  .m_wstrb   (m_wstrb),
    .m_wlast   (m_wlast),  .m_wvalid  (m_wvalid), .m_wready  (m_wready),
    .m_bid     (m_bid),    .m_bresp   (m_bresp),  .m_bvalid  (m_bvalid),
    .m_bready  (m_bready),
    .s0_arid   (s0_arid),  .s0_araddr (s0_araddr),.s0_arlen  (s0_arlen),
    .s0_arsize (s0_arsize),.s0_arburst(s0_arburst),.s0_arvalid(s0_arvalid),
    .s0_arready(s0_arready),.s0_rid   (io_master_rid),.s0_rdata(io_master_rdata),
    .s0_rresp  (io_master_rresp),.s0_rlast(io_master_rlast),.s0_rvalid(io_master_rvalid),
    .s0_rready (s0_rready),
    .s0_awid   (s0_awid),  .s0_awaddr (s0_awaddr),.s0_awlen  (s0_awlen),
    .s0_awsize (s0_awsize),.s0_awburst(s0_awburst),.s0_awvalid(s0_awvalid),
    .s0_awready(io_master_awready),.s0_wdata(s0_wdata),.s0_wstrb(s0_wstrb),
    .s0_wlast  (s0_wlast), .s0_wvalid (s0_wvalid),.s0_wready (io_master_wready),
    .s0_bid    (io_master_bid),.s0_bresp(io_master_bresp),.s0_bvalid(io_master_bvalid),
    .s0_bready (s0_bready),
    .s1_arid   (s1_arid),  .s1_araddr (s1_araddr),.s1_arlen  (s1_arlen),
    .s1_arsize (s1_arsize),.s1_arburst(s1_arburst),.s1_arvalid(s1_arvalid),
    .s1_arready(s1_arready),.s1_rid   (s1_rid),   .s1_rdata  (s1_rdata),
    .s1_rresp  (s1_rresp), .s1_rlast  (s1_rlast), .s1_rvalid (s1_rvalid),
    .s1_rready (s1_rready),
    .s1_awid   (s1_awid),  .s1_awaddr (s1_awaddr),.s1_awlen  (s1_awlen),
    .s1_awsize (s1_awsize),.s1_awburst(s1_awburst),.s1_awvalid(s1_awvalid),
    .s1_awready(s1_awready),.s1_wdata (s1_wdata), .s1_wstrb  (s1_wstrb),
    .s1_wlast  (s1_wlast), .s1_wvalid (s1_wvalid),.s1_wready (s1_wready),
    .s1_bid    (s1_bid),   .s1_bresp  (s1_bresp), .s1_bvalid (s1_bvalid),
    .s1_bready (s1_bready)
);

// Xbar S0 → io_master
assign io_master_arvalid = s0_arvalid; assign s0_arready = io_master_arready;
assign io_master_araddr  = s0_araddr;  assign io_master_arid   = s0_arid;
assign io_master_arlen   = s0_arlen;   assign io_master_arsize  = s0_arsize;
assign io_master_arburst = s0_arburst;
assign io_master_rready  = s0_rready;
assign io_master_awvalid = s0_awvalid; assign io_master_awaddr = s0_awaddr;
assign io_master_awid    = s0_awid;    assign io_master_awlen  = s0_awlen;
assign io_master_awsize  = s0_awsize;  assign io_master_awburst= s0_awburst;
assign io_master_wvalid  = s0_wvalid;  assign io_master_wdata  = s0_wdata;
assign io_master_wstrb   = s0_wstrb;   assign io_master_wlast  = s0_wlast;
assign io_master_bready  = s0_bready;

// ================================================================
//  CLINT（S1）
// ================================================================
CLINT u_clint (
    .clk    (clock),     .rst    (reset),
    .arid   (s1_arid),   .araddr (s1_araddr), .arlen  (s1_arlen),
    .arsize (s1_arsize), .arburst(s1_arburst),.arvalid(s1_arvalid),
    .arready(s1_arready),.rid    (s1_rid),    .rdata  (s1_rdata),
    .rresp  (s1_rresp),  .rlast  (s1_rlast),  .rvalid (s1_rvalid),
    .rready (s1_rready),
    .awid   (s1_awid),   .awaddr (s1_awaddr), .awlen  (s1_awlen),
    .awsize (s1_awsize), .awburst(s1_awburst),.awvalid(s1_awvalid),
    .awready(s1_awready),.wdata  (s1_wdata),  .wstrb  (s1_wstrb),
    .wlast  (s1_wlast),  .wvalid (s1_wvalid), .wready (s1_wready),
    .bid    (s1_bid),    .bresp  (s1_bresp),  .bvalid (s1_bvalid),
    .bready (s1_bready)
);

endmodule
