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


// ------------------------------------------------------------
// -- Calibrating memory access latency (c = r * s * k)
// ------------------------------------------------------------
// yosys-sta core timing report: 507.418MHz
//    with device clk frequency: 100MHz
// 
// got r = core_clk_freq / device_clk_freq = 5,
// and let's assume s = 2
// ------------------------------------------------------------

  localparam r = 5;
  localparam s = 2;
  localparam inc = r * s;

  localparam S_IDLE = 3'd0, S_TRANS = 3'd1, S_WAIT = 3'd2;
  localparam S_BURST_0 = 3'd3, S_BURST_1 = 3'd4, S_BURST_2 = 3'd5, S_BURST_3 = 3'd6; 
  reg [ 2: 0] r_state;
  reg [ 2: 0] burst_state;
  reg [ 2: 0] w_state;

  reg [31: 0] r_counters;
  reg [31: 0] r_quant_counters;
  reg [31: 0] r_cnt_burst_0;
  reg [31: 0] r_cnt_burst_1;
  reg [31: 0] r_cnt_burst_2;
  reg [31: 0] r_cnt_burst_3;

  reg [31: 0] w_counters;
  reg [31: 0] w_quant_counters;

  reg         rvalid_beat_0_q;
  reg [ 3: 0] rid_beat_0_q;
  reg [31: 0] rdata_beat_0_q;
  reg [ 1: 0] rresp_beat_0_q;
  reg         rlast_beat_0_q;

  reg         rvalid_beat_1_q;
  reg [ 3: 0] rid_beat_1_q;
  reg [31: 0] rdata_beat_1_q;
  reg [ 1: 0] rresp_beat_1_q;
  reg         rlast_beat_1_q;

  reg         rvalid_beat_2_q;
  reg [ 3: 0] rid_beat_2_q;
  reg [31: 0] rdata_beat_2_q;
  reg [ 1: 0] rresp_beat_2_q;
  reg         rlast_beat_2_q;

  reg         rvalid_beat_3_q;
  reg [ 3: 0] rid_beat_3_q;
  reg [31: 0] rdata_beat_3_q;
  reg [ 1: 0] rresp_beat_3_q;
  reg         rlast_beat_3_q;

  reg         bvalid_q;
  reg [ 3: 0] bid_q;
  reg [ 1: 0] bresp_q;


  wire        r_hs = out_rvalid & out_rready;
  wire        b_hs = out_bvalid & out_bready;

// read fsm //////////////////////////////////////////////////////////////////////////////////////

  always @ (posedge clock) begin
    if (reset)
      r_state <= S_IDLE;
    else begin
      case (r_state)
        S_IDLE    : r_state <= in_arvalid            ? 
                    (in_arlen == 8'd3                ? S_BURST_0 : S_BURST_3) : S_IDLE;
        S_BURST_0 : r_state <= r_hs                  ? S_BURST_1 : S_BURST_0;
        S_BURST_1 : r_state <= r_hs                  ? S_BURST_2 : S_BURST_1;
        S_BURST_2 : r_state <= r_hs                  ? S_BURST_3 : S_BURST_2;
        S_BURST_3 : r_state <= r_hs & out_rlast      ? S_WAIT    : S_BURST_3;        
        S_WAIT    : r_state <= r_cnt_burst_3 == 0    ? (in_arvalid ? S_BURST_0 : S_IDLE) : S_WAIT;
        default   : r_state <= r_state;
      endcase
    end 
  end

  always @ (posedge clock) begin
    if (reset)
      burst_state <= S_IDLE;
    else begin
      case (burst_state)
        S_IDLE    : burst_state <= r_hs               ? 
                    (in_arlen == 8'd3                 ? S_BURST_0 : S_BURST_3) : S_IDLE;
        S_BURST_0 : burst_state <= r_cnt_burst_0 == 0 ? S_BURST_1 : S_BURST_0;
        S_BURST_1 : burst_state <= r_cnt_burst_1 == 0 ? S_BURST_2 : S_BURST_1;
        S_BURST_2 : burst_state <= r_cnt_burst_2 == 0 ? S_BURST_3 : S_BURST_2;
        S_BURST_3 : burst_state <= r_cnt_burst_3 == 0 ? S_IDLE    : S_BURST_3;
        default   : burst_state <= S_IDLE;   
      endcase
    end
  end

// read quant counters //////////////////////////////////////////////////////////////////////////

  wire r_transfer = r_state == S_BURST_0 | r_state == S_BURST_1 | 
                  r_state == S_BURST_2 | r_state == S_BURST_3 ;
  wire r_waiting  = r_state == S_WAIT;

  always @ (posedge clock) begin
    if (reset)
      r_quant_counters <= 32'd0;
    else if (r_transfer)
      r_quant_counters <= r_quant_counters + inc;
    else if (r_waiting)
      r_quant_counters <= 32'd0;
  end

  always @ (posedge clock) begin
    if (reset)
      r_counters <= 32'd0;
    else if (r_transfer)
      r_counters <= r_counters + 1;
    else if (r_counters == 0)
      r_counters <= 32'd0;
    else if (r_waiting)
      r_counters <= 32'd0;
  end

// read burst counters //////////////////////////////////////////////////////////////////////////

  wire idle    = (r_state == S_IDLE   );
  wire burst_0 = (r_state == S_BURST_0);
  wire burst_1 = (r_state == S_BURST_1);
  wire burst_2 = (r_state == S_BURST_2);
  wire burst_3 = (r_state == S_BURST_3);

  always @ (posedge clock) begin
    if (reset)
      r_cnt_burst_0 <= 32'd0;
    else if (burst_0 & r_hs)
      r_cnt_burst_0 <= ((r_quant_counters + inc) >> $clog2(s)) - r_counters -2;
    else if (r_cnt_burst_0 == 0)
      r_cnt_burst_0 <= 32'd0;
    else 
      r_cnt_burst_0 <= r_cnt_burst_0 - 1;
  end

  always @ (posedge clock) begin
    if (reset)
      r_cnt_burst_1 <= 32'd0;
    else if (burst_1 & r_hs)
      r_cnt_burst_1 <= ((r_quant_counters + inc) >> $clog2(s)) - r_counters - 2;
    else if (r_cnt_burst_1 == 0)
      r_cnt_burst_1 <= 32'd0;
    else 
      r_cnt_burst_1 <= r_cnt_burst_1 - 1;
  end

  always @ (posedge clock) begin
    if (reset)
      r_cnt_burst_2 <= 32'd0;
    else if (burst_2 & r_hs)
      r_cnt_burst_2 <= ((r_quant_counters + inc) >> $clog2(s)) - r_counters - 2;
    else if (r_cnt_burst_2 == 0)
      r_cnt_burst_2 <= 32'd0;
    else 
      r_cnt_burst_2 <= r_cnt_burst_2 - 1;
  end

  always @ (posedge clock) begin
    if (reset)
      r_cnt_burst_3 <= 32'd0;
    else if (burst_3 & r_hs & out_rlast)
      r_cnt_burst_3 <= ((r_quant_counters + inc) >> $clog2(s)) - r_counters - 2;
    else if (r_cnt_burst_3 == 0)
      r_cnt_burst_3 <= 32'd0;
    else 
      r_cnt_burst_3 <= r_cnt_burst_3 - 1;
  end

// read burst registers //////////////////////////////////////////////////////////////////////////
  
  always @ (posedge clock) begin
    if (reset) begin
      rvalid_beat_0_q <= 0;   
      rid_beat_0_q    <= 0;   
      rdata_beat_0_q  <= 0; 
      rresp_beat_0_q  <= 0; 
      rlast_beat_0_q  <= 0; 
    end else if (r_hs & burst_0) begin
      rvalid_beat_0_q <= out_rvalid;  
      rid_beat_0_q    <= out_rid;
      rdata_beat_0_q  <= out_rdata;
      rresp_beat_0_q  <= out_rresp;
      rlast_beat_0_q  <= out_rlast;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      rvalid_beat_1_q <= 0;   
      rid_beat_1_q    <= 0;   
      rdata_beat_1_q  <= 0; 
      rresp_beat_1_q  <= 0; 
      rlast_beat_1_q  <= 0; 
    end else if (r_hs & burst_1) begin 
      rvalid_beat_1_q <= out_rvalid;  
      rid_beat_1_q    <= out_rid;
      rdata_beat_1_q  <= out_rdata;
      rresp_beat_1_q  <= out_rresp;
      rlast_beat_1_q  <= out_rlast;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      rvalid_beat_2_q <= 0;   
      rid_beat_2_q    <= 0;   
      rdata_beat_2_q  <= 0; 
      rresp_beat_2_q  <= 0; 
      rlast_beat_2_q  <= 0; 
    end else if (r_hs & burst_2) begin 
      rvalid_beat_2_q <= out_rvalid;  
      rid_beat_2_q    <= out_rid;
      rdata_beat_2_q  <= out_rdata;
      rresp_beat_2_q  <= out_rresp;
      rlast_beat_2_q  <= out_rlast;
    end
  end

  always @ (posedge clock) begin
    if (reset) begin
      rvalid_beat_3_q <= 0;   
      rid_beat_3_q    <= 0;   
      rdata_beat_3_q  <= 0; 
      rresp_beat_3_q  <= 0; 
      rlast_beat_3_q  <= 0; 
    end else if (r_hs & out_rlast & burst_3) begin 
      rvalid_beat_3_q <= out_rvalid;  
      rid_beat_3_q    <= out_rid;
      rdata_beat_3_q  <= out_rdata;
      rresp_beat_3_q  <= out_rresp;
      rlast_beat_3_q  <= out_rlast;
    end
  end

// write fsm /////////////////////////////////////////////////////////////////////////////////////

  always @ (posedge clock) begin
    if (reset)
      w_state <= S_IDLE;
    else begin
      case (w_state)
        S_IDLE  : w_state <= in_awvalid            ? S_TRANS : S_IDLE;
        S_TRANS : w_state <= b_hs                  ? S_WAIT  : S_TRANS;
        S_WAIT  : w_state <= w_quant_counters == 0 ? (in_awvalid ? S_TRANS : S_IDLE) : S_WAIT;
        default : w_state <= w_state;
      endcase
    end
  end

  // write quant counters //////////////////////////////////////////////////////////////////////////

  wire w_transfer = w_state == S_TRANS;
  wire w_transfer2waiting = b_hs & w_transfer;
  wire w_waiting  = w_state == S_WAIT;

  always @ (posedge clock) begin
    if (reset)
      w_quant_counters <= 32'd0;
    else if (w_transfer2waiting)
      w_quant_counters <= ((w_quant_counters + inc) >> $clog2(s)) - 1;
    else if (w_transfer)
      w_quant_counters <= w_quant_counters + inc;
    else if (w_quant_counters == 0)
      w_quant_counters <= 32'd0;
    else if (w_waiting)
      w_quant_counters <= w_quant_counters - 1;
  end

  always @ (posedge clock) begin
    if (reset)
      w_counters <= 32'd0;
    else if (w_transfer)
      w_counters <= w_counters + 1;
    else if (w_counters == 0)
      w_counters <= 32'd0;
    else if (w_waiting)
      w_counters <= 32'd0;
  end

  always @ (posedge clock) begin
    if (reset) begin
      bvalid_q <= 0;
      bid_q    <= 0;
      bresp_q  <= 0;
    end else if (w_transfer & b_hs) begin
      bvalid_q <= out_bvalid;
      bid_q    <= out_bid;
      bresp_q  <= out_bresp;
    end
  end

  assign in_arready = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid = in_arid;
  assign out_araddr = in_araddr;
  assign out_arlen = in_arlen;
  assign out_arsize = in_arsize;
  assign out_arburst = in_arburst;
  assign out_rready = in_rready;
  assign in_rvalid = burst_state == S_BURST_3 & r_cnt_burst_3 == 0 ? rvalid_beat_3_q :
                     burst_state == S_BURST_2 & r_cnt_burst_2 == 0 ? rvalid_beat_2_q :
                     burst_state == S_BURST_1 & r_cnt_burst_1 == 0 ? rvalid_beat_1_q :
                     burst_state == S_BURST_0 & r_cnt_burst_0 == 0 ? rvalid_beat_0_q : 0;
  assign in_rid = burst_state == S_BURST_3 & r_cnt_burst_3 == 0 ? rid_beat_3_q :
                  burst_state == S_BURST_2 & r_cnt_burst_2 == 0 ? rid_beat_2_q :
                  burst_state == S_BURST_1 & r_cnt_burst_1 == 0 ? rid_beat_1_q :
                  burst_state == S_BURST_0 & r_cnt_burst_0 == 0 ? rid_beat_0_q : 0;
  assign in_rdata = burst_state == S_BURST_3 & r_cnt_burst_3 == 0 ? rdata_beat_3_q :
                    burst_state == S_BURST_2 & r_cnt_burst_2 == 0 ? rdata_beat_2_q :
                    burst_state == S_BURST_1 & r_cnt_burst_1 == 0 ? rdata_beat_1_q :
                    burst_state == S_BURST_0 & r_cnt_burst_0 == 0 ? rdata_beat_0_q : 0;
  assign in_rresp = burst_state == S_BURST_3 & r_cnt_burst_3 == 0 ? rresp_beat_3_q :
                    burst_state == S_BURST_2 & r_cnt_burst_2 == 0 ? rresp_beat_2_q :
                    burst_state == S_BURST_1 & r_cnt_burst_1 == 0 ? rresp_beat_1_q :
                    burst_state == S_BURST_0 & r_cnt_burst_0 == 0 ? rresp_beat_0_q : 0;
  assign in_rlast = burst_state == S_BURST_3 & r_cnt_burst_3 == 0 ? rlast_beat_3_q :
                    burst_state == S_BURST_2 & r_cnt_burst_2 == 0 ? rlast_beat_2_q :
                    burst_state == S_BURST_1 & r_cnt_burst_1 == 0 ? rlast_beat_1_q :
                    burst_state == S_BURST_0 & r_cnt_burst_0 == 0 ? rlast_beat_0_q : 0;
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
  assign out_bready = in_bready;
  assign in_bvalid = (w_quant_counters == 0 & w_waiting) ? bvalid_q : 0;
  assign in_bid = (w_quant_counters == 0 & w_waiting) ? bid_q : 0;
  assign in_bresp = (w_quant_counters == 0 & w_waiting) ? bresp_q : 0;

endmodule