`include "./include/pipeline_pkt_pkg.sv"

module WBU
import pipeline_pkt_pkg::*;
(
    input               clk,
    input               rst,

    input   [4:0]       rs1_addr,
    input   [4:0]       rs2_addr,
    output  [31:0]      rs1_data,
    output  [31:0]      rs2_data,

    output  [4:0]       rd_addr_hazard,

    output              flush_o,
    output  [31:0]      flush_addr_o,
    output              invalidate_ic_o,

    input               valid_i,
    input   ls2wb_pkt_t data_i,
    output              ready_o
);

wire [31:0] inst     = data_i.meta.inst;
wire [31:0] pc       = data_i.meta.pc;
wire [4:0]  rd_addr  = inst[11:7];
wire [11:0] csr_addr = inst[31:20];

wire csr_valid = data_i.sys.csr_cmd != CSR_CMD_NONE;
wire ecall     = data_i.sys.priv_redir == PRIV_REDIR_ECALL;
wire mret      = data_i.sys.priv_redir == PRIV_REDIR_MRET;
wire fence_i   = data_i.sys.fence_i;

wire [31:0] csr_src = data_i.result;
wire csr_src_zero = ~|csr_src;

// CSRRW 无条件写 CSR；CSRRS/CSRRC 源为 0 时只读不写，避免无意义翻转。
wire csr_write_en = valid_i & csr_valid &
                    ((data_i.sys.csr_cmd == CSR_CMD_WRITE) | ~csr_src_zero);

wire [31:0] csr_rdata;
wire [31:0] csr_mtvec;
wire [31:0] csr_mepc;

CSR u_CSR (
    .clk       (clk),
    .rst       (rst),
    .wen       (csr_write_en),
    .cmd       (data_i.sys.csr_cmd),
    .addr      (csr_addr),
    .wdata     (csr_src),
    .ecall_i   (valid_i & ecall),
    .trap_pc_i (pc),
    .rdata_o   (csr_rdata),
    .mtvec_o   (csr_mtvec),
    .mepc_o    (csr_mepc)
);

// WBU 是提交点，当前没有会阻塞的后级。
assign ready_o = 1'b1;

// CSR 指令写回旧 CSR 值，普通指令写回前级 result。
wire [31:0] rf_wdata = csr_valid ? csr_rdata : data_i.result;
wire        rf_wen   = valid_i & data_i.wb.rd_wen;

assign rd_addr_hazard = rd_addr & {5{rf_wen}};

registerfile u_registerfile (
    .clk       (clk),
    .wen       (rf_wen),
    .rd_addr   (rd_addr),
    .rd_data   (rf_wdata),
    .rs1_addr  (rs1_addr),
    .rs1_data  (rs1_data),
    .rs2_addr  (rs2_addr),
    .rs2_data  (rs2_data)
);

// ecall/mret/fence.i 都在提交点发起 flush，保证系统事件精确生效。
wire priv_flush = ecall | mret;
wire sys_flush  = priv_flush | fence_i;

assign flush_o = valid_i & sys_flush;
assign invalidate_ic_o = valid_i & fence_i;

// fence.i 的重定向地址是 EXU 已经算好的 pc+4；ecall/mret 来自 CSR。
assign flush_addr_o = ecall ? csr_mtvec :
                      mret  ? csr_mepc  :
                              data_i.result;

endmodule
