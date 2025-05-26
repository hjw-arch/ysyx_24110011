module registerfile(
    input 			clk,
    input 			wen,
    
    input	[4:0]	rd_addr,
    input	[31:0]	rd_data,

    input	[4:0]	rs1_addr,
    output	[31:0]	rs1_data,

    input	[4:0]	rs2_addr,
    output	[31:0]	rs2_data
);

reg [31:0] register_file [0:14];		// RV32E


always @(posedge clk) begin
    if(wen) register_file[rd_addr[3:0]] <= rd_data;
end


assign rs1_data = rs1_addr == 0 ? 32'b0 : register_file[rs1_addr[3:0]];
assign rs2_data = rs2_addr == 0 ? 32'b0 : register_file[rs2_addr[3:0]];


endmodule
