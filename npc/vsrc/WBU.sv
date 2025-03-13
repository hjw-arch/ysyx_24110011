module WBU #(parameter WIDTH = 32) (
    // 给到IDU
    input [4 : 0] rs1_addr,
    input [4 : 0] rs2_addr,
    output [31 : 0] rs1_data,
    output [31 : 0] rs2_data,

    // 真正的WBU
    input clk,
    input rst,

    input lsu_valid,
    input [103 : 0] lsu_data,
    output wbu_valid
);


// 作为最后一个阶段，WB不需要状态机，接到新的任务就直接执行
// 因此LSU或许也不需要WAIT_READY这个状态，只要准备好就直接发，而WB只要接到新任务就直接写，但在这里我不进行这样的处理，等到五级流水线再说
// 多周期节省数据通路，直接在WB完成CSR的全部操作

wire [31 : 0] alu_result = lsu_data[103 : 72];
wire [31 : 0] lsu_rdata = lsu_data[71 : 40];
wire rd_wen = lsu_data[39];
wire [4 : 0] rd_addr = lsu_data[38 : 34];
wire [1 : 0] rd_input_sel = lsu_data[33 : 32];
wire [31 : 0] csr_data_o = lsu_data[31 : 0];

reg has_new_data;
always_ff @(posedge clk) begin
    has_new_data <= lsu_valid ? 1'b1 : 1'b0;
end

assign wbu_valid = has_new_data;


// 若为五级流水线，这里的csr_data需要通过上游模块传过来
wire [WIDTH - 1 : 0] rd_data = rd_input_sel == 2'b01 ? lsu_rdata : 
                               rd_input_sel == 2'b10 ? csr_data_o : 
                               alu_result;

registerfile #(32) RF_INTER (
    .clk(clk),
    .wen(rd_wen & has_new_data),
    .rd_addr(rd_addr),
    .rd_data(rd_data),
    .rs1_addr(rs1_addr),
    .rs1_data(rs1_data),
    .rs2_addr(rs2_addr),
    .rs2_data(rs2_data)
);


endmodule

