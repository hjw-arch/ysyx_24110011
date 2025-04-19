module ps2_top_apb(
  input         clock,        // 系统时钟
  input         reset,        // 复位信号
  input  [31:0] in_paddr,     // APB 地址
  input         in_psel,      // APB 选择信号
  input         in_penable,   // APB 使能信号
  input  [2:0]  in_pprot,     // APB 保护信号
  input         in_pwrite,    // APB 写使能
  input  [31:0] in_pwdata,    // APB 写数据
  input  [3:0]  in_pstrb,     // APB 写字节选通
  output        in_pready,    // APB 就绪信号
  output [31:0] in_prdata,    // APB 读数据
  output        in_pslverr,   // APB 错误信号

  input         ps2_clk,      // PS/2 时钟输入
  input         ps2_data      // PS/2 数据输入
);

  // APB 接口信号
  assign in_pready  = in_psel & in_penable;  // 当选择且使能时，置为就绪
  assign in_pslverr = (in_paddr != 32'h10011000) | (in_pwrite & in_penable);  // 地址不匹配或尝试写操作时，报错
  assign in_prdata  = (in_psel & in_penable & ~in_pwrite) ? {24'b0, fifo_empty ? 8'b0 : fifo_rdata} : 32'b0;  // 读数据，FIFO 空时返回 0

  // PS/2 时钟同步（3级同步，防止亚稳态）
  reg [2:0] ps2_clk_sync;
  always @(posedge clock) begin
    ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
  end
  wire sampling = ~ps2_clk_sync[2] & ps2_clk_sync[1];  // 检测 PS/2 时钟下降沿

  // PS/2 数据同步（2级同步）
  reg [1:0] ps2_data_sync;
  always @(posedge clock) begin
    ps2_data_sync <= {ps2_data_sync[0], ps2_data};
  end
  wire ps2_data_stable = ps2_data_sync[1];  // 稳定后的 PS/2 数据

  // PS/2 接收逻辑
  reg [3:0] cnt;          // 位计数器（0-10，11位帧）
  reg [10:0] rx_shift;    // 移位寄存器：起始位(1) + 数据(8) + 奇偶校验(1) + 停止位(1)
  reg receiving;          // 接收状态

  always @(posedge clock) begin
    if (reset) begin
      cnt <= 4'd0;
      rx_shift <= 11'b0;
      receiving <= 1'b0;
    end else if (sampling) begin
      if (!receiving) begin
        if (ps2_data_stable == 1'b0) begin  // 检测到起始位
          receiving <= 1'b1;
          cnt <= 4'd0;
          rx_shift <= {ps2_data_stable, rx_shift[10:1]};
        end
      end else begin
        rx_shift <= {ps2_data_stable, rx_shift[10:1]};  // 移位接收数据
        cnt <= cnt + 1;
        if (cnt == 4'd10) begin  // 完成 11 位帧接收
          receiving <= 1'b0;
        end
      end
    end
  end

  // FIFO 控制信号
  wire fifo_wen = (cnt == 4'd10) & sampling & (^rx_shift[8:1] == rx_shift[9]) & (rx_shift[0] == 1'b0) & (rx_shift[10] == 1'b1);  // 帧有效时写入 FIFO
  wire [7:0] fifo_wdata = rx_shift[8:1];  // 提取 8 位数据
  wire fifo_ren = in_psel & in_penable & ~in_pwrite & (in_paddr == 32'h10011000);  // 读操作触发 FIFO 读取
  wire [7:0] fifo_rdata;
  wire fifo_empty, fifo_full;

  // FIFO 实例化
  FIFO #(8, 8) fifo (
    .clk(clock),
    .rst(reset),
    .wen(fifo_wen),
    .ren(fifo_ren),
    .wdata(fifo_wdata),
    .rdata(fifo_rdata),
    .full(fifo_full),
    .empty(fifo_empty)
  );

endmodule

// FIFO 模块
module FIFO #(
  parameter DATA_WIDTH = 8,   // 数据宽度
  parameter FIFO_DEPTH = 8,   // FIFO 深度
  parameter INDEX_WIDTH = $clog2(FIFO_DEPTH)  // 指针宽度
) (
  input                        clk,      // 时钟
  input                        rst,      // 复位
  input                        wen,      // 写使能
  input                        ren,      // 读使能
  input  [DATA_WIDTH-1:0]      wdata,    // 写数据
  output [DATA_WIDTH-1:0]      rdata,    // 读数据
  output                       full,     // FIFO 满标志
  output                       empty     // FIFO 空标志
);

  reg [DATA_WIDTH-1:0] fifo_reg [0:FIFO_DEPTH-1];  // FIFO 存储寄存器
  reg [INDEX_WIDTH:0] w_ptr, r_ptr;  // 写指针和读指针（多一位用于满/空检测）

  assign empty = (w_ptr == r_ptr);  // 读写指针相等时为空
  assign full  = (w_ptr[INDEX_WIDTH-1:0] == r_ptr[INDEX_WIDTH-1:0]) && (w_ptr[INDEX_WIDTH] != r_ptr[INDEX_WIDTH]);  // 指针低位相等且高位不同时为满
  assign rdata = fifo_reg[r_ptr[INDEX_WIDTH-1:0]];  // 输出读数据

  // 写指针和数据更新
  always @(posedge clk) begin
    if (rst) begin
      w_ptr <= 0;
    end else if (wen & ~full) begin
      fifo_reg[w_ptr[INDEX_WIDTH-1:0]] <= wdata;  // 写入数据
      w_ptr <= w_ptr + 1;  // 更新写指针
    end
  end

  // 读指针更新
  always @(posedge clk) begin
    if (rst) begin
      r_ptr <= 0;
    end else if (ren & ~empty) begin
      r_ptr <= r_ptr + 1;  // 更新读指针
    end
  end

endmodule
