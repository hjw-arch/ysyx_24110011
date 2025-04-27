// module icache #(
// 	parameter BLOCK_SIZE	=	4,
// 	parameter BLOCK_NUM		=	16,
// 	parameter ADDR_WIDTH	=	32,
// 	parameter DATA_WIDTH	=	32,

// 	parameter INDEX_WIDTH	=	$clog2(BLOCK_NUM),
// 	parameter OFFSET_WIDTH	=	$clog2(BLOCK_SIZE),
// 	parameter TAG_WIDTH		=	ADDR_WIDTH - INDEX_WIDTH - OFFSET_WIDTH

// ) (
// 	input 							clk,
// 	input 							rst,

// 	input	[ADDR_WIDTH-1:0]		addr,
// 	input	[DATA_WIDTH-1:0]		mdata,		// 来自内存的数据

// 	output 	[DATA_WIDTH-1:0]		data,
// 	output							hit			// 是否命中
// );

// /*********************************************** cache定义 ****************************************/

// typedef struct {								// 定义cache块
// 	logic 					valid;
// 	logic [TAG_WIDTH-1:0] 	tag;
// 	logic [DATA_WIDTH-1:0] 	data;
// } cache_block_t;

// cache_block_t cache[0:BLOCK_NUM-1];


// /******************************************** 地址分解 *********************************************/

// logic	[TAG_WIDTH-1:0]		tag;



	
// endmodule //icache
