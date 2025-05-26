module IFU #(parameter WIDTH = 32) (
    input clk,
    input rst,
    input wbu_valid,
    input [WIDTH - 1 : 0] pc,

    output ifu_valid,
    output reg [63 : 0] ifu_data,
    input idu_ready,

    // 连接SRAM
    // output declaration of module axi4_lite_master
    output prerequest,      // 仅仅适用于多周期处理器
    output [31:0] ARADDR,
    output ARVALID,
    output RREADY,
    output [3 : 0] ARID,
    output [7 : 0] ARLEN,
    output [2 : 0] ARSIZE,
    output [1 : 0] ARBURST,

    // input declaration of slave
    input ARREADY,
    input RVALID,
    input RLAST,
    input [3 : 0] RID,
    input [31 : 0] RDATA,
    input [1 : 0] RRESP
);

typedef enum logic { 
    S_IDLE,
    S_WAIT_READY
} ifu_state_t;

ifu_state_t state, next_state;

always_ff @(posedge clk) begin
    state <= rst ? S_IDLE : next_state;
end

always_comb begin
    case(state)
        S_IDLE:
            next_state = (ifu_valid && !idu_ready) ? S_WAIT_READY : S_IDLE;
        S_WAIT_READY:
            next_state = (idu_ready) ? S_IDLE : S_WAIT_READY;
        default:
            next_state = state;
    endcase
end

reg start;
always_ff @(posedge clk) begin
    start <= wbu_valid | rst ? 1'b1 : 1'b0;
end

// `ifdef SOC

assign ifu_valid = i2c_valid | (state == S_WAIT_READY);


always_ff @(posedge clk) begin
    ifu_data <= (ifu_valid & idu_ready) ? {i2c_data, pc} : ifu_data;
end

assign prerequest = 1'b0;	// 需要修改，暂时为了cache妥协

// output declaration of module axi4_full_master
wire [31:0] rdata;  /* verilator lint_off UNUSEDSIGNAL */
wire rdata_valid;
wire [1:0] rresp;
wire done;

// output declaration of module icache
wire i2c_ready;
wire i2c_valid;
wire [31:0] i2c_data;
wire i2m_valid;
wire [31:0] i2m_addr;
wire i2m_ready;


// 流水线时，icache要大改
_icache #(
	.BLOCK_SIZE 	(16   ),
	.BLOCK_NUM  	(16  ),
	.ADDR_WIDTH 	(32  ),
	.DATA_WIDTH 	(32  ))
u_icache(
	.clk       	(clk        ),
	.rst       	(rst        ),
	.c2i_addr  	(pc		    ),
	.c2i_valid 	(start		),
	.i2c_ready 	(i2c_ready  ),
	.i2c_valid 	(i2c_valid  ),
	.i2c_data  	(i2c_data   ),
	.c2i_ready 	(1'b1 		),
	.c2i_ifence	(1'b0),
	.i2m_valid 	(i2m_valid  ),
	.i2m_addr  	(i2m_addr   ),
	.m2i_ready 	(1'b1       ),
	.m2i_data  	(rdata      ),
	.m2i_valid 	(rdata_valid),
	.m2i_done	(done		),
	.i2m_ready 	(i2m_ready  )
);



axi4_full_master u_axi4_full_master(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .wen        	(1'b0        ),
    .ren        	(i2m_valid   ),
    .user_ready 	(i2m_ready   ),
	.size			(2'b10		 ),
    .len        	(8'b11       ),
    .waddr      	(32'b0       ),
    .wdata      	(32'b0       ),
	.rdata_valid	(rdata_valid ),
    .raddr      	(i2m_addr    ),
    .rdata      	(rdata       ),
    .rresp      	(rresp       ),/* verilator lint_off PINCONNECTEMPTY */
    .wresp      	(            ),
    .done       	(done        ),
    .ARREADY    	(ARREADY     ),
    .ARVALID    	(ARVALID     ),
    .ARADDR     	(ARADDR      ),
    .ARID       	(ARID        ),
    .ARLEN      	(ARLEN       ),
    .ARSIZE     	(ARSIZE      ),
    .ARBURST    	(ARBURST     ),
    .RREADY     	(RREADY      ),
    .RVALID     	(RVALID      ),
    .RDATA      	(RDATA       ),
    .RLAST      	(RLAST       ),
    .RID        	(RID         ),
    .RRESP      	(RRESP       )/* verilator lint_off PINCONNECTEMPTY */,
    .AWADDR     	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWVALID    	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWID       	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWLEN      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWSIZE     	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWBURST    	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .AWREADY    	(1'b0        ),
    .WDATA      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WSTRB      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WLAST      	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WVALID     	(            )/* verilator lint_off PINCONNECTEMPTY */,
    .WREADY     	(1'b0        ),
    .BRESP      	(2'b00       ),
    .BVALID     	(1'b0        ),
    .BID        	(4'b0        ),
    .BREADY     	(            )/* verilator lint_off PINCONNECTEMPTY */
);


/************************** 性能计数器 *****************************/

// import "DPI-C" function void is_finish_bootloader(input int pc);
// import "DPI-C" function void PerformanceCounter_ifu_fetch();
// import "DPI-C" function void PerformanceCounter_ifu_fetch_cycles(input int start, input int finish);
// import "DPI-C" function void PerformanceCounter_inst_type_total_cycles(input int start, input int inst);

// always_ff @(posedge clk) begin
// 	if (wbu_valid) is_finish_bootloader(pc);
// end

// always_ff @(posedge clk) begin
// 	if (i2c_valid) PerformanceCounter_ifu_fetch();
// end
// /* verilator lint_off WIDTHEXPAND */
// always_ff @(posedge clk) begin
// 	if (!rst) PerformanceCounter_ifu_fetch_cycles(start, i2c_valid);
// end

// always_ff @(posedge clk) begin
// 	if (!rst) PerformanceCounter_inst_type_total_cycles(start, i2c_data);
// end


/******************************************************************/

	
// `else


// assign ifu_valid = done | (state == S_WAIT_READY);

// // 模拟SRAM取指
// always_ff @(posedge clk) begin
//     ifu_data <= (ifu_valid & idu_ready) ? {rdata, pc} : ifu_data;
// end

// assign prerequest = wbu_valid;

// // output declaration of module axi4_full_master
// wire [31:0] rdata;  /* verilator lint_off UNUSEDSIGNAL */
// wire rdata_valid;
// wire [1:0] rresp;
// wire done;

// // Not used


// axi4_full_master u_axi4_full_master(
//     .clk        	(clk         ),
//     .rst        	(rst         ),
//     .wen        	(1'b0        ),
//     .ren        	(start       ),
//     .user_ready 	(idu_ready   ),
//     .size        	(2'b10       ),
// 	.len			(8'b0		 ),
//     .waddr      	(32'b0       ),
//     .wdata      	(32'b0       ),
//     .raddr      	(pc          ),
// 	.rdata_valid	(rdata_valid ),
//     .rdata      	(rdata       ),
//     .rresp      	(rresp       ),/* verilator lint_off PINCONNECTEMPTY */
//     .wresp      	(            ),
//     .done       	(done        ),
//     .ARREADY    	(ARREADY     ),
//     .ARVALID    	(ARVALID     ),
//     .ARADDR     	(ARADDR      ),
//     .ARID       	(ARID        ),
//     .ARLEN      	(ARLEN       ),
//     .ARSIZE     	(ARSIZE      ),
//     .ARBURST    	(ARBURST     ),
//     .RREADY     	(RREADY      ),
//     .RVALID     	(RVALID      ),
//     .RDATA      	(RDATA       ),
//     .RLAST      	(RLAST       ),
//     .RID        	(RID         ),
//     .RRESP      	(RRESP       )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWADDR     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWVALID    	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWID       	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWLEN      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWSIZE     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWBURST    	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .AWREADY    	(1'b0        ),
//     .WDATA      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WSTRB      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WLAST      	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WVALID     	(            )/* verilator lint_off PINCONNECTEMPTY */,
//     .WREADY     	(1'b0        ),
//     .BRESP      	(2'b00       ),
//     .BVALID     	(1'b0        ),
//     .BID        	(4'b0        ),
//     .BREADY     	(            )/* verilator lint_off PINCONNECTEMPTY */
// );


	
// `endif




endmodule


module _icache #(
    parameter BLOCK_SIZE    =   16,
    parameter BLOCK_NUM     =   16,
    parameter ADDR_WIDTH    =   32,
    parameter DATA_WIDTH    =   32
) (
    input                           clk,
    input                           rst,
    // 与IFU (指令取指单元) 数据交互
    input      [ADDR_WIDTH-1:0]     c2i_addr,   // CPU发来的指令地址
    input                           c2i_valid,  // CPU请求有效信号
    output                          i2c_ready,  // Cache是否准备好接收CPU请求
    output                          i2c_valid,  // Cache返回给CPU的数据是否有效
    output     logic [DATA_WIDTH-1:0]     i2c_data,   // Cache返回给CPU的指令数据
    input                           c2i_ready,  // CPU是否准备好接收Cache数据
	input							c2i_ifence,
    // 与主内存 (Memory) 交互
    output                          i2m_valid,  // Cache向主存的请求是否有效
    output     [ADDR_WIDTH-1:0]     i2m_addr,   // Cache向主存请求的地址 (块地址)
    input                           m2i_ready,  // 主存是否准备好接收Cache请求
    input      [DATA_WIDTH-1:0]     m2i_data,   // 主存返回给Cache的数据
    input                           m2i_valid,  // 主存返回的数据是否有效
	input 							m2i_done,
    output                          i2m_ready   // Cache是否准备好接收主存数据
);

// Calculated parameters
localparam BLOCK_WIDTH	 =	 BLOCK_SIZE * 8;
localparam INDEX_WIDTH   =   $clog2(BLOCK_NUM);
localparam OFFSET_WIDTH  =   $clog2(BLOCK_SIZE);
localparam TAG_WIDTH     =   ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH;


localparam	IDLE		=	2'b00,
			REQ_MEM		=	2'b01,
			WAIT_MEM	=	2'b11;

assign	i2c_ready	=	state[0];


// Cache storage
logic [BLOCK_NUM-1:0] 		cache_valid;
logic [TAG_WIDTH-1:0] 		cache_tag 	[BLOCK_NUM-1:0];
logic [BLOCK_WIDTH-1:0] 	cache_data 	[BLOCK_NUM-1:0];

always_ff @(posedge clk) begin
	if (rst | c2i_ifence) begin
		cache_valid <= {BLOCK_NUM{1'b0}};
	end else begin
		if (m2i_done) begin
            cache_data[index] <=  {m2i_data, m2i_data_buffer};
            cache_tag[index] <= tag;
            cache_valid[index] <= 1;
        end
	end
end

logic   [TAG_WIDTH-1:0]     tag;
logic   [INDEX_WIDTH-1:0]   index;
logic   [OFFSET_WIDTH-1:0]  offset;

assign  index   =   c2i_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
assign  tag     =   c2i_addr[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_WIDTH];
assign  offset  =   c2i_addr[OFFSET_WIDTH - 1 : 0];

/********************** 命中信号 ********************/
logic   hit;
assign  hit     =      ~state[0] & cache_valid[index] & (cache_tag[index] == tag);

/********************** 状态机 ********************/
logic	[1:0]   state,  nstate;
always_ff @(posedge clk) begin
    state <= rst ? IDLE : nstate;
end

assign nstate[0]	=	~state[0] & ~state[1] & ~hit | state[0] & ~m2i_done;
assign nstate[1]	=	state[0] & ~m2i_done;


/********************** 与mem通信 ********************/
// assign  i2m_valid   =   state[0] & ~m2i_done;
assign  i2m_valid   =   state[0] & ~state[1];
assign  i2m_addr    =   {tag, index, {OFFSET_WIDTH{1'b0}}};
assign  i2m_ready   =   1'b1;


/************************* 填充 ***********************/
logic [BLOCK_WIDTH - DATA_WIDTH - 1 : 0] m2i_data_buffer;

always_ff @(posedge clk) begin
	m2i_data_buffer <= m2i_valid ? {m2i_data, m2i_data_buffer[BLOCK_WIDTH - DATA_WIDTH - 1 : DATA_WIDTH]} : m2i_data_buffer;	// 其实可以提前一个周期，这里先不这么干
end


/************************* 返回上层数据 *************************/
assign   i2c_valid    =   c2i_valid & hit | state[1] & state[0] & m2i_done;


always_comb begin
	case({offset[3:2], state[0]})
		3'b001: i2c_data = m2i_data_buffer[31:0];
		3'b011: i2c_data = m2i_data_buffer[63:32];
		3'b101: i2c_data = m2i_data_buffer[95:64];
		3'b111: i2c_data = m2i_data;
		3'b000: i2c_data = cache_data[index][31:0];
		3'b010: i2c_data = cache_data[index][63:32];
		3'b100: i2c_data = cache_data[index][95:64];
		3'b110: i2c_data = cache_data[index][127:96];
	endcase
end


endmodule


