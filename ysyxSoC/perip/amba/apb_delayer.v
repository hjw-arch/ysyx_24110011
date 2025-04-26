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

  // --- 参数 ---
  // r=7.2, s=16 => r*s = 115.2
  localparam [15:0] R_S       = 16'd115; // floor(r*s)
  localparam        S_SHIFT   = 4;       // log2(s)

  localparam [15:0] K1_TARGET = R_S >> S_SHIFT;

  // --- 状态定义 ---
  localparam [1:0] IDLE      = 2'b00; // 空闲
  localparam [1:0] COUNTING  = 2'b01; // 等待 Slave 并计数/累加
  localparam [1:0] WAITING   = 2'b11; // 倒计时 (从 k*r 减到 k)

  // --- 内部信号与寄存器 ---
  logic [1:0]  state, next_state;
  logic [15:0] counter;           // counter: 16 位
  logic [8:0]  hold_timer;        // hold_timer: 9 位 (k max 300)
  logic [31:0] hold_prdata;
  logic        hold_pslverr;
  logic        hold_penable;       // 中间信号用于 out_penable
  logic        transaction_done;   // 标志事务延迟完成 (组合)
  logic        capture_response;   // 触发锁存 (组合)

  //--------------------------------------------------------------------------
  // 输出信号赋值
  //--------------------------------------------------------------------------
  assign out_paddr   = in_paddr;
  assign out_psel    = in_psel;
  assign out_penable = hold_penable; // 使用组合逻辑控制
  assign out_pprot   = in_pprot;
  assign out_pwrite  = in_pwrite;
  assign out_pwdata  = in_pwdata;
  assign out_pstrb   = in_pstrb;

  // 组合逻辑判断事务是否完成 (WAITING 状态且 counter 减到 k)
  // 比较完整的 16 位 counter 是否等于零扩展的 9 位 hold_timer
  assign transaction_done = (state == WAITING) && (counter == {7'b0, hold_timer});

  // Master Ready 信号，只在事务完成的那个周期有效
  assign in_pready   = transaction_done;

  // 输出锁存的数据/错误
  assign in_prdata   = hold_prdata;
  assign in_pslverr  = hold_pslverr;

  // out_penable 的组合控制逻辑 (根据你的写法)
  assign hold_penable = (in_penable && state != WAITING);

  //--------------------------------------------------------------------------
  // 状态机以及状态转移 (组合逻辑部分)
  //--------------------------------------------------------------------------
  always_comb begin
    next_state = state;
    capture_response = 1'b0;

    case(state)
      IDLE: begin
        if (in_psel && in_penable) begin
          if (!out_pready) begin // k > 1
            next_state = COUNTING;
          end else begin // k = 1
            next_state = WAITING;
            capture_response = 1'b1; // 组合触发锁存 (k=1)
          end
        end
      end

      COUNTING: begin
        if (out_pready) begin // Slave 响应
          next_state = WAITING;
          capture_response = 1'b1; // 组合触发锁存 (k>1)
        end else begin
          next_state = COUNTING; // 保持
        end
      end

      WAITING: begin
        if (transaction_done) begin // 倒计时完成
          next_state = IDLE; // 返回空闲
        end else begin
          next_state = WAITING; // 保持
        end
      end

      default: next_state = IDLE; // 覆盖所有状态，default 其实可以省略
    endcase
  end

  //--------------------------------------------------------------------------
  // 状态机寄存器更新 (时序逻辑部分)
  //--------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (reset) state <= IDLE;
    else state <= next_state;
  end

  //--------------------------------------------------------------------------
  // k 计数器 (hold_timer, 9位) 更新
  //--------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (reset) begin
        hold_timer <= 9'b0;
    end else begin
        // 事务开始时 (IDLE -> COUNTING/WAITING)，k 初始化为 1
        if (state == IDLE && next_state != IDLE) begin // 修正: 使用 next_state 判断启动更准确
             hold_timer <= 9'd1;
        // 在 COUNTING 状态且 Slave 未响应时递增 k
        end else if (state == COUNTING && !out_pready) begin
            hold_timer <= hold_timer + 1;
        // 事务完成时 (WAITING -> IDLE) 清零 k
        end else if (state == WAITING && next_state == IDLE) begin
            hold_timer <= 9'b0;
        end
        // 其他情况 (如 WAITING 期间, IDLE 无操作) 保持 hold_timer 值
    end
  end

  //--------------------------------------------------------------------------
  // 累加/倒计时计数器 (counter, 16位) 更新
  //--------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (reset) begin
        counter <= 16'b0;
    end else begin
        case(state)
            IDLE: begin
                if (next_state == COUNTING) begin // IDLE -> COUNTING (k>1)
                    counter <= R_S;
                end else if (next_state == WAITING) begin // IDLE -> WAITING (k=1)
                    counter <= K1_TARGET; // 加载 k=1 时的目标 k*r 值
                end else begin // 保持 IDLE 或 Reset
                    counter <= 16'b0;
                end
            end

            COUNTING: begin
                if (out_pready) begin // COUNTING -> WAITING
                    counter <= counter >> S_SHIFT;
                end else begin // 保持 COUNTING
                    counter <= counter + R_S; // 继续累加
                end
            end

            WAITING: begin
                if (!transaction_done) begin // WAITING -> WAITING
                    counter <= counter - 1; // 倒计时
                end else begin // WAITING -> IDLE
                    counter <= 16'b0; // 完成后清零
                end
            end
            default: counter <= 16'b0; // 异常状态清零
        endcase
    end
  end

  //--------------------------------------------------------------------------
  // 数据锁存 (hold_prdata)
  //--------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (capture_response) begin
        hold_prdata <= out_prdata;
    end
  end

  //--------------------------------------------------------------------------
  // 错误锁存 (hold_pslverr)
  //--------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (capture_response) begin
        hold_pslverr <= out_pslverr;
    end
  end

  always_ff @(posedge clock) begin
	if (state != IDLE) begin
		$display("counter = %d", counter);
	end
  end

endmodule

