`ifndef PIPELINE_PKT_PKG_DEFINED
`define PIPELINE_PKT_PKG_DEFINED

package pipeline_pkt_pkg;

typedef struct packed {
    logic [31:0] inst;
    logic [31:0] pc;
} if2id_pkt_t;

// assign data_o = {alu_op, rs1_addr_hazard, rs2_addr_hazard, alu_src_sel, rs1_data, rs2_data, pc, imm, is_jump, is_jalr, is_branch, branch_cond, csr_wen, csr_cmd, csr_ecall, csr_mret, csr_addr, ls_store, ls_load, ls_type, rd_addr};

typedef struct packed {
    logic   [3:0]   alu_op;
    logic   [4:0]   rs1_addr;       // 特殊处理后的值，待补充
    logic   [4:0]   rs2_addr;       // 特殊处理后的值，待补充
    logic   [1:0]   alu_src_sel;
    logic   [31:0]  rs1_data;
    logic   [31:0]  rs2_data;
    logic   [31:0]  pc;
    logic   [31:0]  imm;
    logic           is_jump;
    logic           is_jalr;
    logic           is_branch;
    logic   [1:0]   branch_cond;
    logic           csr_wen;
    logic           csr_cmd;
    logic           csr_ecall;
    logic           csr_mret;
    logic   [11:0]  csr_addr;
    logic           is_fence_i;
    logic           ls_store;
    logic           ls_load;
    logic   [2:0]   ls_type;
    logic   [4:0]   rd_addr;
} id2ex_pkt_t;

// assign data_o = {exu_result, rs2_data, rest_data};

typedef struct packed {
    logic   [31:0]  result;
    logic   [31:0]  rs2_data;
    logic           is_fence_i;
    logic   [31:0]  pc;
    logic           ls_store;
    logic           ls_load;
    logic   [2:0]   ls_type;
    logic   [4:0]   rd_addr;
} ex2ls_pkt_t;

// assign data_o = {rd_data, lsu_load, rest_data};

typedef struct packed {
    logic   [31:0]  result;
    logic   [4:0]   rd_addr;
    logic           is_load;
} ls2wb_pkt_t;
    
endpackage

`endif
