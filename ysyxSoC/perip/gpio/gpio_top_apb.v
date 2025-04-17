module gpio_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [15:0] gpio_out,
  input  [15:0] gpio_in,
  output [7:0]  gpio_seg_0,
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);

reg [15:0] GPIO_16B_0;
reg [15:0] GPIO_16B_1;
reg [31:0] GPIO_32B;

assign gpio_out = GPIO_16B_0;

bcd7seg #(0) seg0 (
	.bcd(GPIO_32B[3:0]),
	.seg(gpio_seg_0)
);

bcd7seg #(0) seg1 (
	.bcd(GPIO_32B[7:4]),
	.seg(gpio_seg_1)
);

bcd7seg #(0) seg2 (
	.bcd(GPIO_32B[11:8]),
	.seg(gpio_seg_2)
);

bcd7seg #(0) seg3 (
	.bcd(GPIO_32B[15:12]),
	.seg(gpio_seg_3)
);

bcd7seg #(0) seg4 (
	.bcd(GPIO_32B[19:16]),
	.seg(gpio_seg_4)
);

bcd7seg #(0) seg5 (
	.bcd(GPIO_32B[23:20]),
	.seg(gpio_seg_5)
);

bcd7seg #(0) seg6 (
	.bcd(GPIO_32B[27:24]),
	.seg(gpio_seg_6)
);

bcd7seg #(0) seg7 (
	.bcd(GPIO_32B[31:28]),
	.seg(gpio_seg_7)
);

always_ff @(posedge clock) begin
	if (reset) GPIO_16B_0 <= 16'b0;
	else begin
		GPIO_16B_0[7:0] <= (in_penable & in_psel & in_pwrite & in_pstrb[0] & !in_paddr[3] & !in_paddr[2]) ? in_pwdata[7:0] : GPIO_16B_0[7:0];
		GPIO_16B_0[15:8] <= (in_penable & in_psel & in_pwrite & in_pstrb[1] & !in_paddr[3] & !in_paddr[2]) ? in_pwdata[15:8] : GPIO_16B_0[15:8];
	end
end

always_ff @(posedge clock) begin
	if (reset) GPIO_16B_1 <= 16'b0;
	else begin
		GPIO_16B_1 <= gpio_in;		// 可能根本不需要时序逻辑
	end
end

always_ff @(posedge clock) begin
	if (reset) GPIO_32B <= 32'b0;
	else begin
		GPIO_32B[7:0] <= (in_penable & in_psel & in_pwrite & in_pstrb[0] & in_paddr[3] & !in_paddr[2]) ? in_pwdata[7:0] : GPIO_32B[7:0];
		GPIO_32B[15:8] <= (in_penable & in_psel & in_pwrite & in_pstrb[1] & in_paddr[3] & !in_paddr[2]) ? in_pwdata[15:8] : GPIO_32B[15:8];
		GPIO_32B[23:16] <= (in_penable & in_psel & in_pwrite & in_pstrb[2] & in_paddr[3] & !in_paddr[2]) ? in_pwdata[23:16] : GPIO_32B[23:16];
		GPIO_32B[31:24] <= (in_penable & in_psel & in_pwrite & in_pstrb[3] & in_paddr[3] & !in_paddr[2]) ? in_pwdata[31:24] : GPIO_32B[31:24];
	end
end


// 读
// 16B0
assign in_prdata = rdata;
reg [31:0] rdata;
always_ff @(posedge clock) begin
	case({in_paddr[3:0], in_pwrite, in_penable})
		6'b000001: rdata <= {16'b0, GPIO_16B_0};
		6'b010001: rdata <= {16'b0, GPIO_16B_1};
		6'b100001: rdata <= GPIO_32B;
		default: rdata <= rdata;
	endcase
end


assign in_pready = (in_penable & in_psel);
assign in_pslverr = 1'b0;



endmodule





/* verilator lint_off DECLFILENAME */
module bcd7seg # (parameter PONIT = 0)(
    input [3 : 0] bcd,
    output [7 : 0] seg
);

    assign seg[0] = !PONIT;
    assign seg[1] = (~bcd[3] & ~bcd[2] & ~bcd[1]) | (~bcd[3] & bcd[2] & bcd[1] & bcd[0]) | (bcd[3] & bcd[2] & ~bcd[1] & ~bcd[0]);
    assign seg[2] = (~bcd[3] & ~bcd[2] & bcd[0]) | (~bcd[3] & ~bcd[2] & bcd[1]) | (~bcd[3] & bcd[1] & bcd[0]) | (bcd[3] & bcd[2] & ~bcd[1] & bcd[0]);
    assign seg[3] = (~bcd[3] & bcd[0]) | (~bcd[3] & bcd[2] & ~bcd[1]) | (~bcd[2] & ~bcd[1] & bcd[0]);
    assign seg[4] = (~bcd[3] & ~bcd[2] & ~bcd[1] & bcd[0]) | (~bcd[3] & bcd[2] & ~bcd[1] & ~bcd[0]) | (bcd[2] & bcd[1] & bcd[0]) | (bcd[3] & ~bcd[2] & bcd[1] & ~bcd[0]);
    assign seg[5] = (~bcd[3] & ~bcd[2] & bcd[1] & ~bcd[0]) | (bcd[3] & bcd[2] & bcd[1]) | (bcd[3] & bcd[2] & ~bcd[0]);
    assign seg[6] = (~bcd[3] & bcd[2] & ~bcd[1] & bcd[0]) | (bcd[3] & bcd[2] & bcd[1]) | (bcd[3] & bcd[2] & ~bcd[0]) | (bcd[2] & bcd[1] & ~bcd[0]) | (bcd[3] & bcd[1] & bcd[0]);
    assign seg[7] = (~bcd[3] & ~bcd[2] & ~bcd[1] & bcd[0]) | (~bcd[3] & bcd[2] & ~bcd[1] & ~bcd[0]) | (bcd[3] & ~bcd[2] & bcd[1] & bcd[0]) | (bcd[3] & bcd[2] & ~bcd[1] & bcd[0]);

endmodule

