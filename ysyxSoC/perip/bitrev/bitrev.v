module bitrev (
  	input  sck,
  	input  ss,
  	input  mosi,
  	output miso
);

localparam RECEIVE 	= 1'b0;
localparam SEND		= 1'b1; 

reg state;

reg [7 : 0] data;
reg [2 : 0] counter;

// 状态转移
always @(posedge sck or posedge ss) begin
	case(state)
		RECEIVE: state <= !ss & (&counter) ? SEND : RECEIVE;
		SEND   : state <= !ss & (&counter) ? RECEIVE : SEND;
	endcase
end

// 计数器
always @(posedge sck or posedge ss) begin
	counter <= !ss ? counter + 1 : 3'b0;	// 八位数据，刚好再加一次得0
end

// 接收数据 + 发送数据，一直位移即可
always @(posedge sck or posedge ss) begin
	case (state)
		RECEIVE: data <= !ss ? {data[6 : 0], mosi} : 8'b0;
		SEND   : data <= !ss ? {1'b0, data[7 : 1]} : 8'b0;
	endcase
end

always @(posedge sck) begin
	if (!ss && counter == 3'b0) $display("data = 0x%2x", data);
end

// 发送数据
assign miso = !ss & (state == SEND) ? data[0] : 1'b1;


endmodule


