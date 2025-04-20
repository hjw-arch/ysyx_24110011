module vga_top_apb(
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

  output [7:0]  vga_r,
  output [7:0]  vga_g,
  output [7:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,
  output        vga_valid
);

localparam H_DISPLAY		= 640;
localparam H_FP				= 16;
localparam H_SYNC			= 96;
localparam H_BP				= 48;
localparam H_TOTAL			= H_DISPLAY + H_FP + H_SYNC + H_BP;

localparam V_DISPLAY		= 480;
localparam V_FP				= 10;
localparam V_SYNC			= 2;
localparam V_BP				= 33;
localparam V_TOTAL			= V_DISPLAY + V_FP + V_SYNC + V_BP;

localparam H_BITS			= $clog2(H_TOTAL);
localparam V_BITS			= $clog2(V_TOTAL);

localparam FRAME_DEPTH		= H_DISPLAY * V_DISPLAY;

reg [31:0] frame_buffer [0:FRAME_DEPTH-1];

reg [H_BITS - 1 : 0] h_cnt;
reg [V_BITS - 1 : 0] v_cnt;

wire [18:0] addr = in_paddr[20:2];

/************************************ APB 回复 *********************************/

assign in_pready = 1'b1;
assign in_pslverr = 1'b0;



/************************************ APB 写逻辑 **********************************/

always_ff @(posedge clock) begin
	frame_buffer[addr][7:0] <= (in_pstrb[0] & in_penable & in_pwrite) ? in_pwdata[7:0] : frame_buffer[addr][7:0];
	frame_buffer[addr][15:8] <= (in_pstrb[1] & in_penable & in_pwrite) ? in_pwdata[15:8] : frame_buffer[addr][15:8];
	frame_buffer[addr][23:16] <= (in_pstrb[2] & in_penable & in_pwrite) ? in_pwdata[23:16] : frame_buffer[addr][23:16];
end

/********************************** APB 读逻辑 **********************************/

assign in_prdata = (in_penable & ~in_pwrite) ? frame_buffer[addr] : 32'b0;



/********************************** VGA 输出 ***************************/

// 行计数器
always_ff @(posedge clock) begin
	if (reset) begin
		h_cnt <= 10'b0;
	end else begin
		h_cnt <= (h_cnt == H_TOTAL - 1) ? 10'b0 : h_cnt + 1;
	end
end

// 列计数器
always_ff @(posedge clock) begin
	if (reset) begin
		v_cnt <= 10'b0;
	end else begin
		case ({(h_cnt == H_TOTAL - 1), (v_cnt == V_TOTAL - 1)})
			2'b10: v_cnt <= v_cnt + 1;
			2'b11: v_cnt <= 10'b0;
			default: v_cnt <= v_cnt;
		endcase
	end
end

// vga_hsync
assign vga_hsync = ~hsync_active;
reg hsync_active;
always_ff @(posedge clock) begin
	if (reset) begin
		hsync_active <= 1'b0;
	end else begin
		case({(h_cnt == H_DISPLAY + H_FP - 1), (h_cnt == H_DISPLAY + H_FP + H_SYNC - 1)})
			2'b10: hsync_active <= 1'b1;
			2'b01: hsync_active <= 1'b0;
			default: hsync_active <= hsync_active;
		endcase
	end
end

// vga_vsync
assign vga_vsync = ~vsync_active;
reg vsync_active;
always_ff @(posedge clock) begin
	if (reset) begin
		vsync_active <= 1'b1;
	end else begin
		case({(h_cnt == H_TOTAL - 1), (v_cnt == V_DISPLAY + V_FP - 1), (v_cnt == V_DISPLAY + V_FP + V_SYNC - 1)})
			3'b110: vsync_active <= 1'b1;
			3'b101: vsync_active <= 1'b0;
			default: vsync_active <= vsync_active;
		endcase
	end
end

// vga_valid
// assign vga_valid = (h_cnt < H_DISPLAY) && (v_cnt < V_DISPLAY);
assign vga_valid = valid_h_active & valid_v_active;
reg valid_h_active, valid_v_active;

always_ff @(posedge clock) begin
	if (reset) begin
		valid_h_active <= 1'b1;
	end else begin
		case ({(h_cnt == H_TOTAL - 1), (h_cnt == H_DISPLAY - 1)})
			2'b10: valid_h_active <= 1'b1;
			2'b01: valid_h_active <= 1'b0;
			default: valid_h_active <= valid_h_active;
		endcase
	end
end

always_ff @(posedge clock) begin
	if (reset) begin
		valid_v_active <= 1'b1;
	end else begin
		case ({(h_cnt == H_TOTAL - 1), (v_cnt == V_TOTAL - 1), (v_cnt == V_DISPLAY - 1)})
			3'b110: valid_v_active <= 1'b1;
			3'b101: valid_v_active <= 1'b0; 
			default: valid_v_active <= valid_v_active;
		endcase
	end
end


// 计算输出
reg [20:0] pixel_cnt;
always_ff @(posedge clock) begin
	if (reset) begin
		pixel_cnt <= 21'b0;
	end else begin
		pixel_cnt <= ((h_cnt == H_TOTAL - 1) && (v_cnt == V_TOTAL - 1)) ? 21'b0 : vga_valid ? pixel_cnt + 1 : pixel_cnt;
	end
end


assign vga_r = vga_valid ? frame_buffer[pixel_cnt[18:0]][23:16] : 8'b0;
assign vga_g = vga_valid ? frame_buffer[pixel_cnt[18:0]][15:8] : 8'b0;
assign vga_b = vga_valid ? frame_buffer[pixel_cnt[18:0]][7:0] : 8'b0;


endmodule
