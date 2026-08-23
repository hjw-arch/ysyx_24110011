`ifndef PIPELINE_PKT_PKG_DEFINED
`define PIPELINE_PKT_PKG_DEFINED

package pipeline_pkt_pkg;

//============================================================
// Common metadata
//============================================================
typedef struct packed {
    logic   [31:0]  pc;
    logic   [31:0]  inst;
    logic           pred_taken;
} if2id_pkt_t;

//============================================================
// ALU control
//============================================================

typedef logic [3:0] alu_op_t;

localparam alu_op_t ALU_ADD   = 4'b0000;
localparam alu_op_t ALU_SUB   = 4'b1000;
localparam alu_op_t ALU_SLL   = 4'b0001;
localparam alu_op_t ALU_SLT   = 4'b0010;
localparam alu_op_t ALU_SLTU  = 4'b0011;
localparam alu_op_t ALU_XOR   = 4'b0100;
localparam alu_op_t ALU_SRL   = 4'b0101;
localparam alu_op_t ALU_OR    = 4'b0110;
localparam alu_op_t ALU_AND   = 4'b0111;
localparam alu_op_t ALU_SRA   = 4'b1101;
localparam alu_op_t ALU_COPY2 = 4'b1100;

//============================================================
// ALU source encoding
//
// alu_src[1]: 0 -> rs1, 1 -> pc
// alu_src[0]: 0 -> rs2/4, 1 -> imm
//
// 00: rs1 + rs2
// 01: rs1 + imm
// 10: pc  + 4
// 11: pc  + imm
//============================================================
typedef logic [1:0] alu_src_t;

localparam alu_src_t ALU_SRC_RS1_RS2 = 2'b00;
localparam alu_src_t ALU_SRC_RS1_IMM = 2'b01;
localparam alu_src_t ALU_SRC_PC_4    = 2'b10;
localparam alu_src_t ALU_SRC_PC_IMM  = 2'b11;

//============================================================
// Immediate select
//============================================================
//
// Bit-aware encoding, chosen for a small imm_gen.
// imm_sel[1:0] can select imm[4:1] source directly:
//   00: I/J -> inst[24:21]
//   01: S/B -> inst[11:8]
//   10: U   -> 0
//   11: Z   -> inst[19:16]
//
// IMM_I is also the harmless default for instructions that do not use imm.

typedef logic [2:0] imm_sel_t;

localparam imm_sel_t IMM_I = 3'b000;
localparam imm_sel_t IMM_S = 3'b001;
localparam imm_sel_t IMM_Z = 3'b011;
localparam imm_sel_t IMM_J = 3'b100;
localparam imm_sel_t IMM_B = 3'b101;
localparam imm_sel_t IMM_U = 3'b110;

//============================================================
// Control-flow control
//============================================================

typedef logic [1:0] cfi_type_t;

localparam cfi_type_t CFI_NONE   = 2'b00;
localparam cfi_type_t CFI_BRANCH = 2'b01;
localparam cfi_type_t CFI_JAL    = 2'b10;
localparam cfi_type_t CFI_JALR   = 2'b11;

//============================================================
// Memory control
//============================================================
//
// Load/store size and sign are derived from inst[14:12] in LSU.
// Therefore mem_ctrl only needs the command.

typedef logic [1:0] mem_cmd_t;

localparam mem_cmd_t MEM_NONE  = 2'b00;
localparam mem_cmd_t MEM_LOAD  = 2'b01;
localparam mem_cmd_t MEM_STORE = 2'b10;

//============================================================
// CSR/System control
//============================================================

typedef logic [1:0] csr_cmd_t;

localparam csr_cmd_t CSR_CMD_NONE  = 2'b00;
localparam csr_cmd_t CSR_CMD_WRITE = 2'b01;
localparam csr_cmd_t CSR_CMD_SET   = 2'b10;
localparam csr_cmd_t CSR_CMD_CLEAR = 2'b11;

typedef logic [1:0] priv_redir_t;

localparam priv_redir_t PRIV_REDIR_NONE  = 2'b00;
localparam priv_redir_t PRIV_REDIR_ECALL = 2'b01;
localparam priv_redir_t PRIV_REDIR_MRET  = 2'b10;

//============================================================
// 异常 cause（与 RISC-V mcause 异常码对齐的子集）
//============================================================
typedef logic [3:0] exc_cause_t;

localparam exc_cause_t CAUSE_LOAD_ACCESS_FAULT  = 4'd5;
localparam exc_cause_t CAUSE_STORE_ACCESS_FAULT = 4'd7;

//============================================================
// Stage control structs
//============================================================

typedef struct packed {
    alu_op_t    alu_op;
    alu_src_t   alu_src;
    cfi_type_t  cfi_type;
} ex_ctrl_t;

typedef struct packed {
    mem_cmd_t   cmd;
} mem_ctrl_t;

typedef struct packed {
    csr_cmd_t       csr_cmd;
    priv_redir_t    priv_redir;
    logic           fence_i;
} sys_ctrl_t;

//============================================================
// OoO types (single-issue out-of-order execution)
//============================================================

// 物理寄存器编号（6 位，支持 64 个物理寄存器）
typedef logic [5:0] phys_reg_t;

// ROB 索引（5 位，支持 32 项 ROB）
typedef logic [4:0] rob_idx_t;

// ROB 分配包
typedef struct packed {
    logic   [31:0]  pc;
    logic   [31:0]  inst;
    logic   [4:0]   arch_rd;
    phys_reg_t      phys_rd;
    phys_reg_t      phys_rd_old;
    logic           rd_wen;
    logic           is_store;       // 提交时需 SQ drain
    sys_ctrl_t      sys;
} rob_alloc_pkt_t;

// ROB 提交包
// 仿真：cpu_exec 不拆本结构位域；顶层展平 commit_pc/inst/arch_rd/rd_wen/result_arch
// 改字段顺序或宽度时，必须同步 ysyx_24110011 展平口（若仍有 VlWide 读者）
typedef struct packed {
    logic   [4:0]   arch_rd;
    phys_reg_t      phys_rd;        // 提交时 arch_rd 对应的新物理寄存器
    phys_reg_t      phys_rd_old;    // 提交时释放的旧物理寄存器
    logic   [31:0]  result;
    logic           rd_wen;
    sys_ctrl_t      sys;
    logic   [31:0]  pc;
    logic   [31:0]  inst;
} rob_commit_t;

// Decode → Rename
typedef struct packed {
    logic   [31:0]  pc;
    logic   [31:0]  inst;
    logic           pred_taken;
    logic           rs1_used;
    logic           rs2_used;
    logic           rd_wen;
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic   [31:0]  imm;
} decode_pkt_t;

// Rename → Issue Queue
typedef struct packed {
    logic   [31:0]  pc;
    logic   [2:0]   funct3;
    logic           pred_taken;
    rob_idx_t       rob_idx;
    phys_reg_t      phys_rs1;
    phys_reg_t      phys_rs2;
    phys_reg_t      phys_rd;
    logic           rd_wen;
    logic           rs1_ready;
    logic           rs2_ready;
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic   [31:0]  imm;
} rename2issue_pkt_t;

// Issue Queue → Execute
typedef struct packed {
    logic   [31:0]  pc;
    logic   [2:0]   funct3;
    rob_idx_t       rob_idx;
    phys_reg_t      phys_rd;
    logic   [31:0]  rs1_data;
    logic   [31:0]  rs2_data;
    logic           pred_taken;     // 分支预测结果（用于误预测检测）
    logic           rd_wen;         // 目的寄存器写使能（用于唤醒判断）
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic   [31:0]  imm;
} issue2ex_pkt_t;

endpackage

`endif
