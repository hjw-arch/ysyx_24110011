// ysyx_24110011.sv  —  单发射乱序执行处理器顶层
//
// 七级流水线：
//   IF → ID → Rename/Dispatch → Issue → RegRead → Execute/Memory → Commit
//
// 不变量：
//   1. 架构状态（AMT / CSR / 内存）只在 ROB commit 对外不可回滚
//   2. flush 仅 rob.flush_o；RAT/freelist 用 next_amt 恢复
//   3. store 不得在 commit 前进入 AXI；issue 只入 SQ，commit 后 drain
//   4. load：SQ CAM 全覆盖 STLF / 部分重叠 stall / 无重叠 AXI；IQ 仍 older_mem 序
//   5. 单发射：dispatch/issue/commit 宽均为 1；快、慢写回各使用一路唤醒
//   6. 仿真可见信号见 ROB commit 段「仿真契约」；改展平口须同步 cpu_exec.cpp

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
// EXU redirect 只写入 ROB complete；冲刷前端仅在 head 提交时 rob_flush
wire        exu_redirect_valid /* verilator public_flat_rd */;
wire [31:0] exu_redirect_addr  /* verilator public_flat_rd */;
wire        rob_flush          /* verilator public_flat_rd */;
wire [31:0] rob_flush_pc;

// flush 仅以 ROB 为准；redirect 目标见 redirect_pc_final（trap/mret/其它）
wire        pipeline_flush = rob_flush;

// ─── BPU 更新（来自 exu）──────────────────────────────────
wire        bpu_update_valid;
wire        bpu_update_btb_type;
wire        bpu_update_taken;
wire [31:0] bpu_update_pc;
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

// ─── IQ → EXU/LSU ─────────────────────────────────────────
wire              iq_issue_valid;
issue2ex_pkt_t    iq_issue_pkt;
wire              iq_issue_ready;
wire [5:0]        iq_phys_rs1;
wire [5:0]        iq_phys_rs2;

typedef struct packed {
    issue2ex_pkt_t pkt;
    logic [5:0]    phys_rs1;
    logic [5:0]    phys_rs2;
} issue_stage_t;

issue_stage_t issue_stage_in;
issue_stage_t issue_stage_out;
wire          issue_stage_valid;
wire          issue_stage_ready;

issue2ex_pkt_t execute_stage_in;
issue2ex_pkt_t execute_stage_out;
wire           execute_stage_valid;
wire           execute_stage_ready;

// ─── 物理寄存器堆（2R2W：快、慢写回各一路）──────────────
wire [31:0] prf_rs1_data;
wire [31:0] prf_rs2_data;
wire        prf_wen1;
wire [5:0]  prf_waddr1;
wire [31:0] prf_wdata1;
wire        prf_wen2;
wire [5:0]  prf_waddr2;
wire [31:0] prf_wdata2;

// ─── 唤醒信号（与两个 PRF 写端口一一对应）────────────────
wire        wakeup_en1;
wire [5:0]  wakeup_preg1;
wire        wakeup_en2;
wire [5:0]  wakeup_preg2;

// ─── EXU 完成信号 ──────────────────────────────────────────
wire        exu_complete_en;
wire [4:0]  exu_complete_idx;
wire [31:0] exu_complete_data;
wire        exu_complete_exc;
wire [3:0]  exu_complete_cause;
wire        exu_complete_redir_valid;
wire [31:0] exu_complete_redir_addr;
wire        exu_wakeup_en;
wire [5:0]  exu_wakeup_preg;

// ─── LSU 完成信号 ──────────────────────────────────────────
wire        lsu_ready;
wire        lsu_complete_en;
wire [4:0]  lsu_complete_idx;
wire [31:0] lsu_complete_data;
wire        lsu_complete_exc;
wire [3:0]  lsu_complete_cause;
wire        lsu_complete_rd_wen;
wire [5:0]  lsu_complete_phys_rd;

// ─── ROB commit ────────────────────────────────────────────
// 仿真契约：cpu_exec / DiffTest 只读下列展平信号，禁止再拆 commit_pkt 位域
wire        commit_valid /* verilator public_flat_rd */;
rob_commit_t commit_pkt;
wire [4:0]  rob_head_idx;

wire [31:0] commit_pc      /* verilator public_flat_rd */ = commit_pkt.pc;
wire [31:0] commit_inst    /* verilator public_flat_rd */ = commit_pkt.inst;
wire [4:0]  commit_arch_rd /* verilator public_flat_rd */ = commit_pkt.arch_rd;
wire        commit_rd_wen  /* verilator public_flat_rd */ = commit_pkt.rd_wen;

// ─── 提交点系统语义（对齐五级 WBU）────────────────────────
// CSR/ecall/mret/fence.i 仅在 ROB head 发射，complete 后下一拍提交。
// 真正的 CSR 读写、特权跳转目标、icache inval 都在 commit 完成。
// 精确异常（illegal / bus fault）走 exc_commit，写 mepc/mcause → mtvec。
wire commit_is_csr     = commit_valid & (commit_pkt.sys.csr_cmd != CSR_CMD_NONE);
wire commit_is_ecall   = commit_valid & (commit_pkt.sys.priv_redir == PRIV_REDIR_ECALL);
wire commit_is_mret    = commit_valid & (commit_pkt.sys.priv_redir == PRIV_REDIR_MRET);
wire commit_is_fence_i = commit_valid & commit_pkt.sys.fence_i;

wire        exc_commit_valid /* verilator public_flat_rd */;
wire [3:0]  exc_commit_cause;
wire [31:0] exc_commit_pc;

wire [11:0] commit_csr_addr = commit_pkt.inst[31:20];
wire [31:0] commit_csr_src  = commit_pkt.result; // EXU 放入的 csr_src
// CSRRW 无条件写；CSRRS/CSRRC 的 rs1/zimm==0 时只读不写
wire        commit_csr_wen  = commit_is_csr &
    ((commit_pkt.sys.csr_cmd == CSR_CMD_WRITE) | (|commit_pkt.inst[19:15]));

wire [31:0] csr_rdata;
wire [31:0] csr_mtvec;
wire [31:0] csr_mepc;

// trap：ecall 或精确异常
wire        csr_trap = commit_is_ecall | exc_commit_valid;
wire [31:0] csr_trap_pc = exc_commit_valid ? exc_commit_pc : commit_pkt.pc;
wire [31:0] csr_trap_cause = exc_commit_valid ? {28'b0, exc_commit_cause} : 32'd11;

// 架构可见提交结果：CSR 指令写回旧 CSR 值，其余用 ROB.result
wire [31:0] commit_result_arch /* verilator public_flat_rd */;
assign commit_result_arch = commit_is_csr ? csr_rdata : commit_pkt.result;

// fence.i 仅在提交点失效 icache（对齐五级，不做“任意 flush 都 inval”）
wire        icache_inval;
assign icache_inval = commit_is_fence_i;

// ecall/mret/精确异常的 flush 目标
wire [31:0] redirect_pc_final =
    (commit_is_ecall | exc_commit_valid) ? csr_mtvec :
    commit_is_mret                        ? csr_mepc  :
    rob_flush_pc;

// ─── Store Queue / drain / CAM 握手 ───────────────────────
wire        sq_alloc_en;
wire [4:0]  sq_alloc_rob_idx;
wire [31:0] sq_alloc_addr, sq_alloc_data;
wire [3:0]  sq_alloc_strb;
wire [1:0]  sq_alloc_size;
wire        sq_alloc_ready;

wire [31:0] sq_cam_addr;
wire [1:0]  sq_cam_size;
wire        sq_cam_hit, sq_cam_stall;
wire [31:0] sq_cam_data;

wire        sq_commit_req;
wire [4:0]  sq_commit_rob_idx;
wire        sq_commit_ready;
wire        sq_commit_fault;

wire        drain_req;
wire [31:0] drain_addr, drain_data;
wire [3:0]  drain_strb;
wire [1:0]  drain_size;
wire        drain_fire, drain_done, drain_fault;

// ================================================================
//  IFU
// ================================================================
logic [31:0] IFU_ARADDR;
logic [3:0]  IFU_ARID;
logic [7:0]  IFU_ARLEN;
logic [2:0]  IFU_ARSIZE;
logic [1:0]  IFU_ARBURST;
logic        IFU_ARVALID;
logic        IFU_ARREADY;
logic [3:0]  IFU_RID;
logic [31:0] IFU_RDATA;
logic [1:0]  IFU_RRESP;
logic        IFU_RVALID;
logic        IFU_RLAST;
logic        IFU_RREADY;

IFU u_ifu (
    .clk                 (clock),
    .rst                 (reset),
    .ARADDR              (IFU_ARADDR),
    .ARVALID             (IFU_ARVALID),
    .ARID                (IFU_ARID),
    .ARLEN               (IFU_ARLEN),
    .ARSIZE              (IFU_ARSIZE),
    .ARBURST             (IFU_ARBURST),
    .ARREADY             (IFU_ARREADY),
    .RVALID              (IFU_RVALID),
    .RDATA               (IFU_RDATA),
    .RRESP               (IFU_RRESP),
    .RLAST               (IFU_RLAST),
    .RID                 (IFU_RID),
    .RREADY              (IFU_RREADY),
    .icache_inval_i      (icache_inval),
    .redirect_valid_i    (pipeline_flush),
    .redirect_pc_i       (redirect_pc_final),
    .bpu_update_valid_i  (bpu_update_valid),
    .bpu_update_type_i   (bpu_update_btb_type),
    .bpu_update_taken_i  (bpu_update_taken),
    .bpu_update_pc_i     (bpu_update_pc),
    .bpu_update_target_i (bpu_update_target),
    .valid_o             (if2dec_valid),
    .data_o              (if2dec_data),
    .ready_i             (if2dec_ready)
);

// ================================================================
//  IDU
// ================================================================
idu u_idu (
    .valid_i (if2dec_valid),
    .data_i  (if2dec_data),
    .ready_o (if2dec_ready),
    .valid_o (dec2ren_valid),
    .data_o  (dec2ren_data),
    .ready_i (dec2ren_ready)
);

// ================================================================
//  CSR（仅在 commit 点读写，对齐 WBU）
// ================================================================
CSR u_csr (
    .clk          (clock),
    .rst          (reset),
    .wen          (commit_csr_wen & ~exc_commit_valid),
    .cmd          (commit_pkt.sys.csr_cmd),
    .addr         (commit_csr_addr),
    .wdata        (commit_csr_src),
    .trap_i       (csr_trap),
    .trap_pc_i    (csr_trap_pc),
    .trap_cause_i (csr_trap_cause),
    .rdata_o      (csr_rdata),
    .mtvec_o      (csr_mtvec),
    .mepc_o       (csr_mepc)
);

// ================================================================
//  Rename Stage
// ================================================================
rename_stage u_rename (
    .clk               (clock),
    .rst               (reset),
    .decode_valid_i    (dec2ren_valid),
    .decode_pkt_i      (dec2ren_data),
    .decode_ready_o    (dec2ren_ready),
    .dispatch_valid_o  (ren2iq_valid),
    .dispatch_pkt_o    (ren2iq_pkt),
    .dispatch_ready_i  (ren2iq_ready),
    .rob_alloc_idx_i   (rob_alloc_idx),
    .rob_ready_i       (rob_alloc_ready),
    .rob_alloc_en_o    (rob_alloc_en),
    .rob_alloc_pkt_o   (rob_alloc_pkt),
    .commit_valid_i    (commit_valid),
    .commit_arch_rd_i  (commit_pkt.arch_rd),
    .commit_phys_rd_i  (commit_pkt.phys_rd),
    .commit_preg_old_i (commit_pkt.phys_rd_old),
    .commit_rd_wen_i   (commit_pkt.rd_wen),
    .wakeup_en1_i      (wakeup_en1),
    .wakeup_preg1_i    (wakeup_preg1),
    .wakeup_en2_i      (wakeup_en2),
    .wakeup_preg2_i    (wakeup_preg2),
    .flush_i           (pipeline_flush)
);

// ================================================================
//  ROB（双路 complete：EXU + LSU 可同拍；store 等 SQ drain）
// ================================================================
rob u_rob (
    .clk                        (clock),
    .rst                        (reset),
    .alloc_en_i                 (rob_alloc_en),
    .alloc_pkt_i                (rob_alloc_pkt),
    .alloc_idx_o                (rob_alloc_idx),
    .alloc_ready_o              (rob_alloc_ready),
    .complete_en1_i             (exu_complete_en),
    .complete_idx1_i            (exu_complete_idx),
    .complete_data1_i           (exu_complete_data),
    .complete_exception1_i      (exu_complete_exc),
    .complete_cause1_i          (exu_complete_cause),
    .complete_redirect_valid1_i (exu_complete_redir_valid),
    .complete_redirect_addr1_i  (exu_complete_redir_addr),
    .complete_en2_i             (lsu_complete_en),
    .complete_idx2_i            (lsu_complete_idx),
    .complete_data2_i           (lsu_complete_data),
    .complete_exception2_i      (lsu_complete_exc),
    .complete_cause2_i          (lsu_complete_cause),
    .complete_redirect_valid2_i (1'b0),
    .complete_redirect_addr2_i  (32'b0),
    .store_commit_ready_i       (sq_commit_ready),
    .store_commit_fault_i       (sq_commit_fault),
    .store_commit_req_o         (sq_commit_req),
    .store_commit_rob_idx_o     (sq_commit_rob_idx),
    .commit_valid_o             (commit_valid),
    .commit_pkt_o               (commit_pkt),
    .exc_commit_valid_o         (exc_commit_valid),
    .exc_commit_cause_o         (exc_commit_cause),
    .exc_commit_pc_o            (exc_commit_pc),
    .flush_o                    (rob_flush),
    .flush_pc_o                 (rob_flush_pc),
    .head_idx_o                 (rob_head_idx)
);

// ================================================================
//  Store Queue（commit 后 AXI 写）
// ================================================================
store_queue u_sq (
    .clk             (clock),
    .rst             (reset),
    .flush_i         (pipeline_flush),
    .alloc_en_i      (sq_alloc_en),
    .alloc_rob_idx_i (sq_alloc_rob_idx),
    .alloc_addr_i    (sq_alloc_addr),
    .alloc_data_i    (sq_alloc_data),
    .alloc_strb_i    (sq_alloc_strb),
    .alloc_size_i    (sq_alloc_size),
    .alloc_ready_o   (sq_alloc_ready),
    // empty 仅调试/TB；load 门控已由 CAM 取代
    .empty_o          (),
    .cam_addr_i       (sq_cam_addr),
    .cam_size_i       (sq_cam_size),
    .cam_hit_o        (sq_cam_hit),
    .cam_stall_o      (sq_cam_stall),
    .cam_data_o       (sq_cam_data),
    .commit_req_i     (sq_commit_req),
    .commit_rob_idx_i (sq_commit_rob_idx),
    .commit_ready_o   (sq_commit_ready),
    .commit_fault_o   (sq_commit_fault),
    .drain_req_o      (drain_req),
    .drain_addr_o     (drain_addr),
    .drain_data_o     (drain_data),
    .drain_strb_o     (drain_strb),
    .drain_size_o     (drain_size),
    .drain_fire_i     (drain_fire),
    .drain_done_i     (drain_done),
    .drain_fault_i    (drain_fault)
);

// ================================================================
//  Issue Queue
// ================================================================
issue_queue u_iq (
    .clk              (clock),
    .rst              (reset),
    .dispatch_en_i    (ren2iq_valid),
    .dispatch_pkt_i   (ren2iq_pkt),
    .dispatch_ready_o (ren2iq_ready),
    .issue_valid_o    (iq_issue_valid),
    .issue_pkt_o      (iq_issue_pkt),
    .issue_ready_i    (iq_issue_ready),
    .issue_phys_rs1_o (iq_phys_rs1),
    .issue_phys_rs2_o (iq_phys_rs2),
    .wakeup_en1_i     (wakeup_en1),
    .wakeup_preg1_i   (wakeup_preg1),
    .wakeup_en2_i     (wakeup_en2),
    .wakeup_preg2_i   (wakeup_preg2),
    .rob_head_i       (rob_head_idx),
    .flush_i          (pipeline_flush)
);

// ================================================================
//  Issue → RegRead/Execute：切断 IQ 选择到同拍 PRF 写回的组合路径
// ================================================================
assign issue_stage_in.pkt      = iq_issue_pkt;
assign issue_stage_in.phys_rs1 = iq_phys_rs1;
assign issue_stage_in.phys_rs2 = iq_phys_rs2;

pip_reg #(
    .WIDTH ($bits(issue_stage_t))
) u_issue_stage (
    .clk        (clock),
    .rst        (reset),
    .flush      (pipeline_flush),
    .pre_valid  (iq_issue_valid),
    .pre_data   (issue_stage_in),
    .pre_ready  (iq_issue_ready),
    .next_valid (issue_stage_valid),
    .next_data  (issue_stage_out),
    .next_ready (issue_stage_ready)
);

// ================================================================
//  Physical Register File（2R2W）
// ================================================================
// W1：EXU 完成或 CSR 提交的快写回；两者通过 execute_stage_ready 保证互斥。
// W2：LSU load 完成的慢写回。唤醒信号与当拍实际写使能一一对应。
physical_regfile u_prf (
    .clk           (clock),
    .rst           (reset),
    .read_addr1_i  (issue_stage_out.phys_rs1),
    .read_data1_o  (prf_rs1_data),
    .read_addr2_i  (issue_stage_out.phys_rs2),
    .read_data2_o  (prf_rs2_data),
    .write_en1_i   (prf_wen1),
    .write_addr1_i (prf_waddr1),
    .write_data1_i (prf_wdata1),
    .write_en2_i   (prf_wen2),
    .write_addr2_i (prf_waddr2),
    .write_data2_i (prf_wdata2)
);

wire        exu_prf_wen = exu_complete_en & execute_stage_out.rd_wen
    & (execute_stage_out.sys.csr_cmd == CSR_CMD_NONE)
    & ~execute_stage_out.exception;
wire        lsu_prf_wen = lsu_complete_en & lsu_complete_rd_wen;
wire        csr_prf_wen = commit_is_csr & commit_pkt.rd_wen;

wire execute_stage_is_mem = execute_stage_out.mem.cmd != MEM_NONE;
assign execute_stage_ready = execute_stage_is_mem ? lsu_ready : ~csr_prf_wen;

// CSR 与 EXU 按设计不会同时请求 W1；条件选择仍以 CSR 为优先级。
assign prf_wen1   = exu_prf_wen | csr_prf_wen;
assign prf_waddr1 = csr_prf_wen ? commit_pkt.phys_rd : execute_stage_out.phys_rd;
assign prf_wdata1 = csr_prf_wen ? csr_rdata          : exu_complete_data;

// LSU load 独占 W2。
assign prf_wen2   = lsu_prf_wen;
assign prf_waddr2 = lsu_complete_phys_rd;
assign prf_wdata2 = lsu_complete_data;

// 唤醒端口与 PRF 写端口保持相同的使能和目标寄存器。
assign wakeup_en1   = exu_wakeup_en | csr_prf_wen;
assign wakeup_preg1 = csr_prf_wen ? commit_pkt.phys_rd : exu_wakeup_preg;
assign wakeup_en2   = lsu_prf_wen;
assign wakeup_preg2 = lsu_complete_phys_rd;

// ================================================================
//  RegRead → Execute：隔离异步 PRF 读取与执行/写回组合逻辑
// ================================================================
always_comb begin
    execute_stage_in          = issue_stage_out.pkt;
    execute_stage_in.rs1_data = prf_rs1_data;
    execute_stage_in.rs2_data = prf_rs2_data;
end

pip_reg #(
    .WIDTH ($bits(issue2ex_pkt_t))
) u_execute_stage (
    .clk        (clock),
    .rst        (reset),
    .flush      (pipeline_flush),
    .pre_valid  (issue_stage_valid),
    .pre_data   (execute_stage_in),
    .pre_ready  (issue_stage_ready),
    .next_valid (execute_stage_valid),
    .next_data  (execute_stage_out),
    .next_ready (execute_stage_ready)
);

wire is_mem_inst = execute_stage_valid & execute_stage_is_mem & ~pipeline_flush;
wire is_exu_inst = execute_stage_valid & ~execute_stage_is_mem
    & execute_stage_ready & ~pipeline_flush;

// ================================================================
//  EXU
// ================================================================
exu u_exu (
    .clk                       (clock),
    .rst                       (reset),
    .valid_i                   (is_exu_inst),
    .data_i                    (execute_stage_out),
    .ready_o                   (),
    .complete_en_o             (exu_complete_en),
    .complete_idx_o            (exu_complete_idx),
    .complete_data_o           (exu_complete_data),
    .complete_exception_o      (exu_complete_exc),
    .complete_cause_o          (exu_complete_cause),
    .complete_redirect_valid_o (exu_complete_redir_valid),
    .complete_redirect_addr_o  (exu_complete_redir_addr),
    .wakeup_en_o               (exu_wakeup_en),
    .wakeup_preg_o             (exu_wakeup_preg),
    .redirect_valid_o          (exu_redirect_valid),
    .redirect_addr_o           (exu_redirect_addr),
    .bpu_update_valid_o        (bpu_update_valid),
    .bpu_update_btb_type_o     (bpu_update_btb_type),
    .bpu_update_taken_o        (bpu_update_taken),
    .bpu_update_pc_o           (bpu_update_pc),
    .bpu_update_target_o       (bpu_update_target)
);

// ================================================================
//  LSU + AXI
// ================================================================
logic [31:0] LSU_ARADDR, LSU_AWADDR, LSU_WDATA, LSU_RDATA;
logic [3:0]  LSU_ARID, LSU_AWID, LSU_RID, LSU_BID, LSU_WSTRB;
logic [7:0]  LSU_ARLEN, LSU_AWLEN;
logic [2:0]  LSU_ARSIZE, LSU_AWSIZE;
logic [1:0]  LSU_ARBURST, LSU_AWBURST, LSU_RRESP, LSU_BRESP;
logic        LSU_ARVALID, LSU_ARREADY, LSU_RVALID, LSU_RLAST, LSU_RREADY;
logic        LSU_AWVALID, LSU_AWREADY, LSU_WLAST, LSU_WVALID, LSU_WREADY;
logic        LSU_BVALID, LSU_BREADY;

lsu u_lsu (
    .clk                  (clock),
    .rst                  (reset),
    .valid_i              (is_mem_inst),
    .data_i               (execute_stage_out),
    .ready_o              (lsu_ready),
    .flush_i              (pipeline_flush),
    .complete_en_o        (lsu_complete_en),
    .complete_idx_o       (lsu_complete_idx),
    .complete_data_o      (lsu_complete_data),
    .complete_exception_o (lsu_complete_exc),
    .complete_cause_o     (lsu_complete_cause),
    .complete_rd_wen_o    (lsu_complete_rd_wen),
    .complete_phys_rd_o   (lsu_complete_phys_rd),
    .sq_alloc_en_o        (sq_alloc_en),
    .sq_alloc_rob_idx_o   (sq_alloc_rob_idx),
    .sq_alloc_addr_o      (sq_alloc_addr),
    .sq_alloc_data_o      (sq_alloc_data),
    .sq_alloc_strb_o      (sq_alloc_strb),
    .sq_alloc_size_o      (sq_alloc_size),
    .sq_alloc_ready_i     (sq_alloc_ready),
    .cam_addr_o           (sq_cam_addr),
    .cam_size_o           (sq_cam_size),
    .cam_hit_i            (sq_cam_hit),
    .cam_stall_i          (sq_cam_stall),
    .cam_data_i           (sq_cam_data),
    .drain_req_i          (drain_req),
    .drain_addr_i         (drain_addr),
    .drain_data_i         (drain_data),
    .drain_strb_i         (drain_strb),
    .drain_size_i         (drain_size),
    .drain_fire_o         (drain_fire),
    .drain_done_o         (drain_done),
    .drain_fault_o        (drain_fault),
    .ARADDR               (LSU_ARADDR),
    .ARID                 (LSU_ARID),
    .ARLEN                (LSU_ARLEN),
    .ARSIZE               (LSU_ARSIZE),
    .ARBURST              (LSU_ARBURST),
    .ARVALID              (LSU_ARVALID),
    .ARREADY              (LSU_ARREADY),
    .RID                  (LSU_RID),
    .RDATA                (LSU_RDATA),
    .RRESP                (LSU_RRESP),
    .RVALID               (LSU_RVALID),
    .RLAST                (LSU_RLAST),
    .RREADY               (LSU_RREADY),
    .AWADDR               (LSU_AWADDR),
    .AWLEN                (LSU_AWLEN),
    .AWSIZE               (LSU_AWSIZE),
    .AWID                 (LSU_AWID),
    .AWBURST              (LSU_AWBURST),
    .AWVALID              (LSU_AWVALID),
    .AWREADY              (LSU_AWREADY),
    .WDATA                (LSU_WDATA),
    .WLAST                (LSU_WLAST),
    .WSTRB                (LSU_WSTRB),
    .WVALID               (LSU_WVALID),
    .WREADY               (LSU_WREADY),
    .BID                  (LSU_BID),
    .BRESP                (LSU_BRESP),
    .BVALID               (LSU_BVALID),
    .BREADY               (LSU_BREADY)
);

// ================================================================
//  AXI Arbiter：IFU(m0) + LSU(m1) → 单主端口(s)
// ================================================================
logic [3:0]  m0_arid, m0_awid, m0_rid, m0_bid;
logic [31:0] m0_araddr, m0_awaddr, m0_rdata, m0_wdata;
logic [7:0]  m0_arlen, m0_awlen;
logic [2:0]  m0_arsize, m0_awsize;
logic [1:0]  m0_arburst, m0_awburst, m0_rresp, m0_bresp;
logic        m0_arvalid, m0_arready, m0_rvalid, m0_rlast, m0_rready;
logic        m0_awvalid, m0_awready, m0_wlast, m0_wvalid, m0_wready, m0_bvalid, m0_bready;

logic [3:0]  m1_arid, m1_awid, m1_rid, m1_bid;
logic [31:0] m1_araddr, m1_awaddr, m1_rdata, m1_wdata;
logic [7:0]  m1_arlen, m1_awlen;
logic [2:0]  m1_arsize, m1_awsize;
logic [1:0]  m1_arburst, m1_awburst, m1_rresp, m1_bresp;
logic        m1_arvalid, m1_arready, m1_rvalid, m1_rlast, m1_rready;
logic        m1_awvalid, m1_awready, m1_wlast, m1_wvalid, m1_wready, m1_bvalid, m1_bready;
logic [3:0]  m1_wstrb;

logic [3:0]  s_arid, s_awid, s_rid, s_bid;
logic [31:0] s_araddr, s_awaddr, s_rdata, s_wdata;
logic [7:0]  s_arlen,  s_awlen;
logic [2:0]  s_arsize, s_awsize;
logic [1:0]  s_arburst, s_awburst, s_rresp, s_bresp;
logic        s_arvalid, s_arready, s_rvalid, s_rlast, s_rready;
logic        s_awvalid, s_awready, s_wlast, s_wvalid, s_wready, s_bvalid, s_bready;
logic [3:0]  s_wstrb;

// IFU → m0（只读）
assign m0_arid     = IFU_ARID;
assign m0_araddr   = IFU_ARADDR;
assign m0_arlen    = IFU_ARLEN;
assign m0_arsize   = IFU_ARSIZE;
assign m0_arburst  = IFU_ARBURST;
assign m0_arvalid  = IFU_ARVALID;
assign m0_rready   = IFU_RREADY;
assign IFU_ARREADY = m0_arready;
assign IFU_RID     = m0_rid;
assign IFU_RDATA   = m0_rdata;
assign IFU_RRESP   = m0_rresp;
assign IFU_RLAST   = m0_rlast;
assign IFU_RVALID  = m0_rvalid;
assign m0_awid     = 4'b0;
assign m0_awaddr   = 32'b0;
assign m0_awlen    = 8'b0;
assign m0_awsize   = 3'b0;
assign m0_awburst  = 2'b0;
assign m0_awvalid  = 1'b0;
assign m0_wdata    = 32'b0;
assign m0_wlast    = 1'b0;
assign m0_wvalid   = 1'b0;
assign m0_bready   = 1'b1;

// LSU → m1
assign m1_arid     = LSU_ARID;
assign m1_araddr   = LSU_ARADDR;
assign m1_arlen    = LSU_ARLEN;
assign m1_arsize   = LSU_ARSIZE;
assign m1_arburst  = LSU_ARBURST;
assign m1_arvalid  = LSU_ARVALID;
assign m1_rready   = LSU_RREADY;
assign m1_awid     = LSU_AWID;
assign m1_awaddr   = LSU_AWADDR;
assign m1_awlen    = LSU_AWLEN;
assign m1_awsize   = LSU_AWSIZE;
assign m1_awburst  = LSU_AWBURST;
assign m1_awvalid  = LSU_AWVALID;
assign m1_wdata    = LSU_WDATA;
assign m1_wstrb    = LSU_WSTRB;
assign m1_wlast    = LSU_WLAST;
assign m1_wvalid   = LSU_WVALID;
assign m1_bready   = LSU_BREADY;
assign LSU_ARREADY = m1_arready;
assign LSU_RID     = m1_rid;
assign LSU_RDATA   = m1_rdata;
assign LSU_RRESP   = m1_rresp;
assign LSU_RLAST   = m1_rlast;
assign LSU_RVALID  = m1_rvalid;
assign LSU_AWREADY = m1_awready;
assign LSU_WREADY  = m1_wready;
assign LSU_BID     = m1_bid;
assign LSU_BRESP   = m1_bresp;
assign LSU_BVALID  = m1_bvalid;

axi4_full_arbiter u_arbiter (
    .clk           (clock),
    .rst           (reset),
    .m0_prerequest (1'b0),
    .m1_prerequest (1'b0),
    .m0_arid       (m0_arid),
    .m0_araddr     (m0_araddr),
    .m0_arlen      (m0_arlen),
    .m0_arsize     (m0_arsize),
    .m0_arburst    (m0_arburst),
    .m0_arvalid    (m0_arvalid),
    .m0_arready    (m0_arready),
    .m0_rid        (m0_rid),
    .m0_rdata      (m0_rdata),
    .m0_rresp      (m0_rresp),
    .m0_rlast      (m0_rlast),
    .m0_rvalid     (m0_rvalid),
    .m0_rready     (m0_rready),
    .m0_awid       (m0_awid),
    .m0_awaddr     (m0_awaddr),
    .m0_awlen      (m0_awlen),
    .m0_awsize     (m0_awsize),
    .m0_awburst    (m0_awburst),
    .m0_awvalid    (m0_awvalid),
    .m0_awready    (m0_awready),
    .m0_wdata      (m0_wdata),
    .m0_wstrb      (4'b0),
    .m0_wlast      (m0_wlast),
    .m0_wvalid     (m0_wvalid),
    .m0_wready     (m0_wready),
    .m0_bid        (m0_bid),
    .m0_bresp      (m0_bresp),
    .m0_bvalid     (m0_bvalid),
    .m0_bready     (m0_bready),
    .m1_arid       (m1_arid),
    .m1_araddr     (m1_araddr),
    .m1_arlen      (m1_arlen),
    .m1_arsize     (m1_arsize),
    .m1_arburst    (m1_arburst),
    .m1_arvalid    (m1_arvalid),
    .m1_arready    (m1_arready),
    .m1_rid        (m1_rid),
    .m1_rdata      (m1_rdata),
    .m1_rresp      (m1_rresp),
    .m1_rlast      (m1_rlast),
    .m1_rvalid     (m1_rvalid),
    .m1_rready     (m1_rready),
    .m1_awid       (m1_awid),
    .m1_awaddr     (m1_awaddr),
    .m1_awlen      (m1_awlen),
    .m1_awsize     (m1_awsize),
    .m1_awburst    (m1_awburst),
    .m1_awvalid    (m1_awvalid),
    .m1_awready    (m1_awready),
    .m1_wdata      (m1_wdata),
    .m1_wstrb      (m1_wstrb),
    .m1_wlast      (m1_wlast),
    .m1_wvalid     (m1_wvalid),
    .m1_wready     (m1_wready),
    .m1_bid        (m1_bid),
    .m1_bresp      (m1_bresp),
    .m1_bvalid     (m1_bvalid),
    .m1_bready     (m1_bready),
    .s_arid        (s_arid),
    .s_araddr      (s_araddr),
    .s_arlen       (s_arlen),
    .s_arsize      (s_arsize),
    .s_arburst     (s_arburst),
    .s_arvalid     (s_arvalid),
    .s_arready     (s_arready),
    .s_rid         (s_rid),
    .s_rdata       (s_rdata),
    .s_rresp       (s_rresp),
    .s_rlast       (s_rlast),
    .s_rvalid      (s_rvalid),
    .s_rready      (s_rready),
    .s_awid        (s_awid),
    .s_awaddr      (s_awaddr),
    .s_awlen       (s_awlen),
    .s_awsize      (s_awsize),
    .s_awburst     (s_awburst),
    .s_awvalid     (s_awvalid),
    .s_awready     (s_awready),
    .s_wdata       (s_wdata),
    .s_wstrb       (s_wstrb),
    .s_wlast       (s_wlast),
    .s_wvalid      (s_wvalid),
    .s_wready      (s_wready),
    .s_bid         (s_bid),
    .s_bresp       (s_bresp),
    .s_bvalid      (s_bvalid),
    .s_bready      (s_bready)
);

// ================================================================
//  Xbar：arbiter → S0(io_master) + S1(CLINT)
// ================================================================
logic [3:0]  m_arid, m_awid, m_rid, m_bid;
logic [31:0] m_araddr, m_awaddr, m_rdata, m_wdata;
logic [7:0]  m_arlen, m_awlen;
logic [2:0]  m_arsize, m_awsize;
logic [1:0]  m_arburst, m_awburst, m_rresp, m_bresp;
logic        m_arvalid, m_arready, m_rvalid, m_rlast, m_rready;
logic        m_awvalid, m_awready, m_wlast, m_wvalid, m_wready, m_bvalid, m_bready;
logic [3:0]  m_wstrb;

assign m_arid    = s_arid;
assign m_araddr  = s_araddr;
assign m_arlen   = s_arlen;
assign m_arsize  = s_arsize;
assign m_arburst = s_arburst;
assign m_arvalid = s_arvalid;
assign s_arready = m_arready;
assign s_rid     = m_rid;
assign s_rdata   = m_rdata;
assign s_rresp   = m_rresp;
assign s_rlast   = m_rlast;
assign s_rvalid  = m_rvalid;
assign m_rready  = s_rready;
assign m_awid    = s_awid;
assign m_awaddr  = s_awaddr;
assign m_awlen   = s_awlen;
assign m_awsize  = s_awsize;
assign m_awburst = s_awburst;
assign m_awvalid = s_awvalid;
assign s_awready = m_awready;
assign m_wdata   = s_wdata;
assign m_wstrb   = s_wstrb;
assign m_wlast   = s_wlast;
assign m_wvalid  = s_wvalid;
assign s_wready  = m_wready;
assign s_bid     = m_bid;
assign s_bresp   = m_bresp;
assign s_bvalid  = m_bvalid;
assign m_bready  = s_bready;

logic [3:0]  s0_arid, s0_awid, s0_bid;
logic [31:0] s0_araddr, s0_awaddr, s0_wdata;
logic [7:0]  s0_arlen, s0_awlen;
logic [2:0]  s0_arsize, s0_awsize;
logic [1:0]  s0_arburst, s0_awburst;
logic [3:0]  s0_wstrb;
logic        s0_arvalid, s0_arready, s0_awvalid, s0_awready;
logic        s0_wlast, s0_wvalid, s0_wready, s0_bvalid, s0_bready;
logic        s0_rready;
logic [1:0]  s0_bresp;

logic [3:0]  s1_arid, s1_awid, s1_bid, s1_rid;
logic [31:0] s1_araddr, s1_awaddr, s1_wdata, s1_rdata;
logic [7:0]  s1_arlen, s1_awlen;
logic [2:0]  s1_arsize, s1_awsize;
logic [1:0]  s1_arburst, s1_awburst, s1_rresp, s1_bresp;
logic [3:0]  s1_wstrb;
logic        s1_arvalid, s1_arready, s1_rvalid, s1_rlast, s1_rready;
logic        s1_awvalid, s1_awready, s1_wlast, s1_wvalid, s1_wready, s1_bvalid, s1_bready;

Xbar u_xbar (
    .m_arid     (m_arid),
    .m_araddr   (m_araddr),
    .m_arlen    (m_arlen),
    .m_arsize   (m_arsize),
    .m_arburst  (m_arburst),
    .m_arvalid  (m_arvalid),
    .m_arready  (m_arready),
    .m_rid      (m_rid),
    .m_rdata    (m_rdata),
    .m_rresp    (m_rresp),
    .m_rlast    (m_rlast),
    .m_rvalid   (m_rvalid),
    .m_rready   (m_rready),
    .m_awid     (m_awid),
    .m_awaddr   (m_awaddr),
    .m_awlen    (m_awlen),
    .m_awsize   (m_awsize),
    .m_awburst  (m_awburst),
    .m_awvalid  (m_awvalid),
    .m_awready  (m_awready),
    .m_wdata    (m_wdata),
    .m_wstrb    (m_wstrb),
    .m_wlast    (m_wlast),
    .m_wvalid   (m_wvalid),
    .m_wready   (m_wready),
    .m_bid      (m_bid),
    .m_bresp    (m_bresp),
    .m_bvalid   (m_bvalid),
    .m_bready   (m_bready),
    .s0_arid    (s0_arid),
    .s0_araddr  (s0_araddr),
    .s0_arlen   (s0_arlen),
    .s0_arsize  (s0_arsize),
    .s0_arburst (s0_arburst),
    .s0_arvalid (s0_arvalid),
    .s0_arready (s0_arready),
    .s0_rid     (io_master_rid),
    .s0_rdata   (io_master_rdata),
    .s0_rresp   (io_master_rresp),
    .s0_rlast   (io_master_rlast),
    .s0_rvalid  (io_master_rvalid),
    .s0_rready  (s0_rready),
    .s0_awid    (s0_awid),
    .s0_awaddr  (s0_awaddr),
    .s0_awlen   (s0_awlen),
    .s0_awsize  (s0_awsize),
    .s0_awburst (s0_awburst),
    .s0_awvalid (s0_awvalid),
    .s0_awready (io_master_awready),
    .s0_wdata   (s0_wdata),
    .s0_wstrb   (s0_wstrb),
    .s0_wlast   (s0_wlast),
    .s0_wvalid  (s0_wvalid),
    .s0_wready  (io_master_wready),
    .s0_bid     (io_master_bid),
    .s0_bresp   (io_master_bresp),
    .s0_bvalid  (io_master_bvalid),
    .s0_bready  (s0_bready),
    .s1_arid    (s1_arid),
    .s1_araddr  (s1_araddr),
    .s1_arlen   (s1_arlen),
    .s1_arsize  (s1_arsize),
    .s1_arburst (s1_arburst),
    .s1_arvalid (s1_arvalid),
    .s1_arready (s1_arready),
    .s1_rid     (s1_rid),
    .s1_rdata   (s1_rdata),
    .s1_rresp   (s1_rresp),
    .s1_rlast   (s1_rlast),
    .s1_rvalid  (s1_rvalid),
    .s1_rready  (s1_rready),
    .s1_awid    (s1_awid),
    .s1_awaddr  (s1_awaddr),
    .s1_awlen   (s1_awlen),
    .s1_awsize  (s1_awsize),
    .s1_awburst (s1_awburst),
    .s1_awvalid (s1_awvalid),
    .s1_awready (s1_awready),
    .s1_wdata   (s1_wdata),
    .s1_wstrb   (s1_wstrb),
    .s1_wlast   (s1_wlast),
    .s1_wvalid  (s1_wvalid),
    .s1_wready  (s1_wready),
    .s1_bid     (s1_bid),
    .s1_bresp   (s1_bresp),
    .s1_bvalid  (s1_bvalid),
    .s1_bready  (s1_bready)
);

// Xbar S0 → io_master
assign io_master_arvalid = s0_arvalid;
assign s0_arready        = io_master_arready;
assign io_master_araddr  = s0_araddr;
assign io_master_arid    = s0_arid;
assign io_master_arlen   = s0_arlen;
assign io_master_arsize  = s0_arsize;
assign io_master_arburst = s0_arburst;
assign io_master_rready  = s0_rready;
assign io_master_awvalid = s0_awvalid;
assign io_master_awaddr  = s0_awaddr;
assign io_master_awid    = s0_awid;
assign io_master_awlen   = s0_awlen;
assign io_master_awsize  = s0_awsize;
assign io_master_awburst = s0_awburst;
assign io_master_wvalid  = s0_wvalid;
assign io_master_wdata   = s0_wdata;
assign io_master_wstrb   = s0_wstrb;
assign io_master_wlast   = s0_wlast;
assign io_master_bready  = s0_bready;

// ================================================================
//  CLINT（S1）
// ================================================================
CLINT u_clint (
    .clk     (clock),
    .rst     (reset),
    .arid    (s1_arid),
    .araddr  (s1_araddr),
    .arlen   (s1_arlen),
    .arsize  (s1_arsize),
    .arburst (s1_arburst),
    .arvalid (s1_arvalid),
    .arready (s1_arready),
    .rid     (s1_rid),
    .rdata   (s1_rdata),
    .rresp   (s1_rresp),
    .rlast   (s1_rlast),
    .rvalid  (s1_rvalid),
    .rready  (s1_rready),
    .awid    (s1_awid),
    .awaddr  (s1_awaddr),
    .awlen   (s1_awlen),
    .awsize  (s1_awsize),
    .awburst (s1_awburst),
    .awvalid (s1_awvalid),
    .awready (s1_awready),
    .wdata   (s1_wdata),
    .wstrb   (s1_wstrb),
    .wlast   (s1_wlast),
    .wvalid  (s1_wvalid),
    .wready  (s1_wready),
    .bid     (s1_bid),
    .bresp   (s1_bresp),
    .bvalid  (s1_bvalid),
    .bready  (s1_bready)
);

endmodule
