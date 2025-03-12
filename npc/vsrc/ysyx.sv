module ysyx #(parameter WIDTH = 32) (
    input clk,
    input rst,

    // 用于测试
    output [31 : 0] inst,
    output [31 : 0] PC
);

assign inst = ifu_data[63 : 32];
assign PC = pc;

// PC
// 五级流水线需要修改
wire [1 : 0] pc_sel;
wire pc_sel_for_adder_left;
wire is_branch;
wire [31 : 0] pc_imm;
wire [31 : 0] pc_inst;
wire [31 : 0] pc;


// IF
wire ifu_valid;
wire [63 : 0] ifu_data;
wire [4 : 0] rs1_addr;
wire [4 : 0] rs2_addr;

// ID
wire idu_ready;
wire idu_valid;
wire [191 : 0] idu_data;


// EX
wire exu_ready;
wire exu_valid;
wire [108 : 0] exu_data;

// LS
wire lsu_ready;
wire lsu_valid;
wire [103 : 0] lsu_data;

// WB
wire can_start;
wire [31 : 0] rs1_data;
wire [31 : 0] rs2_data;


// IF
IFU #(WIDTH) IFU_INTER(
    .clk(clk),
    .rst(rst),
    .start(can_start),
    .pc(pc),        // 五级流水线需要修改
    .ifu_valid(ifu_valid),
    .ifu_data(ifu_data),
    .idu_ready(idu_ready)
);


// ID
IDU IDU_INTER(
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),

    .clk(clk),
    .rst(rst),
    .ifu_valid(ifu_valid),
    .ifu_data(ifu_data),
    .idu_ready(idu_ready),
    .idu_valid(idu_valid),
    .idu_data(idu_data),
    .exu_ready(exu_ready),

    // PC直通，五级流水线需要修改
    .pc_sel(pc_sel),
    .pc_sel_for_adder_left(pc_sel_for_adder_left),
    .is_branch(is_branch),
    .pc_imm(pc_imm),
    .pc_inst(pc_inst)
);

// EX
EXU #(WIDTH) EXU_INTER(
    .clk(clk),
    .rst(rst),

    .idu_valid(idu_valid),
    .idu_data(idu_data),
    .exu_ready(exu_ready),

    .exu_valid(exu_valid),
    .exu_data(exu_data),
    .lsu_ready(lsu_ready),

    // 直通PC，五级流水线需修改
    .pc_sel(pc_sel),
    .pc_sel_for_adder_left(pc_sel_for_adder_left),
    .is_branch(is_branch),
    .imm(pc_imm),
    .inst(pc_inst),
    .pc(pc)
);

// LS
LSU LSU_INTER(
    .clk(clk),
    .rst(rst),

    .exu_valid(exu_valid),
    .exu_data(exu_data),
    .lsu_ready(lsu_ready),

    .lsu_valid(lsu_valid),
    .lsu_data(lsu_data),
    .wbu_ready(1'b1)
);

// WB
WBU #(WIDTH) WBU_INTER(
    .rs1_addr(rs1_addr),
    .rs2_addr(rs2_addr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),

    .clk(clk),
    .rst(rst),

    .lsu_valid(lsu_valid),
    .lsu_data(lsu_data),
    .can_start(can_start)
);



endmodule
