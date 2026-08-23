module Xbar(
    // MASTER 接口信号 (主设备端)
    // 读地址通道 (Read Address Channel)
    input  logic [3:0]  m_arid,     // 读传输 ID
    input  logic [31:0] m_araddr,   // 读地址
    input  logic [7:0]  m_arlen,    // 读突发长度
    input  logic [2:0]  m_arsize,   // 读传输大小
    input  logic [1:0]  m_arburst,  // 读突发类型
    input  logic        m_arvalid,  // 读地址有效信号
    output logic        m_arready,  // 读地址准备好信号

    // 读数据通道 (Read Data Channel)
    output logic [3:0]  m_rid,      // 读数据 ID
    output logic [31:0] m_rdata,    // 读数据
    output logic [1:0]  m_rresp,    // 读响应状态
    output logic        m_rlast,    // 读数据最后一次传输信号
    output logic        m_rvalid,   // 读数据有效信号
    input  logic        m_rready,   // 读数据准备好接收信号

    // 写地址通道 (Write Address Channel)
    input  logic [3:0]  m_awid,     // 写传输 ID
    input  logic [31:0] m_awaddr,   // 写地址
    input  logic [7:0]  m_awlen,    // 写突发长度
    input  logic [2:0]  m_awsize,   // 写传输大小
    input  logic [1:0]  m_awburst,  // 写突发类型
    input  logic        m_awvalid,  // 写地址有效信号
    output logic        m_awready,  // 写地址准备好信号

    // 写数据通道 (Write Data Channel)
    input  logic [31:0] m_wdata,    // 写数据
    input  logic [3:0]  m_wstrb,    // 写选通字节
    input  logic        m_wlast,    // 写数据最后一次传输信号
    input  logic        m_wvalid,   // 写数据有效信号
    output logic        m_wready,   // 写数据准备好信号

    // 写响应通道 (Write Response Channel - Bresp)
    output logic [3:0]  m_bid,      // 写响应 ID
    output logic [1:0]  m_bresp,    // 写响应状态
    output logic        m_bvalid,   // 写响应有效信号
    input  logic        m_bready,   // 写响应准备好接收信号

    // SLAVE 0 接口信号 (从设备 0 端)
    // 读地址通道
    output logic [3:0]  s0_arid,
    output logic [31:0] s0_araddr,
    output logic [7:0]  s0_arlen,
    output logic [2:0]  s0_arsize,
    output logic [1:0]  s0_arburst,
    output logic        s0_arvalid,
    input  logic        s0_arready,

    // 读数据通道
    input  logic [3:0]  s0_rid,
    input  logic [31:0] s0_rdata,
    input  logic [1:0]  s0_rresp,
    input  logic        s0_rlast,
    input  logic        s0_rvalid,
    output logic        s0_rready,

    // 写地址通道
    output logic [3:0]  s0_awid,
    output logic [31:0] s0_awaddr,
    output logic [7:0]  s0_awlen,
    output logic [2:0]  s0_awsize,
    output logic [1:0]  s0_awburst,
    output logic        s0_awvalid,
    input  logic        s0_awready,

    // 写数据通道
    output logic [31:0] s0_wdata,
    output logic [3:0]  s0_wstrb,
    output logic        s0_wlast,
    output logic        s0_wvalid,
    input  logic        s0_wready,

    // 写响应通道
    input  logic [3:0]  s0_bid,
    input  logic [1:0]  s0_bresp,
    input  logic        s0_bvalid,
    output logic        s0_bready,

    // SLAVE 1 接口信号 (从设备 1 端)
    // 读地址通道
    output logic [3:0]  s1_arid,
    output logic [31:0] s1_araddr,
    output logic [7:0]  s1_arlen,
    output logic [2:0]  s1_arsize,
    output logic [1:0]  s1_arburst,
    output logic        s1_arvalid,
    input  logic        s1_arready,

    // 读数据通道
    input  logic [3:0]  s1_rid,
    input  logic [31:0] s1_rdata,
    input  logic [1:0]  s1_rresp,
    input  logic        s1_rlast,
    input  logic        s1_rvalid,
    output logic        s1_rready,

    // 写地址通道
    output logic [3:0]  s1_awid,
    output logic [31:0] s1_awaddr,
    output logic [7:0]  s1_awlen,
    output logic [2:0]  s1_awsize,
    output logic [1:0]  s1_awburst,
    output logic        s1_awvalid,
    input  logic        s1_awready,

    // 写数据通道
    output logic [31:0] s1_wdata,
    output logic [3:0]  s1_wstrb,
    output logic        s1_wlast,
    output logic        s1_wvalid,
    input  logic        s1_wready,

    // 写响应通道
    input  logic [3:0]  s1_bid,
    input  logic [1:0]  s1_bresp,
    input  logic        s1_bvalid,
    output logic        s1_bready
);

//--------------------------------------------------------------------------
// 路由逻辑 (Routing Logic)
//--------------------------------------------------------------------------
logic select_s1_ar; // 标志位：主设备读地址通道 (AR) 目标是 Slave 1
logic select_s0_ar; // 标志位：主设备读地址通道 (AR) 目标是 Slave 0
logic select_s1_aw; // 标志位：主设备写地址通道 (AW) 目标是 Slave 1
logic select_s0_aw; // 标志位：主设备写地址通道 (AW) 目标是 Slave 0

// 地址解码：如果地址的高16位是 0x0200，则目标为 Slave 1，否则为 Slave 0
assign select_s1_ar = (m_araddr[31:16] == 16'h0200);
assign select_s0_ar = ~select_s1_ar; // 不是 Slave 1 就是 Slave 0

assign select_s1_aw = (m_awaddr[31:16] == 16'h0200);
assign select_s0_aw = ~select_s1_aw; // 不是 Slave 1 就是 Slave 0


//--------------------------------------------------------------------------
// 读地址 (AR) 通道路由 (Master -> Slaves)
//--------------------------------------------------------------------------
// 根据 m_araddr 将 AR 通道信号路由到选定的从设备
assign s0_arvalid = m_arvalid & select_s0_ar; // S0 的 AR 有效，当主设备 AR 有效且目标是 S0
assign s0_arid    = m_arid;                   // ID 透传
assign s0_araddr  = m_araddr;                 // 地址透传
assign s0_arlen   = m_arlen;                  // 长度透传
assign s0_arsize  = m_arsize;                 // 大小透传
assign s0_arburst = m_arburst;                // 突发类型透传

assign s1_arvalid = m_arvalid & select_s1_ar; // S1 的 AR 有效，当主设备 AR 有效且目标是 S1
assign s1_arid    = m_arid;
assign s1_araddr  = m_araddr;
assign s1_arlen   = m_arlen;
assign s1_arsize  = m_arsize;
assign s1_arburst = m_arburst;

// 主设备看到的 arready 来自它正在寻址的那个从设备
assign m_arready  = select_s1_ar ? s1_arready : s0_arready; // 如果目标是S0，则用s0_arready，否则用s1_arready






//--------------------------------------------------------------------------
// 读数据 (R) 通道路由 (Slaves -> Master)
//--------------------------------------------------------------------------
// 将来自从设备的读数据复用回主设备。
assign m_rvalid = select_s1_ar ? s1_rvalid : s0_rvalid;	// assign m_rvalid = s1_rvalid | s0_rvalid;	更简单的写法

// 从活动的从设备选择数据
assign m_rid    = select_s1_ar ? s1_rid    : s0_rid;    // 根据选择输出 rid
assign m_rdata  = select_s1_ar ? s1_rdata  : s0_rdata;  // 根据选择输出 rdata
assign m_rresp  = select_s1_ar ? s1_rresp  : s0_rresp;  // 根据选择输出 rresp
assign m_rlast  = select_s1_ar ? s1_rlast  : s0_rlast;  // 根据选择输出 rlast

// 将主设备的 ready 信号回传给被选中的那个从设备
assign s0_rready = m_rready;	// assign s0_rready = m_rready & select_s0_ar;	更规范的写法
assign s1_rready = m_rready;	// assign s1_rready = m_rready & select_s1_ar;	更规范的写法








//--------------------------------------------------------------------------
// 写地址 (AW) 通道路由 (Master -> Slaves)
//--------------------------------------------------------------------------
// 根据 m_awaddr 将 AW 通道信号路由到选定的从设备
assign s0_awvalid = m_awvalid & select_s0_aw; // S0 的 AW 有效，当主设备 AW 有效且目标是 S0
assign s0_awid    = m_awid;                   // ID 透传
assign s0_awaddr  = m_awaddr;                 // 地址透传
assign s0_awlen   = m_awlen;                  // 长度透传
assign s0_awsize  = m_awsize;                 // 大小透传
assign s0_awburst = m_awburst;                // 突发类型透传

assign s1_awvalid = m_awvalid & select_s1_aw; // S1 的 AW 有效，当主设备 AW 有效且目标是 S1
assign s1_awid    = m_awid;
assign s1_awaddr  = m_awaddr;
assign s1_awlen   = m_awlen;
assign s1_awsize  = m_awsize;
assign s1_awburst = m_awburst;

// 主设备看到的 awready 来自它正在寻址的那个从设备
assign m_awready  = select_s1_aw ? s1_awready : s0_awready; // 如果目标是S0，则用s0_awready，否则用s1_awready








//--------------------------------------------------------------------------
// 写数据 (W) 通道路由 (Master -> Slaves)
//--------------------------------------------------------------------------
// Master 在 AW/W 完成前保持地址稳定，因此 W 通道可复用 AW 地址译码结果。
assign s0_wvalid = m_wvalid & select_s0_aw; // S0 的 W 有效，当主设备 W 有效且 AW 目标是 S0
assign s0_wdata  = m_wdata;                 // 数据透传
assign s0_wstrb  = m_wstrb;                 // 字节选通透传
assign s0_wlast  = m_wlast;                 // last 信号透传

assign s1_wvalid = m_wvalid & select_s1_aw; // S1 的 W 有效，当主设备 W 有效且 AW 目标是 S1
assign s1_wdata  = m_wdata;
assign s1_wstrb  = m_wstrb;
assign s1_wlast  = m_wlast;

// 主设备看到的 wready 来自 AW 通道所指向的那个从设备
assign m_wready  = select_s1_aw ? s1_wready : s0_wready; // 如果 AW 目标是S0，则用s0_wready，否则用s1_wready








//--------------------------------------------------------------------------
// 写响应 (B) 通道路由 (Slaves -> Master)
//--------------------------------------------------------------------------
// 将来自从设备的写响应复用回主设备。

assign m_bvalid = select_s1_aw ? s1_bvalid : s0_bvalid;		// assign m_bvalid = s1_bvalid | s0_bvalid;	更简单的写法

// 从活动的从设备选择响应
assign m_bid    = select_s1_aw ? s1_bid    : s0_bid;    // 根据选择输出 bid
assign m_bresp  = select_s1_aw ? s1_bresp  : s0_bresp;  // 根据选择输出 bresp

// 将主设备的 ready 信号回传给被选中的那个从设备
assign s0_bready = m_bready;	// assign s0_bready = m_bready & select_s0_aw;	更规范的写法
assign s1_bready = m_bready;	// assign s1_bready = m_bready & select_s1_aw;	更规范的写法

endmodule // Xbar
