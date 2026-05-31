module registerfile #(
    parameter bit RV32E = 1'b1
)(
    input 			clk,
    input 			wen,
    
    input	[4:0]	rd_addr,
    input	[31:0]	rd_data,

    input	[4:0]	rs1_addr,
    output	[31:0]	rs1_data,

    input	[4:0]	rs2_addr,
    output	[31:0]	rs2_data
);

localparam int REG_NUM   = RV32E ? 16 : 32;
localparam int REG_IDX_W = RV32E ? 4  : 5;

logic [31:0] register_file [0:REG_NUM-1];

wire [REG_IDX_W-1:0] rd_idx  = rd_addr[REG_IDX_W-1:0];
wire [REG_IDX_W-1:0] rs1_idx = rs1_addr[REG_IDX_W-1:0];
wire [REG_IDX_W-1:0] rs2_idx = rs2_addr[REG_IDX_W-1:0];

wire rd_wen = wen & (|rd_idx);

wire [31:0] rs1_raw = (|rs1_idx) ? register_file[rs1_idx] : 32'b0;
wire [31:0] rs2_raw = (|rs2_idx) ? register_file[rs2_idx] : 32'b0;

// 同拍读写同一个寄存器时直接返回写入数据。
// 这样 ID 阶段消费者和 WB 阶段生产者同拍相遇时，不需要额外停顿一拍。
wire rs1_bypass = rd_wen & (rs1_idx == rd_idx);
wire rs2_bypass = rd_wen & (rs2_idx == rd_idx);

always_ff @(posedge clk) begin
    if (rd_wen) begin
        register_file[rd_idx] <= rd_data;
    end
end

assign rs1_data = rs1_bypass ? rd_data : rs1_raw;
assign rs2_data = rs2_bypass ? rd_data : rs2_raw;

endmodule
