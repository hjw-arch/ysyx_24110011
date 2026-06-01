`ifdef NPC

module ysyx (
    input logic clock,
    input logic reset
);

logic        io_master_awready;
logic        io_master_awvalid;
logic [31:0] io_master_awaddr;
logic [3:0]  io_master_awid;
logic [7:0]  io_master_awlen;
logic [2:0]  io_master_awsize;
logic [1:0]  io_master_awburst;

logic        io_master_wready;
logic        io_master_wvalid;
logic [31:0] io_master_wdata;
logic [3:0]  io_master_wstrb;
logic        io_master_wlast;

logic        io_master_bready;
logic        io_master_bvalid;
logic [1:0]  io_master_bresp;
logic [3:0]  io_master_bid;

logic        io_master_arready;
logic        io_master_arvalid;
logic [31:0] io_master_araddr;
logic [3:0]  io_master_arid;
logic [7:0]  io_master_arlen;
logic [2:0]  io_master_arsize;
logic [1:0]  io_master_arburst;

logic        io_master_rready;
logic        io_master_rvalid;
logic [1:0]  io_master_rresp;
logic [31:0] io_master_rdata;
logic        io_master_rlast;
logic [3:0]  io_master_rid;

logic        io_slave_awready;
logic        io_slave_wready;
logic        io_slave_bvalid;
logic [1:0]  io_slave_bresp;
logic [3:0]  io_slave_bid;
logic        io_slave_arready;
logic        io_slave_rvalid;
logic [1:0]  io_slave_rresp;
logic [31:0] io_slave_rdata;
logic        io_slave_rlast;
logic [3:0]  io_slave_rid;

ysyx_24110011 u_cpu (
    .clock              (clock),
    .reset              (reset),
    .io_interrupt       (1'b0),

    .io_master_awready  (io_master_awready),
    .io_master_awvalid  (io_master_awvalid),
    .io_master_awaddr   (io_master_awaddr),
    .io_master_awid     (io_master_awid),
    .io_master_awlen    (io_master_awlen),
    .io_master_awsize   (io_master_awsize),
    .io_master_awburst  (io_master_awburst),
    .io_master_wready   (io_master_wready),
    .io_master_wvalid   (io_master_wvalid),
    .io_master_wdata    (io_master_wdata),
    .io_master_wstrb    (io_master_wstrb),
    .io_master_wlast    (io_master_wlast),
    .io_master_bready   (io_master_bready),
    .io_master_bvalid   (io_master_bvalid),
    .io_master_bresp    (io_master_bresp),
    .io_master_bid      (io_master_bid),
    .io_master_arready  (io_master_arready),
    .io_master_arvalid  (io_master_arvalid),
    .io_master_araddr   (io_master_araddr),
    .io_master_arid     (io_master_arid),
    .io_master_arlen    (io_master_arlen),
    .io_master_arsize   (io_master_arsize),
    .io_master_arburst  (io_master_arburst),
    .io_master_rready   (io_master_rready),
    .io_master_rvalid   (io_master_rvalid),
    .io_master_rresp    (io_master_rresp),
    .io_master_rdata    (io_master_rdata),
    .io_master_rlast    (io_master_rlast),
    .io_master_rid      (io_master_rid),

    .io_slave_awready   (io_slave_awready),
    .io_slave_awvalid   (1'b0),
    .io_slave_awaddr    (32'b0),
    .io_slave_awid      (4'b0),
    .io_slave_awlen     (8'b0),
    .io_slave_awsize    (3'b0),
    .io_slave_awburst   (2'b0),
    .io_slave_wready    (io_slave_wready),
    .io_slave_wvalid    (1'b0),
    .io_slave_wdata     (32'b0),
    .io_slave_wstrb     (4'b0),
    .io_slave_wlast     (1'b0),
    .io_slave_bready    (1'b1),
    .io_slave_bvalid    (io_slave_bvalid),
    .io_slave_bresp     (io_slave_bresp),
    .io_slave_bid       (io_slave_bid),
    .io_slave_arready   (io_slave_arready),
    .io_slave_arvalid   (1'b0),
    .io_slave_araddr    (32'b0),
    .io_slave_arid      (4'b0),
    .io_slave_arlen     (8'b0),
    .io_slave_arsize    (3'b0),
    .io_slave_arburst   (2'b0),
    .io_slave_rready    (1'b1),
    .io_slave_rvalid    (io_slave_rvalid),
    .io_slave_rresp     (io_slave_rresp),
    .io_slave_rdata     (io_slave_rdata),
    .io_slave_rlast     (io_slave_rlast),
    .io_slave_rid       (io_slave_rid)
);

npc_axi_ram u_ram (
    .clk     (clock),
    .rst     (reset),
    .ARID    (io_master_arid),
    .ARADDR  (io_master_araddr),
    .ARLEN   (io_master_arlen),
    .ARSIZE  (io_master_arsize),
    .ARBURST (io_master_arburst),
    .ARVALID (io_master_arvalid),
    .ARREADY (io_master_arready),
    .RID     (io_master_rid),
    .RDATA   (io_master_rdata),
    .RRESP   (io_master_rresp),
    .RLAST   (io_master_rlast),
    .RVALID  (io_master_rvalid),
    .RREADY  (io_master_rready),
    .AWID    (io_master_awid),
    .AWADDR  (io_master_awaddr),
    .AWLEN   (io_master_awlen),
    .AWSIZE  (io_master_awsize),
    .AWBURST (io_master_awburst),
    .AWVALID (io_master_awvalid),
    .AWREADY (io_master_awready),
    .WDATA   (io_master_wdata),
    .WSTRB   (io_master_wstrb),
    .WLAST   (io_master_wlast),
    .WVALID  (io_master_wvalid),
    .WREADY  (io_master_wready),
    .BID     (io_master_bid),
    .BRESP   (io_master_bresp),
    .BVALID  (io_master_bvalid),
    .BREADY  (io_master_bready)
);

endmodule

module npc_axi_ram (
    input  logic        clk,
    input  logic        rst,

    input  logic [3:0]  ARID,
    input  logic [31:0] ARADDR,
    input  logic [7:0]  ARLEN,
    input  logic [2:0]  ARSIZE,   /* verilator lint_off UNUSEDSIGNAL */
    input  logic [1:0]  ARBURST,  /* verilator lint_off UNUSEDSIGNAL */
    input  logic        ARVALID,
    output logic        ARREADY,

    output logic [3:0]  RID,
    output logic [31:0] RDATA,
    output logic [1:0]  RRESP,
    output logic        RLAST,
    output logic        RVALID,
    input  logic        RREADY,

    input  logic [3:0]  AWID,
    input  logic [31:0] AWADDR,
    input  logic [7:0]  AWLEN,    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [2:0]  AWSIZE,   /* verilator lint_off UNUSEDSIGNAL */
    input  logic [1:0]  AWBURST,  /* verilator lint_off UNUSEDSIGNAL */
    input  logic        AWVALID,
    output logic        AWREADY,

    input  logic [31:0] WDATA,
    input  logic [3:0]  WSTRB,
    input  logic        WLAST,    /* verilator lint_off UNUSEDSIGNAL */
    input  logic        WVALID,
    output logic        WREADY,

    output logic [3:0]  BID,
    output logic [1:0]  BRESP,
    output logic        BVALID,
    input  logic        BREADY
);

import "DPI-C" function int pmem_read(input int addr, input int len);
import "DPI-C" function void pmem_write(input int addr, input int data, input int len);

typedef enum logic {
    R_IDLE,
    R_DATA
} r_state_t;

r_state_t  r_state;
logic [31:0] raddr_r;
logic [7:0]  rlen_r;
logic [7:0]  rbeat_r;
logic [3:0]  rid_r;

assign ARREADY = (r_state == R_IDLE);
assign RVALID  = (r_state == R_DATA);
assign RLAST   = (rbeat_r == rlen_r);
assign RID     = rid_r;
assign RRESP   = 2'b00;
assign RDATA   = pmem_read(raddr_r, 32'hf);

wire ar_fire = ARVALID & ARREADY;
wire r_fire  = RVALID & RREADY;

always_ff @(posedge clk) begin
    if (rst) begin
        r_state <= R_IDLE;
        raddr_r <= 32'b0;
        rlen_r  <= 8'b0;
        rbeat_r <= 8'b0;
        rid_r   <= 4'b0;
    end else begin
        unique case (r_state)
            R_IDLE: begin
                if (ar_fire) begin
                    r_state <= R_DATA;
                    raddr_r <= ARADDR;
                    rlen_r  <= ARLEN;
                    rbeat_r <= 8'b0;
                    rid_r   <= ARID;
                end
            end
            R_DATA: begin
                if (r_fire) begin
                    if (RLAST) begin
                        r_state <= R_IDLE;
                    end else begin
                        raddr_r <= raddr_r + 32'd4;
                        rbeat_r <= rbeat_r + 8'd1;
                    end
                end
            end
            default: r_state <= R_IDLE;
        endcase
    end
end

logic        aw_seen_r;
logic [31:0] awaddr_r;
logic [3:0]  awid_r;
logic        w_seen_r;
logic [31:0] wdata_r;
logic [3:0]  wstrb_r;
logic [3:0]  bid_r;

assign AWREADY = ~aw_seen_r & ~BVALID;
assign WREADY  = ~w_seen_r  & ~BVALID;
assign BID     = bid_r;
assign BRESP   = 2'b00;

wire aw_fire = AWVALID & AWREADY;
wire w_fire  = WVALID  & WREADY;
wire b_fire  = BVALID  & BREADY;

wire        aw_ready_for_write = aw_seen_r | aw_fire;
wire        w_ready_for_write  = w_seen_r  | w_fire;
wire [31:0] write_addr         = aw_seen_r ? awaddr_r : AWADDR;
wire [3:0]  write_bid          = aw_seen_r ? awid_r   : AWID;
wire [31:0] write_data         = w_seen_r  ? wdata_r  : WDATA;
wire [3:0]  write_strb         = w_seen_r  ? wstrb_r  : WSTRB;
wire        write_fire         = ~BVALID & aw_ready_for_write & w_ready_for_write;

always_ff @(posedge clk) begin
    if (rst) begin
        aw_seen_r <= 1'b0;
        awaddr_r  <= 32'b0;
        awid_r    <= 4'b0;
        w_seen_r  <= 1'b0;
        wdata_r   <= 32'b0;
        wstrb_r   <= 4'b0;
        bid_r     <= 4'b0;
        BVALID    <= 1'b0;
    end else begin
        if (b_fire) begin
            BVALID <= 1'b0;
        end

        if (aw_fire & ~write_fire) begin
            aw_seen_r <= 1'b1;
            awaddr_r  <= AWADDR;
            awid_r    <= AWID;
        end

        if (w_fire & ~write_fire) begin
            w_seen_r <= 1'b1;
            wdata_r  <= WDATA;
            wstrb_r  <= WSTRB;
        end

        if (write_fire) begin
            pmem_write(write_addr, write_data, {28'b0, write_strb});
            aw_seen_r <= 1'b0;
            w_seen_r  <= 1'b0;
            bid_r     <= write_bid;
            BVALID    <= 1'b1;
        end
    end
end

endmodule

`endif
