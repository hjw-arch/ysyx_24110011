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

// 	// 与IFU数据交互
// 	input	[ADDR_WIDTH-1:0]		c2i_addr,
// 	input							c2i_valid,
// 	output 							i2c_ready,

// 	output 							i2c_valid,
// 	output 	[DATA_WIDTH-1:0]		i2c_data,
// 	input 							c2i_ready,

// 	// 与mem交互
// 	output							i2m_valid,
// 	output 	[ADDR_WIDTH-1:0]		i2m_addr,
// 	input							m2i_ready,

// 	input	[DATA_WIDTH-1:0]		m2i_data,
// 	input 							m2i_valid,
// 	output 							i2m_ready
// );

// /*********************************************** cache定义 ****************************************/

// typedef struct {								// 定义cache块
// 	logic 					valid;
// 	logic [TAG_WIDTH-1:0] 	tag;
// 	logic [DATA_WIDTH-1:0] 	data;
// } cache_block_t;

// cache_block_t cache [0:BLOCK_NUM-1];


// /******************************************** 地址分解 *********************************************/

// logic	[TAG_WIDTH-1:0]		tag;
// logic	[INDEX_WIDTH-1:0]	index;
// logic	[OFFSET_WIDTH-1:0]	offset;

// assign	tag		=	c2i_addr[ADDR_WIDTH - 1 : ADDR_WIDTH - TAG_WIDTH];
// assign	index	=	c2i_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
// assign	offset	=	c2i_addr[OFFSET_WIDTH - 1 : 0];


// /***************************************** 命中检测 *************************************************/

// logic 	hit;
// assign	hit	=	cache[index].tag == tag && cache[index].valid == 1'b1;


// /***************************************** 状态机 ***************************************************/

// localparam		IDLE	=	


	
// endmodule //icache
