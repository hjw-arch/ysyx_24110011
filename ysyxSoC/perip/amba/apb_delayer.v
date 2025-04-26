module apb_delayer(
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

  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

/************************************** 直连信号 ******************************/
assign out_paddr	=	in_paddr;
assign out_pprot	=	in_pprot;
assign out_pwrite	=	in_pwrite;
assign out_pwdata	=	in_pwdata;
assign out_pstrb	=	in_pstrb;

/************************************* 接管信号 ********************************/

wire delayer_pready, delayer_psel, delayer_penable;
reg [31:0] 	delayer_prdata;
reg			delayer_pslverr;


assign in_pready	=	delayer_pready;
assign out_psel		=	delayer_psel;
assign out_penable	=	delayer_penable;
assign in_prdata	=	delayer_prdata;
assign in_pslverr	=	delayer_pslverr;

/************************************** 状态定义 ******************************/
localparam 	IDLE	=	2'b00,
			SETUP	=	2'b01,
			ACCESS	=	2'b11,
			DELAY	=	2'b10;

reg [1:0] state;
logic [1:0] nstate;

reg [15:0] 	total_delay;
reg [8:0]	dynamic_cnt;


/************************************* 辅助信号 ********************************/
wire delay_finish		=	total_delay == 16'b0;
wire start_transmit		=	in_psel;
wire finish_transmit	=	out_pready;

assign delayer_pready	=	((state == DELAY) & delay_finish);
assign delayer_psel		=	in_psel && (state != DELAY);
assign delayer_penable	=	in_penable && (state != DELAY);

always_ff @(posedge clock) begin
	delayer_prdata <= finish_transmit ? out_prdata : delayer_prdata;
end

always_ff @(posedge clock) begin
	delayer_pslverr <= finish_transmit ? out_pslverr : delayer_pslverr;
end

/*********************************** 状态转换 ***********************************/
always_ff @(posedge clock) begin
	state <= reset ? IDLE : nstate;
end

always_comb begin
	case(state)
		IDLE:	nstate = in_psel ? SETUP : IDLE;
		SETUP:	nstate = in_penable & in_psel ? ACCESS : IDLE;
		ACCESS:	nstate = out_pready ? DELAY : ACCESS;
		DELAY:	nstate = delay_finish ? IDLE : DELAY;
	endcase
end

/******************************** 计数器 **********************************/
localparam SR		=		99;		// 6.2*16
localparam SHIFTER	=		4;

always_ff @(posedge clock) begin
	if (reset) begin
		dynamic_cnt <= 9'b1;		// 补偿，因为最后一次算不上
	end else begin
		if (state == DELAY && delay_finish) dynamic_cnt <= 9'b1;
		else if (state == IDLE && in_psel || state == SETUP || state == ACCESS)	dynamic_cnt <= dynamic_cnt + 1;
		else dynamic_cnt <= dynamic_cnt;
	end
end

always_ff @(posedge clock) begin
	if (reset) begin
		total_delay <= 16'b0;
	end else begin
		if (state == DELAY && delay_finish) begin
			total_delay <= 16'b0;
		end else if (state == DELAY && !delay_finish) begin
			total_delay <= total_delay - 1;
		end else if (state == ACCESS && finish_transmit) begin
			total_delay <= (total_delay >> SHIFTER) - {7'b0, dynamic_cnt};
		end else if (state == IDLE && start_transmit || state == SETUP || state == ACCESS && !finish_transmit) begin
			total_delay <= total_delay + SR;
		end else begin
			total_delay <= total_delay;
		end
	end
end

/************************************* 调试 ***************************************/
// === 增强的调试逻辑 ===

// reg current_transfer_is_write; // 记录当前活跃传输是否为写操作

// // 在传输开始时锁存是否为写操作
// always_ff @(posedge clock) begin
//   if (reset) begin
//     current_transfer_is_write <= 1'b0;
//   end else if (state == IDLE && nstate == SETUP) begin // 检测到新传输开始 (从 IDLE 进入 SETUP)
//     current_transfer_is_write <= in_pwrite;         // 锁存本次传输的写信号
//   end else if (nstate == IDLE && state != IDLE) begin // 传输结束，返回 IDLE
//     current_transfer_is_write <= 1'b0;         // 清除标志，为下次传输准备
//   // 注：如果需要处理 psel 提前撤销导致的中止，也应在此处或状态机中清除标志
//   end
//   // 在 SETUP, ACCESS, DELAY 状态保持不变
// end

// // 在写传输活跃期间打印调试信息
// always_ff @(posedge clock) begin
//   if (!reset && current_transfer_is_write && (state == SETUP || state == ACCESS || state == DELAY)) begin
//     string state_str;
//     case(state)
//       IDLE:   state_str = "IDLE  ";
//       SETUP:  state_str = "SETUP ";
//       ACCESS: state_str = "ACCESS";
//       DELAY:  state_str = "DELAY ";
//       default: state_str = "XXXX  ";
//     endcase

//     $display("[%t] WRITE DEBUG | State: %s(%b) | IN(M->D): psel=%b pen=%b pwrite=%b paddr=%h pwdata=%h pstrb=%b | OUT(D->S): psel=%b pen=%b pwrite=%b paddr=%h pwdata=%h pstrb=%b | SLV_RESP: pready=%b pslverr=%b | DELAY_LOGIC: total=%d dyn_cnt=%d fin=%b | OUT(D->M): pready=%b pslverr=%b",
//              $time,                       // 时间戳
//              state_str, state,            // 当前状态 (名称 + 二进制值)
//              in_psel, in_penable, in_pwrite, in_paddr, in_pwdata, in_pstrb, // Master 输入给 Delayer 的信号
//              out_psel, out_penable, out_pwrite, out_paddr, out_pwdata, out_pstrb, // Delayer 输出给 Slave 的信号
//              out_pready, out_pslverr,     // Slave 返回给 Delayer 的响应
//              total_delay, dynamic_cnt, delay_finish, // 内部延迟计算状态
//              in_pready, in_pslverr        // Delayer 输出给 Master 的最终响应
//             );
//   end
// end

reg temp;
always_ff @(posedge clock) begin
	if (in_psel & in_penable & in_pwrite) begin
		temp <= temp + 1;
	end else if(out_pready & in_pwrite) begin
		temp <= 0;
		$display("clcyes = %d", temp);
	end
end

// === 结束增强的调试逻辑 ===


endmodule
