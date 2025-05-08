module IDU (
    // 异步读寄存器堆
    output [4 : 0] rs1_addr,
    output [4 : 0] rs2_addr,
    input [31 : 0] rs1_data,
    input [31 : 0] rs2_data,

    input clk,
    input rst,

    // 实现上下游握手信号
    input ifu_valid,
    input [63 : 0] ifu_data,
    output idu_ready,

    // IDU部分
    output idu_valid,
    output reg [191 : 0] idu_data,
    input  exu_ready,



    // 直通PC，仅仅在多周期有效，五级流水线需要修改，因为不是最终版因此随意了一些
    output [1 : 0] pc_sel,
    output pc_sel_for_adder_left,
    output is_branch,
    output [31 : 0] pc_imm,
    output [31 : 0] pc_inst
);

wire [31 : 0] inst = ifu_data[63 : 32];
wire [31 : 0] pc = ifu_data[31 : 0];

// IDU部分
// 握手协议实现
typedef enum logic { 
    S_IDLE,
    S_WAIT_READY
} idu_state_t;

idu_state_t state, next_state;

always_ff @(posedge clk) begin
    state <= rst ? S_IDLE : next_state;
end

always_comb begin
    case(state)
        S_IDLE:
            next_state = (idu_valid & ~exu_ready) ? S_WAIT_READY : S_IDLE;
        S_WAIT_READY:
            next_state = exu_ready ? S_IDLE : S_WAIT_READY;
        default: 
            next_state = S_IDLE;
    endcase
end

reg has_new_data;
always_ff @(posedge clk) begin
    has_new_data <= (ifu_valid & idu_ready) ? 1'b1 : 1'b0;
end

assign idu_valid = has_new_data | (state == S_WAIT_READY);
assign idu_ready = exu_ready;      // 需要调整

always_ff @(posedge clk) begin
    idu_data <= (idu_valid & exu_ready) ? {alu_data1, alu_data2, alu_op, csr_wen, csr_sel, csr_is_ecall, csr_addr, pc, rs1_data, lsu_ren, lsu_wen, lsu_op, rs2_data, rd_wen, rd_addr, rd_input_sel} : idu_data;
end



/************************** 性能计数器 *****************************/

import "DPI-C" function void PerformanceCounter_idu_identify_inst(input int inst);

always_ff @(posedge clk) begin
	if (idu_valid & (state != S_WAIT_READY)) PerformanceCounter_idu_identify_inst(inst);
end

always_ff @(posedge clk) begin
	if (has_new_data) $display("IDU!\n");
end


/******************************************************************/



// Imm
wire [31 : 0] imm;
ImmGen #(32) ImmGen_INTER(inst, imm);

// RF部分
assign rs1_addr = inst[19 : 15];    // rs1 & rs2 直通RF，不需要握手信号
assign rs2_addr = inst[24 : 20];
wire [4 : 0] rd_addr = inst[11 : 7];        // 给到WBU

// EXU部分 如果使用独热码，关键路径可以被优化, 面积会增加
wire [3 : 0] alu_op;
assign alu_op[0] = ~inst[5] & inst[4] & ~inst[2] & inst[14] & ~inst[13] & inst[12] & inst[30] |             // srai
                   inst[5] & inst[4] & inst[30] |          // R
                   inst[5] & inst[4] & inst[2];   //  lui

assign alu_op[1] = inst[4] & ~inst[2] & inst[12] |      // compute i + compute R
                  inst[6] & ~inst[2] & inst[13];    // Bu

assign alu_op[2] = inst[4] & ~inst[2] & inst[13] |       // compute i + compute R
                  inst[6] & ~inst[2];     // B

assign alu_op[3] = inst[4] & ~inst[2] & inst[14] |        // compute i + compute R
                  inst[5] & inst[4] & inst[2];        // lui

wire alu_left_sel = inst[2];  // U + J
wire alu_right_sel = inst[4] & inst[2] | ~inst[5] & inst[4] | ~inst[6] & ~inst[4];    // U + competeI + L + S

wire [31 : 0] alu_data1 = {32{alu_left_sel}} & pc | {32{~alu_left_sel}} & rs1_data;
wire [31 : 0] alu_data2 = {32{~alu_left_sel & ~alu_right_sel}} & rs2_data | {32{alu_left_sel & ~alu_right_sel}} & {{29{1'b0}}, 3'b100} | {32{alu_right_sel}} & imm;

// CSR
wire [11 : 0] csr_addr = inst[31 : 20];
wire csr_wen = inst[6] & inst[4] & |inst[13 : 12]; // Zicsr    添加此类指令需重构
wire csr_sel = inst[6] & inst[4] & inst[13];  // // Zicsr    添加此类指令需重构
wire csr_is_ecall = is_sys & ~inst[29];


// LSU部分
wire lsu_wen = ~inst[6] & inst[5] & ~inst[4];      // S
wire lsu_ren = ~inst[5] & ~inst[4];        // L
wire [2 : 0] lsu_op = inst[14 : 12];


wire is_sys = inst[6] & inst[4] & ~inst[13] & ~inst[12];    // 系统相关指令，ecall、mret，添加指令时可能需要做调整

// RF WB
wire rd_wen = ~(inst[5] & ~inst[4] & ~inst[2] | is_sys);   // ~((B + S) | sys)
wire [1 : 0] rd_input_sel;
assign rd_input_sel[1] = inst[6] & inst[4];     // CSR
assign rd_input_sel[0] = ~inst[5] & ~inst[4];   // Load

// PC部分   直通PC
assign pc_sel[1] = is_sys & inst[29];   // mret
assign pc_sel[0] = is_sys;  // ecall
assign pc_sel_for_adder_left = inst[6] & ~inst[3] & inst[2];
assign is_branch = inst[6] & ~inst[4] & ~inst[2];
assign pc_imm = imm;
assign pc_inst = inst;

endmodule








/* verilator lint_off DECLFILENAME */
// 立即数生成器
module ImmGen #(parameter WIDTH = 32)(  /* verilator lint_off UNUSEDSIGNAL */
    input [31 : 0] inst,
    output [31 : 0] imm
);

// 64位需要扩展符号位
assign imm[WIDTH - 1 : 31] = {(WIDTH - 31){inst[31]}};

// 两级延迟
assign imm[10 : 5] = inst[30 : 25] & {6{~(inst[4] & inst[2])}}; // U-Type does not have imm[10 : 5] // {6~{~opcode[6] & opcode[4] & ~opcode[3] & opcode[2]}}， ~U

// 三级延迟，可以优化为两级延迟
assign imm[4 : 1] = inst[11 : 8] & {4{inst[5] & ~inst[2]}} |                    // S + B
                    inst[24 : 21] & {4{inst[3]}} |                                // J
                    inst[24 : 21] & {4{~inst[6] & ~inst[5] & ~inst[2]}} |     // I
                    inst[24 : 21] & {4{~inst[4] & ~inst[3] & inst[2]}};       // I

assign imm[0] = inst[20] & ~inst[6] & ~inst[5] & ~inst[2]  |              // I
                inst[20] & ~inst[4] & ~inst[3] & inst[2] |      // I
                inst[7] & ~inst[6] & inst[5] & ~inst[4];       // S

assign imm[30 : 20] = {11{inst[31] & ~(inst[4] & inst[2])}} | 
                      inst[30 : 20] & {11{inst[4] & inst[2]}}; // ~U | U

assign imm[19 : 12] = {8{inst[31] & inst[5] & ~inst[2]}} |                      // S + B
                      {8{inst[31] & ~inst[6] & ~inst[5] & ~inst[2]}} |        // I
                      {8{inst[31] & ~inst[4] & ~inst[3] & inst[2]}} |         // I
                      inst[19 : 12] & {8{inst[4] & inst[2]}} |                  // U
                      inst[19 : 12] & {8{inst[3]}};                               // J

assign imm[11] = inst[31] & ~inst[6] & inst[5] & ~inst[4] | 
                 inst[31] & ~inst[6] & ~inst[5] & ~inst[2] |
                 inst[31] & ~inst[4] & ~inst[3] & inst[2] |
                 inst[7] & inst[6] & ~inst[2] |
                 inst[20] & inst[3];

endmodule


