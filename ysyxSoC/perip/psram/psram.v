module psram(
      input sck,
      input ce_n,
      inout [3:0] dio
);

// 命令定义
localparam CMD_Q_READ	=     8'hEB;
localparam CMD_Q_WRITE	=    8'h38;

localparam S_CMD    = 1;
localparam S_ADDR   = 2;
localparam S_DUMMY  = 3;
localparam S_READ   = 4;
localparam S_WRITE 	= 5;

// localparam ADDR_BITS  = 24;
reg [7 : 0] PSRAM[0 : (1 << 22) - 1];

logic [2 : 0] state, next_state;
reg [2 : 0] cnt;
reg [7 : 0] cmd;
reg [23 : 0] addr;

reg dio_oe;        // dio输出使能信号
reg [3:0] dio_out;
wire [3:0] dio_in;

assign dio = dio_oe ? dio_out : 4'bz;
assign dio_in = dio;

// 状态转移
always_ff @(posedge sck or posedge ce_n) begin
    state <= ce_n ? S_CMD : next_state;
end

always_comb begin
    case(state) 
        S_CMD:
            next_state = cnt == 3'b111 ? S_ADDR : state;
        S_ADDR:
            next_state = cnt == 3'b101 && cmd == CMD_Q_READ ? S_DUMMY : cnt == 3'd5 && cmd == CMD_Q_WRITE ? S_WRITE : state;
        S_DUMMY:
            next_state = cnt == 3'b101 ? S_READ : state;
        S_READ:
            next_state = state;
        S_WRITE:
            next_state = state;
        default: next_state = state;
    endcase
end

// cnt
always_ff @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
        cnt <= 0;
    end else begin
        case(state)
            S_CMD:		cnt <= (cnt == 3'b111 | ce_n) ? 3'b0 : cnt + 1;
            S_ADDR:    	cnt <= cnt == 3'b101 ? 3'b0 : cnt + 1;
            S_DUMMY: 	cnt <= cnt == 3'b101 ? 3'b0 : cnt + 1;
            default: 	cnt <= 0;
        endcase
    end
end

// cmd
always_ff @(posedge sck) begin
    cmd <= (state == S_CMD & !ce_n) ? {cmd[6 : 0], dio_in[0]} : cmd;
end

// addr
always_ff @(posedge sck) begin
    if (state == S_ADDR) begin
        addr <= {addr[19 : 0], dio_in};
    end else if (state == S_READ && data_toggle || state == S_WRITE && ~data_toggle) begin
        addr <= addr + 1;
    end else begin
        addr <= addr;
    end
end

// read & write
assign dio_oe = state == S_READ;
reg [3 : 0] write_buf;    // 用于暂存写数据
reg [7 : 0] read_buf;   // 暂存读数据
reg data_toggle;

always_ff @(posedge sck) begin
    data_toggle <= cnt == 3'b101 ? 1'b1 : (state == S_READ || state == S_WRITE) ? ~data_toggle : 1'b0;
end

// read
// 功能仿真
always_ff @(posedge sck) begin
    if ((state == S_DUMMY && cnt == 3'b101) || (state == S_READ && ~data_toggle)) begin
        read_buf <= PSRAM[addr[21:0]];
    end else begin
        read_buf <= read_buf;
    end
end

// assign dio_out = data_toggle ? read_buf[7 : 4] : read_buf[3 : 0];

always_ff @(posedge sck) begin
	if (state == S_READ && data_toggle) dio_out <= read_buf[7:4];
	else if (state == S_READ && ~data_toggle) dio_out <= read_buf[3:0];
end

always_ff @(posedge sck) begin
	if (state == S_READ) begin
		$display("dio_out = %x， data_toggle is %d\n\n", dio_out, data_toggle);
	end
end

// write
// 功能仿真
always_ff @(posedge sck) begin
    if (state == S_WRITE) begin
        if (data_toggle) begin
            write_buf <= dio_in;
        end else begin
            PSRAM[addr[21:0]] <= {write_buf, dio_in};
        end
    end
end

// always_ff @(posedge sck) begin
// 	if (state == S_WRITE) begin
// 		$display("PSRAM ADDR is 0x%08x, DATA is %02x", addr, {write_buf, dio_in});
// 	end
// end

// always_ff @(posedge sck) begin
// 	if (state == S_READ) begin
// 		$display("PSRAM ADDR is 0x%08x, DATA is %02x", addr, PSRAM[addr[21 : 0]]);
// 	end
// end

// always_ff @(posedge sck) begin
// 	$display("state = %d", state);
// end

// always_ff @(posedge sck) begin
// 	$display("cmd = %x, cnt = %d", cmd, cnt);
// end

// always_ff @(posedge sck) begin
// 	if (state == S_READ) begin
// 		for (int i = 0; i < 16; i++) begin
// 			$display("PSRAM[%d] is %d", i, PSRAM[i]);
// 		end
// 	end
// end


endmodule
