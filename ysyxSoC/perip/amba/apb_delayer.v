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

assign out_paddr   = in_paddr;
assign out_psel    = in_psel;
// assign out_penable = hold_penable;
assign out_penable = in_penable;
assign out_pprot   = in_pprot;
assign out_pwrite  = in_pwrite;
assign out_pwdata  = in_pwdata;
assign out_pstrb   = in_pstrb;
// assign in_pready   = (state == WAITING && finish_wait_cnt);
// assign in_prdata   = hold_prdata;
// assign in_pslverr  = hold_pslverr;
assign in_pready   = out_pready;
assign in_prdata   = out_prdata;
assign in_pslverr  = out_pslverr;

// localparam R_S			= 115;
// localparam S_SHIFTER	= 4;

// localparam IDLE			= 2'b00;
// localparam COUNTING		= 2'b01;
// localparam WAITING		= 2'b11;

// logic [1:0]  	state, next_state;
// logic [15:0] 	counter;
// logic [8:0] 	hold_timer;
// logic [31:0] 	hold_prdata;
// logic 		 	hold_pslverr;
// logic			hold_penable;

// assign hold_penable = (in_penable && state != WAITING);

// wire finish_wait_cnt 	= 	counter == {7'b0, hold_timer};
// wire start_transmit		= 	in_psel && in_penable;
// wire finish_transmit	=	out_pready;

// /****************************************** 状态机以及状态转移 ***************************************/
// always_ff @(posedge clock) begin
// 	state <= reset ? IDLE : next_state;
// end

// always_comb begin
// 	case(state) 
// 		IDLE: next_state = (start_transmit && !finish_transmit) ? COUNTING : (start_transmit && finish_transmit) ? WAITING : IDLE;
// 		COUNTING: next_state = finish_transmit ? WAITING : COUNTING;
// 		WAITING: next_state = finish_wait_cnt ? IDLE : WAITING;
// 		default: next_state = IDLE;
// 	endcase
// end

// /********************************************** 计数器 **************************************************/

// always_ff @(posedge clock) begin
// 	if (reset) hold_timer <= 9'b0;
// 	else begin
// 		if (state == IDLE && start_transmit || state == COUNTING) hold_timer <= hold_timer + 1;
// 		else if (state == WAITING && finish_wait_cnt) hold_timer <= 9'b0;
// 		else hold_timer <= hold_timer;
// 	end
// end

// always_ff @(posedge clock) begin
// 	if (reset) counter <= 16'b0;
// 	else begin
// 		if (state == IDLE && start_transmit && finish_transmit) counter <= 16'd7;
// 		else if ((state == IDLE) && start_transmit && ~finish_transmit || (state == COUNTING) && ~finish_transmit) counter <= counter + R_S;
// 		else if ((state == COUNTING) && finish_transmit) counter <= counter >> S_SHIFTER;
// 		else if ((state == WAITING) && !finish_wait_cnt) counter <= counter - 1;
// 		else if ((state == WAITING) && finish_wait_cnt) counter <= 16'b0;
// 		else counter <= counter;
// 	end
// end

// always_ff @(posedge clock) begin
// 	hold_prdata <= finish_transmit ? out_prdata : hold_prdata;
// end

// always_ff @(posedge clock) begin
// 	hold_pslverr <= finish_transmit ? out_pslverr : hold_pslverr;
// end

// always_ff @(posedge clock) begin
// 	if(state != IDLE) $display("state = %d, counter = %d, hold timer = %d", state, counter, hold_timer);
// end

endmodule
