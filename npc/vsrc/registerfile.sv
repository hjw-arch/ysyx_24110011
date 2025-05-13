module registerfile #(parameter WIDTH = 32) (
    input clk,
    input wen,
    
    input [4 : 0] rd_addr,
    input [WIDTH - 1 : 0] rd_data,

    input [4 : 0] rs1_addr,
    output [WIDTH - 1 : 0] rs1_data,

    input [4 : 0] rs2_addr,
    output [WIDTH - 1 : 0] rs2_data
);

reg [WIDTH - 1 : 0] register_file [15 : 0];

wire not_x0 = |rd_addr;

always @(posedge clk) begin
    if (wen & not_x0) register_file[rd_addr[3:0]] <= rd_data;
end


assign rs1_data = rs1_addr != 0 ? register_file[rs1_addr[3:0]] : {WIDTH{1'b0}};
assign rs2_data = rs2_addr != 0 ? register_file[rs2_addr[3:0]] : {WIDTH{1'b0}};


endmodule
