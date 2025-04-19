/*------------------------------------------------------------------------------
 * MODULE: ps2_top_apb
 * DESCRIPTION:
 *   APB slave module for interfacing with a PS/2 keyboard.
 *   Provides the last received scan code at offset 0x0.
 * PARAMETERS:
 *   APB_ADDR_WIDTH: Width of the APB address bus (implicitly 32 from input).
 *   APB_DATA_WIDTH: Width of the APB data bus (implicitly 32 from input).
 *   TARGET_ADDR: Base address of this peripheral on the APB bus.
 *   SCAN_CODE_ADDR: Offset for the scan code register.
 *------------------------------------------------------------------------------*/
module ps2_top_apb #(
    parameter TARGET_ADDR    = 32'h1001_1000, // 外设基地址
    parameter SCAN_CODE_ADDR = 32'h0          // 扫描码寄存器偏移地址
) (
    // APB Interface Signals (APB接口信号)
    input         clock,        // 系统时钟 (System clock)
    input         reset,        // 系统复位, 高有效 (System reset, active high)
    input  [31:0] in_paddr,     // APB 地址总线 (APB address bus)
    input         in_psel,      // APB 外设选择信号 (APB peripheral select)
    input         in_penable,   // APB 使能信号 (APB enable strobe)
    input  [2:0]  in_pprot,     // APB 保护类型 (APB protection type - unused)
    input         in_pwrite,    // APB 写操作信号 (APB write transfer)
    input  [31:0] in_pwdata,    // APB 写数据总线 (APB write data bus - unused)
    input  [3:0]  in_pstrb,     // APB 写选通信号 (APB write strobes - unused)
    output        in_pready,    // APB 传输就绪信号 (APB transfer ready)
    output [31:0] in_prdata,    // APB 读数据总线 (APB read data bus)
    output        in_pslverr,   // APB 传输错误信号 (APB transfer error - unused)

    // PS/2 Interface Signals (PS/2接口信号)
    input         ps2_clk,      // PS/2 时钟信号 (来自键盘) (PS/2 clock from keyboard)
    input         ps2_data      // PS/2 数据信号 (来自键盘) (PS/2 data from keyboard)
);

    //--------------------------------------------------------------------------
    // Internal Signals and Registers (内部信号和寄存器)
    //--------------------------------------------------------------------------

    // --- Synchronization (同步逻辑) ---
    reg  ps2_clk_sync1, ps2_clk_sync2, ps2_clk_sync3; // PS/2时钟同步寄存器
    reg  ps2_data_sync1, ps2_data_sync2, ps2_data_sync3; // PS/2数据同步寄存器
    wire ps2_clk_sync;      // 同步后的PS/2时钟 (Synchronized PS/2 clock)
    wire ps2_data_sync;     // 同步后的PS/2数据 (Synchronized PS/2 data)
    wire ps2_clk_falling;   // 检测到的PS/2时钟下降沿 (Detected PS/2 clock falling edge)

    // --- PS/2 Receiver State Machine (PS/2接收状态机) ---
    localparam [1:0] S_IDLE    = 2'b00, // 空闲状态
                     S_RECEIVE = 2'b01, // 接收数据状态
                     S_STOP    = 2'b10; // 停止位状态

    reg [1:0]  current_state, next_state; // FSM 状态寄存器
    reg [3:0]  bit_count;       // 接收位数计数器 (0-10: start, d0-d7, parity, stop)
    reg [9:0]  ps2_shift_reg;   // 移位寄存器 (start, data[7:0], parity)
    reg [7:0]  scan_code_reg;   // 存储最后接收到的扫描码
    reg        scan_code_valid; // 扫描码有效标志

    // --- APB Logic (APB逻辑) ---
    wire       addr_match;      // 地址匹配信号 (Address match signal)
    wire       apb_read_op;     // APB 读操作 (APB read operation)
    wire       apb_write_op;    // APB 写操作 (APB write operation)
    wire       apb_access_phase;// APB 访问阶段 (APB access phase)
    reg [31:0] prdata_out;      // 内部读数据寄存器

    //--------------------------------------------------------------------------
    // Synchronization Logic (同步逻辑实现)
    //--------------------------------------------------------------------------
    // 使用三级触发器同步来自键盘的异步信号 ps2_clk 和 ps2_data
    // Use 3 flip-flops to synchronize asynchronous inputs from the keyboard
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ps2_clk_sync1  <= 1'b1; // PS/2 空闲时为高电平
            ps2_clk_sync2  <= 1'b1;
            ps2_clk_sync3  <= 1'b1;
            ps2_data_sync1 <= 1'b1; // PS/2 空闲时为高电平
            ps2_data_sync2 <= 1'b1;
            ps2_data_sync3 <= 1'b1;
        end else begin
            ps2_clk_sync1  <= ps2_clk;
            ps2_clk_sync2  <= ps2_clk_sync1;
            ps2_clk_sync3  <= ps2_clk_sync2;
            ps2_data_sync1 <= ps2_data;
            ps2_data_sync2 <= ps2_data_sync1;
            ps2_data_sync3 <= ps2_data_sync2;
        end
    end

    assign ps2_clk_sync  = ps2_clk_sync3;
    assign ps2_data_sync = ps2_data_sync3;

    // 检测同步后 PS/2 时钟的下降沿 (Detect falling edge of synchronized PS/2 clock)
    // 使用同步后的第二级和第三级比较, 减少毛刺影响
    assign ps2_clk_falling = ps2_clk_sync2 & ~ps2_clk_sync3;

    //--------------------------------------------------------------------------
    // PS/2 Receiver Finite State Machine (FSM) (PS/2接收有限状态机)
    //--------------------------------------------------------------------------

    // --- State Register (状态寄存器) ---
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // --- Next State Logic & Datapath Logic (下一状态逻辑和数据通路逻辑) ---
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            bit_count       <= 4'b0;
            ps2_shift_reg   <= 10'b0;
            scan_code_reg   <= 8'b0;
            scan_code_valid <= 1'b0; // 复位时无效
        end else begin
            // APB 读操作会清除 scan_code_valid 标志
            if (apb_read_op && apb_access_phase && addr_match && scan_code_valid) begin
                scan_code_valid <= 1'b0;
            end

            // FSM transitions and actions based on ps2_clk_falling edge
            // 状态机转换和操作 (在系统时钟下，但由PS/2时钟下降沿触发)
            if (ps2_clk_falling) begin
                case (current_state)
                    S_IDLE: begin
                        // 检测到起始位 (ps2_data_sync 为低)
                        if (~ps2_data_sync) begin
                           // next_state 在组合逻辑中设置 (将在下一个时钟周期生效)
                           // bit_count 和 ps2_shift_reg 在这里不需要立即更新
                           // 因为第一个下降沿是起始位，数据在后续下降沿采集
                           bit_count <= 4'd1; // 开始计数第一个数据位
                           // next_state will be S_RECEIVE (set combinatorially)
                        end else begin
                           // 保持空闲
                           bit_count <= 4'b0;
                           // next_state will be S_IDLE (set combinatorially)
                        end
                    end // case: S_IDLE

                    S_RECEIVE: begin
                        // 移入当前数据位 (LSB first)
                        // 注意：ps2_shift_reg[0] 是起始位，我们关心 data[7:0] 和 parity
                        // 在第1个下降沿(bit_count=1)读d0, ..., 第8个下降沿(bit_count=8)读d7, 第9个下降沿(bit_count=9)读parity
                        ps2_shift_reg[bit_count-1] <= ps2_data_sync; // bit_count 从 1 到 9
                        if (bit_count == 9) begin // 接收完8位数据和1位奇偶校验位
                           bit_count <= 4'd10; // 准备接收停止位
                           // next_state will be S_STOP (set combinatorially)
                        end else begin
                           bit_count <= bit_count + 1;
                           // next_state will be S_RECEIVE (set combinatorially)
                        end
                    end // case: S_RECEIVE

                    S_STOP: begin
                       // 检查停止位 (ps2_data_sync 应该为高)
                       // 这里我们不强制检查奇偶校验位或停止位，简化处理
                       // 如果需要更严格的检查，可以在这里加入逻辑
                       if (ps2_data_sync) begin // 假设停止位有效
                           // 接收完成, 存储扫描码 (data bits are in ps2_shift_reg[7:0])
                           scan_code_reg   <= ps2_shift_reg[7:0];
                           scan_code_valid <= 1'b1; // 标记数据有效
                           $display("PS/2 Received Scan Code: 0x%h", ps2_shift_reg[7:0]); // 仿真时打印信息
                       end else begin
                           // 停止位错误，可以选择忽略或报错
                           // 这里我们简单忽略错误的数据帧
                           // scan_code_valid 保持不变 (可能为0，或上一次有效的值)
                           $display("PS/2 Stop bit error");
                       end
                       bit_count <= 4'b0; // 复位计数器
                       // next_state will be S_IDLE (set combinatorially)
                    end // case: S_STOP

                    default: begin
                       // 不应该发生, 回到 IDLE
                       bit_count <= 4'b0;
                       // next_state will be S_IDLE (set combinatorially)
                    end
                endcase // case(current_state)
            end // if (ps2_clk_falling)
            // 如果 APB 读取清除了 valid 标志，但 FSM 没有在同一个周期产生新的数据，
            // valid 标志应保持清除状态，上面的 APB 清除逻辑已处理此情况。
            // 如果 FSM 在同一个周期产生了新数据 (ps2_clk_falling 恰好发生)，
            // 新数据的 valid 标志会覆盖 APB 的清除操作（因为 FSM 逻辑在后面）。
            // 注意：上面scan_code_valid的赋值在时钟边沿，APB清除逻辑也在时钟边沿，
            // 需要确保优先级或时序正确。将APB清除逻辑放在 FSM 逻辑之前，
            // 这样如果同时发生读和接收完成，接收完成会置位 valid。
        end // else: !if(reset)
    end // always @ (posedge clock or posedge reset)

    // --- Combinational Next State Logic (组合下一状态逻辑) ---
    always @(*) begin
        next_state = current_state; // 默认保持当前状态
        case (current_state)
            S_IDLE: begin
                // 等待下降沿和起始位 (在时序逻辑中处理具体跳转条件)
                // 如果 ps2_clk_falling 且 ps2_data_sync 为低, 则跳转
                if (ps2_clk_falling && ~ps2_data_sync) begin
                   next_state = S_RECEIVE;
                end
            end
            S_RECEIVE: begin
                // 等待下降沿 (在时序逻辑中处理具体跳转条件)
                // 如果 bit_count == 9 且 ps2_clk_falling, 则跳转
                 if (ps2_clk_falling && (bit_count == 9)) begin
                   next_state = S_STOP;
                 end
            end
            S_STOP: begin
                // 等待下降沿 (在时序逻辑中处理具体跳转条件)
                // 处理完停止位后，总是在下一个下降沿回到 IDLE
                if (ps2_clk_falling) begin
                    next_state = S_IDLE;
                end
            end
            default: next_state = S_IDLE; // 安全默认状态
        endcase
    end

    //--------------------------------------------------------------------------
    // APB Slave Interface Logic (APB从设备接口逻辑)
    //--------------------------------------------------------------------------

    // --- Address Decoding (地址译码) ---
    // 检查访问地址是否为扫描码寄存器地址 (基地址 + 偏移)
    // assign addr_match = (in_paddr == (TARGET_ADDR + SCAN_CODE_ADDR));
    // 更通用的做法：假设总线结构已将基地址匹配，只需检查偏移
     assign addr_match = (in_paddr[11:0] == SCAN_CODE_ADDR[11:0]); // 假设偏移在低12位足够区分

    // --- APB Operation Signals (APB操作信号) ---
    assign apb_read_op  = in_psel & ~in_pwrite;
    assign apb_write_op = in_psel & in_pwrite;
    assign apb_access_phase = in_psel & in_penable; // 访问阶段信号

    // --- PREADY Signal (APB就绪信号) ---
    // 对于简单的寄存器访问，通常可以立即准备好
    // pready 在选中(psel)后一个周期（enable阶段）拉高
    // 这里简化处理：只要被选中就绪绪，或者在访问阶段就绪
    // assign in_pready = in_psel; // 简单方式：选中即就绪 (可能不完全符合APB时序)
     assign in_pready = apb_access_phase; // 更标准的：在Access阶段拉高，表示数据已准备好/写入已接收

    // --- PRDATA Signal (APB读数据信号) ---
    // 组合逻辑输出读数据
    // 如果是读操作、地址匹配且扫描码有效，则输出扫描码 (低8位)，否则输出0
    always @(*) begin
        if (apb_read_op && addr_match) begin // 只关心读操作和地址匹配
            if (scan_code_valid) begin
                prdata_out = {24'b0, scan_code_reg}; // 输出8位扫描码，高位补零
            end else begin
                prdata_out = 32'h0000_0000; // 无有效数据时读出0
            end
        end else begin
            prdata_out = 32'h0000_0000; // 非读操作或地址不匹配时输出0
        end
    end
    assign in_prdata = prdata_out; // 连接到输出端口

    // --- PSLVERR Signal (APB错误信号) ---
    // 在这个简单实现中，我们不产生错误
    // 对于写操作或访问保留地址，我们简单地忽略
    assign in_pslverr = 1'b0;

endmodule // ps2_top_apb
