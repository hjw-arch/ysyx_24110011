module axi4_delayer(
  input         clock,
  input         reset,

  output        in_arready,
  input         in_arvalid,
  input  [3:0]  in_arid,
  input  [31:0] in_araddr,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [3:0]  in_rid,
  output [31:0] in_rdata,
  output [1:0]  in_rresp,
  output        in_rlast,
  output        in_awready,
  input         in_awvalid,
  input  [3:0]  in_awid,
  input  [31:0] in_awaddr,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
                in_bready,
  output        in_bvalid,
  output [3:0]  in_bid,
  output [1:0]  in_bresp,

  input         out_arready,
  output        out_arvalid,
  output [3:0]  out_arid,
  output [31:0] out_araddr,
  output [7:0]  out_arlen,
  output [2:0]  out_arsize,
  output [1:0]  out_arburst,
  output        out_rready,
  input         out_rvalid,
  input  [3:0]  out_rid,
  input  [31:0] out_rdata,
  input  [1:0]  out_rresp,
  input         out_rlast,
  input         out_awready,
  output        out_awvalid,
  output [3:0]  out_awid,
  output [31:0] out_awaddr,
  output [7:0]  out_awlen,
  output [2:0]  out_awsize,
  output [1:0]  out_awburst,
  input         out_wready,
  output        out_wvalid,
  output [31:0] out_wdata,
  output [3:0]  out_wstrb,
  output        out_wlast,
                out_bready,
  input         out_bvalid,
  input  [3:0]  out_bid,
  input  [1:0]  out_bresp
);

  assign in_arready = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid = in_arid;
  assign out_araddr = in_araddr;
  assign out_arlen = in_arlen;
  assign out_arsize = in_arsize;
  assign out_arburst = in_arburst;
  assign in_rid = out_rid;
  assign in_rdata = out_rdata;
  assign in_rresp = out_rresp;
  assign in_rlast = out_rlast;
  assign in_awready = out_awready;
  assign out_awvalid = in_awvalid;
  assign out_awid = in_awid;
  assign out_awaddr = in_awaddr;
  assign out_awlen = in_awlen;
  assign out_awsize = in_awsize;
  assign out_awburst = in_awburst;
  assign in_wready = out_wready;
  assign out_wvalid = in_wvalid;
  assign out_wdata = in_wdata;
  assign out_wstrb = in_wstrb;
  assign out_wlast = in_wlast;
  assign in_bid = out_bid;
  assign in_bresp = out_bresp;



/*****************************************************************************/
// 常量定义
localparam SR        =        99;     // 6.2*16
localparam SHIFTER   =        4;

localparam  IDLE     = 2'b00,
            RUNNING  = 2'b01,
            DELAYING = 2'b11;

// 信号定义            
/*****************************************************************************/
// 读通道延迟逻辑 (AR & R channels)
/*****************************************************************************/

// 读通道状态和计数器
logic [1:0] r_state, r_state_last, n_r_state;
logic arvalid_last;
logic [7:0] r_counter;           // 读请求计数器
logic [19:0] r_delay_counter;    // 读累积延迟计数器

// 读通道状态转换检测
logic read_state_changing_to_delay;

// 握手成功标志
logic new_handshake;

// 边沿检测
always_ff @(posedge clock) begin
    arvalid_last <= in_arvalid;
    r_state_last <= r_state;
	new_handshake <= (in_rvalid & out_rready & ~in_rlast);
end

wire read_start = ~arvalid_last & in_arvalid;

// 读通道状态转换检测
assign read_state_changing_to_delay = (r_state_last == RUNNING) && (r_state == DELAYING);

// 读通道状态机逻辑
always_ff @(posedge clock) begin
    if (reset) begin
        r_state <= IDLE;
    end else begin
        r_state <= n_r_state;
    end
end

// 读通道下一状态逻辑
always_comb begin
    n_r_state = r_state;

    case (r_state)
        IDLE: begin
            if (read_start | (in_rvalid & out_rready & ~in_rlast)) n_r_state = RUNNING;
        end
        RUNNING: begin
            if (out_rvalid) n_r_state = DELAYING;
        end
        DELAYING: begin // 0时要握手成功，1时就得交互，再补偿开始时少减的1，就是2
            if (r_delay_counter == 2) n_r_state = IDLE;
        end
        default: n_r_state = IDLE;
    endcase
end

// 读通道计数器和延迟计算逻辑
always_ff @(posedge clock) begin
    if (reset) begin
        r_counter <= 0;
        r_delay_counter <= 0;
    end else begin
        if (read_start | new_handshake) begin
            // 读请求开始
            r_counter <= 1;
            r_delay_counter <= SR;
        end else if (r_state == RUNNING) begin
            // 累积延迟
            r_counter <= r_counter + 1;
            r_delay_counter <= r_delay_counter + SR;
        end
        
        // 状态转换时计算延迟周期数
        if (read_state_changing_to_delay) begin
            r_delay_counter <= (r_delay_counter >> SHIFTER) - {12'b0, r_counter};
        end else if (r_state == DELAYING && r_delay_counter > 0) begin
            // 在DELAYING状态下简单递减
            r_delay_counter <= r_delay_counter - 1;
        end
    end
end

// 延迟读控制逻辑
logic delay_rok;

// 延迟读控制（现在使用r_remaining_delay来决定何时结束延迟）
always_ff @(posedge clock) begin
    if (reset) begin
        delay_rok <= 1'b0;
    end else begin
        if (r_state == DELAYING && r_delay_counter == 2) begin
            // 当延迟即将结束时，开始传输有效信号
            delay_rok <= 1'b1;
        end else if (in_rvalid && out_rready) begin
            // 传输完成后清除
            delay_rok <= 1'b0;
        end
    end
end

// 读通道代理逻辑
assign out_rready = delay_rok & in_rready;
assign in_rvalid = delay_rok & out_rvalid;



/*****************************************************************************/
// 写通道延迟逻辑 (AW, W & B channels)
/*****************************************************************************/

// 写通道状态和计数器
logic [1:0] w_state, w_state_last, n_w_state;
logic awvalid_last, wvalid_last;
logic [7:0] w_counter;
logic [19:0] w_delay_counter;

// 写通道状态转换检测
logic write_state_changing_to_delay;

// 写通道边沿检测
always_ff @(posedge clock) begin
    awvalid_last <= in_awvalid;
    wvalid_last <= in_wvalid;
    w_state_last <= w_state;
end

wire write_start = ~awvalid_last & in_awvalid | ~wvalid_last & in_wvalid;

// 写通道状态转换检测
assign write_state_changing_to_delay = (w_state_last == RUNNING) && (w_state == DELAYING);

// 写通道状态机逻辑
always_ff @(posedge clock) begin
    if (reset) begin
        w_state <= IDLE;
    end else begin
        w_state <= n_w_state;
    end
end

// 写通道下一状态逻辑
always_comb begin
    n_w_state = w_state;
    
    case (w_state)
        IDLE: begin
            if (write_start) n_w_state = RUNNING;
        end
        RUNNING: begin
            if (out_bvalid) n_w_state = DELAYING; // 写数据完成时进入延迟状态
        end
        DELAYING: begin
            if (w_delay_counter == 2) n_w_state = IDLE;
        end
        default: n_w_state = IDLE;
    endcase
end

// 写通道计数器和延迟计算逻辑
always_ff @(posedge clock) begin
    if (reset) begin
        w_counter <= 0;
        w_delay_counter <= 0;
    end else begin
        if (write_start) begin
            // 写请求开始
            w_counter <= 1;
            w_delay_counter <= SR;
        end else if (w_state == RUNNING) begin
            // 累积延迟
            w_counter <= w_counter + 1;
            w_delay_counter <= w_delay_counter + SR;
        end
        
        // 状态转换时计算延迟周期数
        if (write_state_changing_to_delay) begin
            w_delay_counter <= (w_delay_counter >> SHIFTER) - {12'b0, w_counter};
        end else if (w_state == DELAYING && w_delay_counter > 0) begin
            // 在DELAYING状态下简单递减
            w_delay_counter <= w_delay_counter - 1;
        end
    end
end

// 延迟写控制逻辑
logic delay_wok;

// 写响应通道控制
always_ff @(posedge clock) begin
    if (reset) begin
        delay_wok <= 1'b0;
    end else begin
        if (w_state == DELAYING && w_delay_counter == 2) begin
            // 当延迟即将结束时，传递B通道响应
            delay_wok <= 1'b1;
        end else if (in_bvalid && out_bready) begin
            // 响应被接收后清除
            delay_wok <= 1'b0;
        end
    end
end

// 写通道代理连接

assign in_bvalid = delay_wok & out_bvalid;
assign out_bready = delay_wok & in_bready;

endmodule

