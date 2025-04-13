module sdram(
  	input        clk,
  	input        cke,
  	input        cs,
  	input        ras,
  	input        cas,
  	input        we,
  	input [12:0] a,
  	input [ 1:0] ba,
  	input [ 1:0] dqm,
  	inout [15:0] dq
);

localparam CMD_INHTBIT			= 4'b1xxx;
localparam CMD_NOP				= 4'b0111;
localparam CMD_ACTIVE			= 4'b0011;
localparam CMD_READ				= 4'b0101;
localparam CMD_WRITE			= 4'b0100;
localparam CMD_TERMINATE		= 4'b0110;
localparam CMD_PRECHARGE		= 4'b0010;
localparam CMD_REFRESH			= 4'b0001;
localparam CMD_LOAD_MODE		= 4'b0000;

localparam BANKS				= 4;
localparam ROWS					= 8192;
localparam COLS					= 512;
localparam DATA_WIDTH			= 16;


// 模式寄存器，仅仅实现突发长度和操作需要的时间
reg [2:0] burst_length;
reg [2:0] cas_latency;

// 存储阵列
reg [DATA_WIDTH - 1 : 0] memory [0:BANKS-1][0 : ROWS-1][0:COLS-1];

// 每个bank被激活的行数据，以及每个bank是否处于行激活状态
reg [12:0] active_row [0:BANKS-1];
reg	is_bank_active[0:BANKS-1];

// 行缓冲
reg [DATA_WIDTH - 1 : 0] row_buffer [0:BANKS-1][0:COLS-1];

// 输出数据
reg [DATA_WIDTH - 1 : 0] data_out;
reg data_out_enable;

// 突发长度计数器
reg [2:0] burst_counter;
reg [2:0] cas_counter;
reg [8:0] col_addr;
reg [1:0] bank_addr;

// CMD
wire [3:0] cmd = cke ? {cs, ras, cas, we} : CMD_NOP;

// 三态输出
wire [15:0] masked_dq_out = {dqm[1] ? 8'b0 : data_out[15:8], dqm[0] ? 8'b0 : data_out[7:0]};

assign dq = data_out_enable ? masked_dq_out : 16'bz;

// 初始化，用于仿真，没有也行，默认就是0
initial begin
	for (int i = 0; i < BANKS; i++) begin
		active_row[i] = 0;
		is_bank_active[i] = 0;
		for (int j = 0; j < COLS; j++) begin
			row_buffer[i][j] = 0;
		end	
	end

	data_out_enable = 0;
	data_out = 0;
	burst_counter = 0;
	col_addr = 0;
	bank_addr = 0;

	burst_length = 3'b000;
	cas_latency = 3'b010;
end

// burst_legth && cas_latency
wire [2:0] num_burst = burst_length == 3'b000 ? 3'b001 : burst_length == 3'b001 ? 3'b010 : 3'b001;
always_ff @(posedge clk) begin
	burst_length <= cmd == CMD_LOAD_MODE ? a[2:0] : burst_length;
	cas_latency <= cmd == CMD_LOAD_MODE ? a[6:4] : cas_latency;
end

// bank_addr
always_ff @(posedge clk) begin
	bank_addr <= (cmd == CMD_ACTIVE || cmd == CMD_READ || cmd == CMD_WRITE) ? ba : bank_addr;
end

// active_row & is_bank_active & row_buffer
always_ff @(posedge clk) begin
	active_row[ba] <= (cmd == CMD_ACTIVE) ? a : active_row[ba];
end

always_ff @(posedge clk) begin
	case(cmd)
		CMD_ACTIVE:
			is_bank_active[ba] <= 1'b1;
		CMD_PRECHARGE, CMD_REFRESH:
			case(a[10])
				1'b1: begin
					is_bank_active[0] <= 1'b0;
					is_bank_active[1] <= 1'b0;
					is_bank_active[2] <= 1'b0;
					is_bank_active[3] <= 1'b0;
				end

				1'b0:
					is_bank_active[ba] <= 1'b0;
			endcase
		default: begin
			is_bank_active[0] <= is_bank_active[0];
			is_bank_active[1] <= is_bank_active[1];
			is_bank_active[2] <= is_bank_active[2];
			is_bank_active[3] <= is_bank_active[3];
		end
	endcase
end

always_ff @(posedge clk) begin
	row_buffer[ba] <= (cmd == CMD_ACTIVE) ? memory[ba][a] : row_buffer[ba];
end


// col_addr & cas_counter & burst_counter
always_ff @(posedge clk) begin
	col_addr <= (is_bank_active[ba] && cmd == CMD_READ) ? a[8:0] : (is_bank_active[ba] && cmd == CMD_WRITE) ? {a[8:1], 1'b1} : (cas_counter == 0 && burst_counter != 0) ? col_addr + 1 : col_addr;
end

always_ff @(posedge clk) begin
	cas_counter <= (cas_counter != 0) ? cas_counter - 1 : (is_bank_active[ba] && cmd == CMD_READ) ? cas_latency - 1 : 0;
end

always_ff @(posedge clk) begin
	burst_counter <= (burst_counter != 0) ? burst_counter - 1 : (is_bank_active[ba] && cmd == CMD_READ) ? num_burst : (is_bank_active[ba] && cmd == CMD_WRITE) ? num_burst - 1 : burst_counter;
end

reg reading, writing;

always_ff @(posedge clk) begin
	reading <= (cas_counter == 1 && burst_counter != 0 && !reading) ? 1'b1 : (burst_counter == 1 && reading || cmd == CMD_TERMINATE) ? 1'b0 : reading;
end

always_ff @(posedge clk) begin
	writing <= (cmd == CMD_WRITE && !writing) ? 1'b1 : (burst_counter == 1 && writing || cmd == CMD_TERMINATE) ? 1'b0 : writing;
end

// read
assign data_out = row_buffer[bank_addr][col_addr];
assign data_out_enable = reading;

// write
always_ff @(posedge clk) begin
	if (cmd == CMD_WRITE || writing) begin
		$display("cmd == %d, data = %d", cmd, dq);
		row_buffer[ba][col_addr][7 : 0] <= dqm[0] ? row_buffer[ba][col_addr][7 : 0] : dq[7:0];
		row_buffer[ba][col_addr][15 : 8] <= dqm[1] ? row_buffer[ba][col_addr][15 : 8] : dq[15:8];

		memory[ba][active_row[ba]][col_addr] <= {
			dqm[1] ? row_buffer[ba][col_addr][15:8] : dq[15:8],
          	dqm[0] ? row_buffer[ba][col_addr][7:0] : dq[7:0]
		};
	end
end



endmodule
