// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
// `define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
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

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else


localparam SPI_CTRL_GO_BUY	= 8;

// 状态
localparam NORMAL				= 0;
localparam XIP_SEND_ADDR		= 1;
localparam XIP_CONF_DIV			= 2;
localparam XIP_CONF_SS			= 3;
localparam XIP_CONF_CTRL_START	= 4;
localparam XIP_WAIT_DATA		= 5;
localparam XIP_GET_DATA			= 6;
localparam XIP_RESET_SS			= 7;

reg [3:0] state;

// 输出
assign in_pslverr = (in_paddr[31:28] == 4'h3 && in_psel && in_pwrite) ? 1'b1 : spi_pslverr;
assign in_pready = (in_paddr[31:28] == 4'h3 && in_psel && in_penable && in_pwrite) ? 1'b1 : (is_xip ? xip_pready : spi_pready);
assign in_prdata = is_xip ? xip_prdata : spi_prdata;

// XIP内部信号
wire [4:0] xip_paddr;
wire [31:0] xip_pwdata;
reg  [31:0] xip_prdata;
reg  xip_penable;
wire xip_pready;
wire xip_pwrite;

// 给定spi_top输入
wire [4:0] spi_paddr;
wire [31:0] spi_pwdata;
wire [3:0] spi_pstrb;
wire spi_pwrite;
wire spi_penable;
wire spi_psel = in_psel;

// 给定spi_top输出
wire spi_pready;
wire spi_pslverr;
wire [31:0] spi_prdata;


// XIP状态判断
wire is_xip = state != NORMAL;

// 输入信号多路复用
assign spi_paddr = is_xip ? xip_paddr[4:0] : in_paddr[4:0];
assign spi_pwdata = is_xip ? xip_pwdata : in_pwdata;
assign spi_pstrb = is_xip ? 4'b1111 : in_pstrb;
assign spi_pwrite = is_xip ? xip_pwrite : in_pwrite;
assign spi_penable = is_xip ? xip_penable : in_penable;

// 状态转移
wire is_flash_access = in_paddr[31:28] == 4'h3 && in_psel && !in_pwrite;
always @(posedge clock) begin
	if (reset) begin
		state <= NORMAL;
	end else begin
		case(state)
			NORMAL:
				state <= is_flash_access ? XIP_SEND_ADDR : state;
			XIP_SEND_ADDR:
				state <= (xip_penable & spi_pready) ? XIP_CONF_DIV : state;
			XIP_CONF_DIV:
				state <= (xip_penable & spi_pready) ? XIP_CONF_SS : state;
			XIP_CONF_SS:
				state <= (xip_penable & spi_pready) ? XIP_CONF_CTRL_START : state;
			XIP_CONF_CTRL_START:
				state <= (xip_penable & spi_pready) ? XIP_WAIT_DATA : state;
			XIP_WAIT_DATA:
				state <= (xip_penable & spi_pready & !spi_prdata[SPI_CTRL_GO_BUY]) ? XIP_GET_DATA : state;
			XIP_GET_DATA:
				state <= (xip_penable & spi_pready) ? XIP_RESET_SS : state;
			XIP_RESET_SS:
				state <= (xip_penable & spi_pready) ? NORMAL : state;
			default:
				state <= NORMAL;
	endcase
	end
end

// penable
always @(posedge clock) begin
	xip_penable <= (xip_penable & spi_pready & !reset) ? 1'b0 : 1'b1;
end

// paddr
assign xip_paddr = 	{5{(state == XIP_SEND_ADDR)}} & 5'h04 | {5{state == XIP_CONF_DIV}} & 5'h14 | {5{state == XIP_CONF_SS}} & 5'h18 |
					{5{state == XIP_CONF_CTRL_START}} & 5'h10 | {5{state == XIP_WAIT_DATA}} & 5'h10 | {5{state == XIP_GET_DATA}} & 5'h00 | {5{state == XIP_RESET_SS}} & 5'h18;

// pwdata
assign xip_pwdata = {32{(state == XIP_SEND_ADDR)}} & {8'h03, in_paddr[23:2], 2'b0} | {32{state == XIP_CONF_DIV}} & 32'h01 | {32{state == XIP_CONF_SS}} & 32'h01 |
					{32{state == XIP_CONF_CTRL_START}} & 32'h540 | {32{state == XIP_RESET_SS}} & 32'h00;			// XIP_WAIT_DATA XIP_GET_DATA只读不写

// prdata
// 大端转小端
always @(posedge clock) begin
	xip_prdata <= ((state == XIP_GET_DATA) & spi_pready) ? {spi_prdata[7:0], spi_prdata[15:8], spi_prdata[23:16], spi_prdata[31:24]} : xip_prdata;
end

// pwrite
assign xip_pwrite = (state != XIP_WAIT_DATA) && (state != XIP_GET_DATA);		// 只有这两个阶段需要读

// pready
assign xip_pready = (state == XIP_RESET_SS) & spi_pready & in_penable;


spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(spi_paddr[4:0]),
  .wb_dat_i(spi_pwdata),
  .wb_dat_o(spi_prdata),
  .wb_sel_i(spi_pstrb),
  .wb_we_i (spi_pwrite),
  .wb_stb_i(spi_psel),
  .wb_cyc_i(spi_penable),
  .wb_ack_o(spi_pready),
  .wb_err_o(spi_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);


`endif // FAST_FLASH

endmodule
