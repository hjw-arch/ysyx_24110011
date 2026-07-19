/*
 * YSYX Review Studio
 * Static by design: no framework, no build step, and progress stays in localStorage.
 */
(function () {
  "use strict";

  const DEFAULT_ROOT = "/home/hjw-arch/ysyx-workbench";
  const PROGRESS_KEY = "ysyx-review-progress-v1";
  const ROOT_KEY = "ysyx-review-root-v1";
  const WSL_DISTRO_KEY = "ysyx-review-wsl-distro-v1";
  const QUIZ_KEY = "ysyx-review-quiz-v1";

  const app = document.querySelector("#app");
  const workspaceInput = document.querySelector("#workspace-root");
  const wslDistroInput = document.querySelector("#wsl-distro");
  const detailDialog = document.querySelector("#detail-dialog");
  const dialogContent = document.querySelector("#dialog-content");
  const toast = document.querySelector("#toast");

  const chapters = [
    {
      id: "c1",
      short: "C1",
      title: "支持 RV32IM 的 NEMU",
      subtitle: "先恢复 ISA 状态机：一条指令如何改变 PC、GPR、内存和 CSR。",
      official: "https://ysyx.oscc.cc/docs/2306/basic/1.1.html",
      overview: "官方任务是完成 PA2 阶段 1。复习时不要只背 INSTPAT：要能用当前 NEMU 和 NPC 的实现，从取指、译码、执行到 dnpc，解释一条 RV32IM 指令如何改变 ISA 状态。",
      tasks: [
        {
          id: "c1-rv32im",
          required: true,
          title: "重建 RV32IM 指令执行模型",
          how: "阅读 RISC-V 指令匹配、寄存器与执行循环；手写 addi、lw、beq、jalr、div 的 src1/src2/imm/dnpc/写回路径。",
          why: "NEMU 是 ISA 状态机的参考实现。NPC DiffTest 出现第一个差异时，必须能回到这里判断架构语义是否正确。",
          verify: ["make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run git_commit="],
          links: [
            ["nemu/src/isa/riscv32/inst.c", 1, "指令译码与语义"],
            ["nemu/src/cpu/cpu-exec.c", 1, "执行循环"],
            ["nemu/src/isa/riscv32/reg.c", 1, "寄存器实现"],
            ["nemu/src/memory/paddr.c", 1, "物理内存访问"]
          ]
        },
        {
          id: "c1-imm",
          required: true,
          title: "闭卷恢复六类立即数与有符号语义",
          how: "分别写出 R/I/S/B/U/J 格式，尤其是 B/J 的分散位拼接、符号扩展和低位补零。比较 slt/sltu、lb/lbu、sra/srl 的实现。",
          why: "立即数和 signed/unsigned 是 CPU tests 与 DiffTest 最常见的第一类失败根源。",
          verify: ["挑选 addi、lb、lbu、beq、jal、jalr、sra、sltu 的 cpu-test 单独复现"],
          links: [["nemu/src/isa/riscv32/inst.c", 1, "立即数和 INSTPAT"]]
        },
        {
          id: "c1-rv32m",
          required: false,
          title: "选做：检查 RV32M 边界行为",
          how: "用 ISA 规范核对乘除、余数、除零和 INT_MIN / -1 的语义；确认软件参考模型与硬件/运行库没有混淆。",
          why: "RV32E 核心没有 M 扩展时，C 程序里的乘除通常由 libgcc 补齐；考核常借此考查 ISA 与运行时的边界。",
          verify: ["运行 div、mul、rem 相关 cpu-tests", "检查 AM 平台 libgcc 源文件"],
          links: [["abstract-machine/am/src/riscv/npc/libgcc/div.S", 1, "RV32E 除法运行库"]]
        }
      ],
      answers: [
        ["什么是 snpc 与 dnpc？", "snpc 是顺序下一条 PC，通常为 pc+4；dnpc 是本条指令实际执行后选择的下一 PC。分支、跳转、异常会修改 dnpc。"],
        ["为什么 jalr 目标地址要清零 bit 0？", "RISC-V 将最低位保留为对齐/标记用途；JALR 的目标地址定义为 (rs1+imm) & ~1。"],
        ["NEMU 与 RTL NPC 的根本区别？", "NEMU 直接按软件顺序更新 ISA 状态；RTL 必须在时钟、组合路径、流水寄存器和总线握手约束下实现同样语义。"]
      ]
    },
    {
      id: "c2",
      short: "C2",
      title: "用 RTL 实现最简单的处理器",
      subtitle: "从 PC、寄存器堆和 ALU 出发，重新建立电路而非 C 程序的思维。",
      official: "https://ysyx.oscc.cc/docs/2306/basic/1.2.html",
      overview: "必做核心是画出处理器、实现 addi，并建立仿真结束机制。当前代码采用流水线实现：DPI-C 用于 NPC-only 内存访问，ebreak 则在提交边界由 C++ monitor 判定并结束仿真。复习时直接沿当前 IFU、IDU、EXU、WBU 说明数据和控制路径。",
      tasks: [
        {
          id: "c2-addi",
          required: true,
          title: "用当前 RTL 画出 addi 数据通路",
          how: "画 IFU → if2id → IDU → id2ex → EXU → ls2wb → WBU 的实际数据流；标出 I 型立即数、rs1、rd、写使能、PC+4、前递和级间时钟边界。",
          why: "这是之后所有指令和流水线控制的最小基座。不能讲清 addi，就无法讲清前递、停顿或 DiffTest。",
          verify: ["make -C am-kernels/tests/cpu-tests ARCH=riscv32e-npc ALL=dummy run git_commit="],
          links: [
            ["npc/vsrc/IFU.sv", 38, "当前 PC、取指与 reset"],
            ["npc/vsrc/IDU.sv", 1, "译码与立即数"],
            ["npc/vsrc/EXU.sv", 1, "ALU 与控制流"],
            ["npc/vsrc/WBU.sv", 1, "写回与寄存器堆"],
            ["npc/vsrc/registerfile.sv", 1, "x0 与写读 bypass"],
            ["npc/vsrc/ysyx.sv", 195, "NPC-only DPI-C 内存接口"],
            ["npc/csrc/src/ram.cpp", 54, "pmem 读写与字节掩码"]
          ]
        },
        {
          id: "c2-ebreak",
          required: true,
          title: "解释 DPI-C 与 ebreak 结束机制",
          how: "追踪 WBU 的退休信息、Verilator 顶层、C++ 执行循环和 halt 判定；当前实现由 C++ 在提交边界识别 ebreak，DPI-C 主要服务于 NPC-only 内存读写，而不是直接回调 ebreak。",
          why: "以程序结束作为仿真结束条件，避免用固定周期数掩盖死循环或早停；放在提交边界也使流水线与顺序程序的结束语义一致。",
          verify: ["运行 dummy 或 cpu-test，观察 HIT GOOD TRAP / HIT BAD TRAP"],
          links: [["npc/vsrc/WBU.sv", 28, "提交级输出"], ["npc/csrc/src/cpu_exec.cpp", 191, "提交、ebreak 与仿真驱动"], ["npc/vsrc/ysyx.sv", 195, "DPI-C 内存接口"]]
        },
        {
          id: "c2-hdl",
          required: false,
          title: "选做：检查时序/组合边界",
          how: "挑出 PC、寄存器堆、流水寄存器三处状态元件，解释 reset、write enable 和组合默认值。",
          why: "锁存器、negedge 滥用和组合环路会在后续集成中变成难定位的硬件 bug。",
          verify: ["make -C npc -n npc git_commit= | head -n 60", "对照波形检查时钟沿前后数据变化"],
          links: [["npc/vsrc/pip_reg.sv", 1, "级间寄存器"], ["npc/vsrc/ysyx_24110011.sv", 1, "顶层连线"]]
        }
      ],
      answers: [
        ["为什么组合逻辑必须有默认赋值？", "否则综合器需要保持上一次值，会推导 latch；这通常违背组合逻辑的设计意图。"],
        ["为什么 x0 必须恒为 0？", "这是 RISC-V 架构状态的一部分；无论写入什么，读取 x0 都必须得到零。"],
        ["DPI-C 的边界是什么？", "RTL 负责描述电路信号和时序；C/C++ 负责仿真驱动、内存模型、日志、设备和结束判定。"]
      ]
    },
    {
      id: "c3",
      short: "C3",
      title: "运行时环境和基础设施",
      subtitle: "从一个 C 文件到处理器提交第一条指令，建立完整工具链与调试链。",
      official: "https://ysyx.oscc.cc/docs/2306/basic/1.3.html",
      overview: "这一章复习重点是 AM 的启动路径、镜像加载、链接脚本，以及 SDB、trace、DiffTest 各自解决的调试问题。",
      tasks: [
        {
          id: "c3-runtime",
          required: true,
          title: "走通 AM 运行时与镜像链路",
          how: "从应用 Makefile 沿 ARCH、AM_HOME、平台脚本追到 ELF/镜像；从 _start 追到 _trm_init、main 和 halt。",
          why: "处理器不是直接执行 C 源码。链接地址、复位 PC 和加载地址任何一个不一致，程序都无法正确开始。",
          verify: ["make -C am-kernels/kernels/yield-os ARCH=riscv32-nemu run git_commit=", "make -C am-kernels/kernels/yield-os ARCH=riscv32e-npc run git_commit="],
          links: [
            ["abstract-machine/am/src/riscv/npc/start.S", 1, "启动汇编"],
            ["abstract-machine/am/src/riscv/npc/trm.c", 1, "_trm_init 与 halt"],
            ["abstract-machine/scripts/riscv32e-npc.mk", 1, "ISA/ABI 选择"],
            ["abstract-machine/scripts/platform/npc.mk", 1, "平台运行入口"]
          ]
        },
        {
          id: "c3-tools",
          required: true,
          title: "掌握 SDB、Trace 与 DiffTest 的分工",
          how: "分别用单步、表达式、watchpoint、ITrace/MTrace 和 DiffTest 解决一次问题；记录每种工具的第一观察点。",
          why: "硬件调试的关键不是多看波形，而是先用成本最低的工具缩小错误范围。",
          verify: ["在 NPC SDB 中使用 si、info r、p、w、d", "开启 DiffTest 跑短程序"],
          links: [
            ["npc/csrc/src/sdb/sdb.cpp", 1, "SDB 命令"],
            ["npc/csrc/src/sdb/expr.cpp", 419, "表达式求值"],
            ["npc/csrc/src/sdb/watchpoint.cpp", 1, "监视点"],
            ["npc/csrc/src/sdb/trace.cpp", 1, "ITrace/MTrace/FTrace"],
            ["npc/csrc/src/difftest/difftest.cpp", 1, "差分测试"]
          ]
        }
      ],
      answers: [
        ["_start、_trm_init 与 main 的关系？", "_start 做最低层初始化并进入 C 运行时；_trm_init 初始化 AM 环境后调用 main；main 返回后由 halt 报告程序结果。"],
        ["什么时候优先看 DiffTest，什么时候优先看波形？", "先用 DiffTest 定位第一条架构不一致的指令；再用 ITrace/SDB 缩小范围；只有需要查看周期级握手、时序和流水状态时才进入波形。"],
        ["为什么链接地址重要？", "代码与数据的链接地址必须与镜像加载位置、PC 复位地址和存储器映射一致，否则取指或访问全局数据会落到错误地址。"]
      ]
    },
    {
      id: "c4",
      short: "C4",
      title: "支持 RV32E 的单周期 NPC",
      subtitle: "按官方 C4 能力复习；讲解与实操均使用当前五级流水线 NPC。",
      official: "https://ysyx.oscc.cc/docs/2306/basic/1.4.html",
      overview: "官方必做包括加载镜像、dummy/halt、SDB、trace、DiffTest、RV32E 指令集、MTrace 以及正确运行所有 cpu-tests。当前流水线版本仍必须保持同样的单指令架构语义。",
      tasks: [
        {
          id: "c4-isa",
          required: true,
          title: "逐类解释 RV32E 指令实现",
          how: "把 LUI/AUIPC、JAL/JALR、branch、load/store、OP-IMM、OP、SYSTEM 分成表格；每类写清数据源、立即数、ALU、写回和 dnpc。",
          why: "考核不会只问某一条指令；分类思维才能在随机抽题时快速回答。",
          verify: ["make -C am-kernels/tests/cpu-tests ARCH=riscv32e-npc run git_commit="],
          links: [["npc/vsrc/IDU.sv", 1, "指令识别和控制生成"], ["npc/vsrc/EXU.sv", 1, "执行与分支"], ["npc/vsrc/LSU.sv", 1, "访存语义"]]
        },
        {
          id: "c4-difftest",
          required: true,
          title: "按提交点理解 DiffTest",
          how: "读出 NPC 当前从 LS/WB 提交的 PC/指令，理解为何非普通内存访问需要 skip；用一个失败测试演练第一差异定位。",
          why: "流水线按周期前进，NEMU 按指令前进；比较必须在等价的架构提交点发生。",
          verify: ["make -C npc menuconfig", "开启 DiffTest 后运行短 cpu-test，并记录第一个差异的 PC、寄存器和 ITrace"],
          links: [["npc/csrc/src/cpu_exec.cpp", 191, "提交点与 skip"], ["npc/csrc/src/difftest/difftest.cpp", 22, "NPC DiffTest 动态接口"], ["nemu/src/cpu/difftest/ref.c", 21, "NEMU reference ABI"]]
        },
        {
          id: "c4-monitor",
          required: true,
          title: "讲清镜像加载、dummy 与 halt/ebreak",
          how: "从 monitor 的参数解析和镜像加载进入仿真主循环，说明复位 PC、DPI 内存、dummy 镜像与 ebreak 如何共同定义一次测试的开始和结束。",
          why: "CPU 通过测试不只是‘算对了’：必须从可预测的入口取指，并让程序显式报告 GOOD/BAD TRAP，才能排除固定周期数造成的假通过。",
          verify: ["make -C npc npc IMG=/绝对路径/镜像.bin git_commit=", "在 SDB 中运行短镜像，确认 GOOD TRAP / BAD TRAP 结论"],
          links: [["npc/csrc/src/monitor.cpp", 1, "镜像、参数与初始化"], ["npc/csrc/src/cpu_exec.cpp", 1, "主循环、提交与结束判定"], ["npc/vsrc/ysyx.sv", 1, "NPC-only 顶层与 DPI 内存"]]
        },
        {
          id: "c4-trace",
          required: true,
          title: "把 ITrace / MTrace 当作第一现场",
          how: "先读当前 .config，区分‘代码已实现’和‘本次构建已启用’；打开 trace 模块，练习用 PC、反汇编和访存地址定位第一处异常，而不是直接淹没在波形里。若使用 menuconfig，先保存 Git 状态：它会修改配置。",
          why: "C4 的 Trace 与 MTrace 是 DiffTest 之后最便宜的定位手段；可配置开关也考查你是否知道当前构建到底包含哪些调试功能。",
          verify: ["rg -n \"CONFIG_(ITRACE|MTRACE|DIFFTEST)\" npc/.config", "make -C npc menuconfig"],
          links: [["npc/.config", 1, "当前调试功能开关"], ["npc/csrc/src/sdb/trace.cpp", 1, "ITrace/MTrace/FTrace 实现"], ["npc/csrc/src/sdb/sdb.cpp", 1, "SDB 命令入口"]]
        },
        {
          id: "c4-rv32e",
          required: false,
          title: "选做：RV32E 与运行库的乘除法",
          how: "核对 16 个通用寄存器的选择，说明为什么不支持 M 扩展的核心仍能运行包含乘除的 C 程序。",
          why: "这是 ISA、编译器 ABI 和运行时库协同的经典考点。",
          verify: ["运行 mul/div cpu-tests", "检查 AM libgcc 的 muldi3/div 实现"],
          links: [["npc/vsrc/registerfile.sv", 1, "RVE/RVI 寄存器数"], ["abstract-machine/am/src/riscv/npc/libgcc/muldi3.S", 1, "软件乘法"]]
        },
        {
          id: "c4-synthesis",
          required: false,
          title: "选做：从 ALU 做综合/时序推理",
          how: "阅读 ALU 的加减、比较和移位路径，回答减法与比较能否共享加法器、移位会综合成什么结构、直接使用运算符还可如何优化。当前仓库没有维护好的 yosys-sta 一键目标，不要伪造‘已跑通’结论。",
          why: "功能正确不等于时序合理；这项练习能把 RTL 代码、综合电路和 B 阶段性能优化真正连接起来。",
          verify: ["rg -n \"module ALU|case\" npc/vsrc/ALU.sv", "在独立的 yosys-sta 环境完成分析并保存报告"],
          links: [["npc/vsrc/ALU.sv", 10, "当前 ALU 实现"], ["npc/vsrc/EXU.sv", 34, "ALU 在 EXU 中的使用"]]
        }
      ],
      answers: [
        ["RV32E 与 RV32I 的核心差异？", "RV32E 只提供 x0–x15 共16个通用寄存器，并使用 ilp32e ABI；指令语义主体仍是 RV32 基础整数指令。"],
        ["为什么 store 不写回寄存器？", "store 的架构效果是修改内存，rd 字段在 S 型编码中不存在；写回使能必须关闭。"],
        ["为何 DiffTest 要在提交而非每周期比较？", "流水线中不同指令会并行位于多个阶段，周期状态不等价；只有提交时的 ISA 状态才能与顺序参考模型一一对应。"]
      ]
    },
    {
      id: "c5",
      short: "C5",
      title: "设备和输入输出",
      subtitle: "把 MMIO、AM IOE 和宿主机设备模型串成一次完整的输入输出。",
      official: "https://ysyx.oscc.cc/docs/2306/basic/1.5.html",
      overview: "官方必做覆盖 NEMU I/O、NPC 串口和时钟，以及字符模式 FCEUX；VGA/图形版超级玛丽是重要选做。复习重点是 CPU 访问设备本质上仍是 load/store，只是地址落在设备映射区。",
      tasks: [
        {
          id: "c5-mmio",
          required: true,
          title: "追踪一次 MMIO 读写",
          how: "从 AM 的 io_read/io_write 进入 CPU load/store，再追到 paddr/MMIO map、设备回调和宿主机接口。选择 UART 写和 timer 读各做一次。",
          why: "MMIO 统一了处理器的访存接口，但设备的副作用让它不能和普通内存等价对待。",
          verify: ["make -C am-kernels/tests/am-tests ARCH=riscv32e-ysyxsoc mainargs=h run git_commit="],
          links: [
            ["nemu/src/device/io/map.c", 1, "NEMU I/O 映射"],
            ["nemu/src/device/io/mmio.c", 1, "MMIO 访问"],
            ["npc/csrc/src/device/mmio.c", 1, "NPC MMIO"],
            ["abstract-machine/am/src/riscv/ysyxsoc/ioe/uart.c", 1, "SoC 平台 AM UART"]
          ]
        },
        {
          id: "c5-device",
          required: true,
          title: "验证串口、时钟和输入设备路径",
          how: "观察串口字符写入、uptime 读取和键盘事件；说明哪个寄存器/地址触发哪个设备行为。当前 NPC-only 的 CONFIG_DEVICE 默认关闭：若要验证该模式，先在 menuconfig 启用设备并记录配置差异；NEMU/SoC 可先提供可见设备证据。",
          why: "设备驱动要求跨越 AM、NPC/NEMU C++、RTL 总线和宿主机库，是系统协同的典型题；明确配置边界能防止把未启用的功能误当作已验证。",
          verify: ["make -C npc menuconfig", "make -C am-kernels/tests/am-tests ARCH=riscv32e-npc mainargs=h run git_commit=", "make -C am-kernels/tests/am-tests ARCH=riscv32-nemu mainargs=t run git_commit=", "make -C fceux-am ARCH=riscv32e-npc run mainargs=mario git_commit="],
          links: [["npc/csrc/src/ram.cpp", 54, "NPC pmem/MMIO 分流"], ["npc/csrc/src/device/map.c", 34, "NPC MMIO 映射"], ["npc/csrc/src/device/serial.c", 7, "NPC 串口"], ["npc/csrc/src/device/timer.c", 10, "NPC 定时器"], ["npc/csrc/src/device/vag.c", 49, "NPC VGA（文件名 vag.c）"]]
        },
        {
          id: "c5-graphics",
          required: false,
          title: "跑通图形 / 输入综合实操（FCEUX）",
          how: "用当前 AM IOE 的 keyboard、gpu 与 timer 链路解释游戏模拟器如何把帧缓冲区、输入事件和时钟变成可见的运行结果；先确认 ROM、SDL/设备条件和目标平台。",
          why: "图形程序会同时压到 MMIO、定时器、键盘、VGA 与运行时，是 C5 所有设备能力的综合验收，而不是单独的‘能输出字符’。",
          verify: ["make -C fceux-am ARCH=riscv32-nemu run mainargs=mario git_commit=", "确认 nes/rom/mario.nes 存在，并记录画面、输入与串口第一现场"],
          links: [["fceux-am/Makefile", 1, "FCEUX 到 AM 的构建入口"], ["fceux-am/README.md", 16, "ROM 与运行参数"], ["abstract-machine/am/src/riscv/ysyxsoc/ioe/gpu.c", 1, "SoC GPU / framebuffer IOE"]]
        },
        {
          id: "c5-skip",
          required: false,
          title: "选做：解释 MMIO 的 DiffTest skip",
          how: "追踪 NPC 对非 pmem 访问打标记、在提交点 skip 并与参考模型重新同步的路径。",
          why: "设备读写具有外部副作用，参考模型与 DUT 不能简单重复执行同一次设备事务。",
          verify: ["开启 DiffTest 并运行含 UART/timer 的短程序"],
          links: [["npc/csrc/src/cpu_exec.cpp", 1, "MMIO DiffTest skip"]]
        }
      ],
      answers: [
        ["为什么 MMIO 可以复用 load/store？", "从 CPU 看它们都是地址读写；地址译码把某些区间路由到设备回调而非普通 RAM。"],
        ["为什么串口常只使用低 8 位？", "UART 通常以字节为单位传输字符；写 strobe 和地址低位决定有效字节。"],
        ["为什么设备访问要谨慎 DiffTest？", "设备读可能随时间变化，写会有副作用；让参考模型再次执行可能得到不同结果或重复副作用。"]
      ]
    },
    {
      id: "c6",
      short: "C6",
      title: "异常处理和 RT-Thread",
      subtitle: "从 ecall、CSR、trap frame 到上下文切换，完成软件系统落地。",
      official: "https://ysyx.oscc.cc/docs/2306/basic/1.6.html",
      overview: "官方必做是 NEMU 自陷、在 NEMU/NPC 上运行 RT-Thread，以及定位最后命令提示符不输出的问题。这里的关键是区分 ISA 异常、AM CTE 和 RTOS 调度。",
      tasks: [
        {
          id: "c6-trap",
          required: true,
          title: "闭环 ecall → trap → mret",
          how: "写出 mcause/mepc/mtvec 的更新顺序；读 trap.S 的保存恢复顺序；追踪 CTE handler 如何返回 Context。",
          why: "异常是硬件、汇编、C 运行时和操作系统真正交汇的地方，最能检验整体理解。",
          verify: ["make -C am-kernels/kernels/yield-os ARCH=riscv32-nemu run git_commit=", "make -C am-kernels/kernels/yield-os ARCH=riscv32e-npc run git_commit="],
          links: [
            ["nemu/src/isa/riscv32/system/intr.c", 1, "NEMU 异常状态"],
            ["abstract-machine/am/src/riscv/npc/trap.S", 1, "上下文保存恢复"],
            ["abstract-machine/am/src/riscv/npc/cte.c", 1, "AM 事件分发"],
            ["npc/vsrc/CSR.sv", 22, "NPC CSR"],
            ["npc/vsrc/WBU.sv", 33, "提交点异常重定向"],
            ["am-kernels/kernels/yield-os/yield-os.c", 12, "yield 协作切换样例"]
          ]
        },
        {
          id: "c6-rtt",
          required: true,
          title: "在当前 SoC/NPC 链路上运行 RT-Thread 并定位启动问题",
          how: "从 RT-Thread BSP 的 Makefile、AM 应用整合和启动配置走到 shell；检查最后提示符、串口和上下文切换。",
          why: "能运行 RT-Thread 证明异常、定时器、串口、运行时和处理器提交语义同时正确。",
          verify: ["make -C RT-Thread/bsp/abstract-machine ARCH=riscv32-nemu run git_commit=", "make -C RT-Thread/bsp/abstract-machine ARCH=riscv32e-npc run git_commit=", "make -C RT-Thread/bsp/abstract-machine ARCH=riscv32e-ysyxsoc run git_commit="],
          links: [["RT-Thread/bsp/abstract-machine/Makefile", 1, "RT-Thread AM BSP"], ["RT-Thread/bsp/abstract-machine/src/context.c", 11, "AM / RT-Thread Context 桥接"], ["RT-Thread/bsp/abstract-machine/src/uart.c", 34, "RT-Thread UART 路径"], ["npc/vsrc/WBU.sv", 33, "ecall/mret 提交重定向"]]
        },
        {
          id: "c6-prompt",
          required: false,
          title: "选做：复盘最后命令提示符不输出",
          how: "按“应用/RT-Thread → AM UART → MMIO → NPC device → host stdout”分层，先确认字符是否发出，再定位卡在何处。",
          why: "这道题不是只考串口；它考查如何用分层证据缩小复杂系统问题。",
          verify: ["运行 RT-Thread，记录最后一条 ITrace、MTrace 与 UART 输出", "必要时对 UART 地址加 watchpoint/trace"],
          links: [["abstract-machine/am/src/riscv/npc/trm.c", 16, "NPC AM putch / 串口端口"], ["abstract-machine/am/src/riscv/ysyxsoc/ioe/uart.c", 1, "SoC AM UART 驱动"], ["npc/csrc/src/device/serial.c", 7, "仿真端串口"]]
        }
      ],
      answers: [
        ["mcause、mepc、mtvec 分别是什么？", "mcause 记录异常原因，mepc 保存返回地址，mtvec 保存异常入口；ecall 将控制流转入 mtvec，mret 从 mepc 恢复。"],
        ["为什么 trap frame 要保存大量寄存器？", "异常处理和调度器可能破坏调用者现场；要能恢复被中断线程的完整架构状态。"],
        ["yield 与普通函数调用有什么不同？", "yield 经由 ecall 进入异常路径，调度器可选择不同 Context；mret 返回的寄存器与 PC 不一定属于原调用者。"]
      ]
    }
  ];

  const weeklyPlan = [
    ["1", "C1 · NEMU", "RV32IM、立即数、dnpc、RV32M；跑 NEMU cpu-tests。", "7–8h"],
    ["2", "C2 · 最简 RTL", "画 addi 数据通路，追 DPI-C/ebreak，复盘时序与组合边界。", "7h"],
    ["3", "C3 · AM/工具", "从 C 源码到镜像到提交；SDB、Trace、DiffTest 实操。", "7h"],
    ["4", "C4 · RV32E NPC", "指令分类、单指令语义、DiffTest、全量 cpu-tests。", "8h"],
    ["5", "C5 · 设备 I/O", "MMIO、UART、timer、keyboard、VGA 与 AM IOE。", "7h"],
    ["6", "C6 · 异常/RTT", "ecall/CSR/trap/mret；yield-os 与 RT-Thread。", "8h"],
    ["7", "模拟考核 + B", "闭卷讲图、综合验证；快速串联总线、SoC、cache、流水线。", "8h"]
  ];

  const commandGroups = [
    {
      title: "开始前：环境与工作区",
      description: "AM 构建依赖环境变量；NPC 的仿真 Makefile 会包含根目录 tracer 逻辑。页面中的运行命令都带 git_commit= 以覆盖它，仍应先确认路径和 Git 状态。",
      commands: [
        ["export NEMU_HOME={ROOT}/nemu AM_HOME={ROOT}/abstract-machine NPC_HOME={ROOT}/npc NVBOARD_HOME={ROOT}/nvboard", "设置当前终端所需路径", "只影响当前 shell"],
        ["git status --short --branch", "只读检查当前分支和未提交改动", "安全"],
        ["make -C npc -n npc git_commit= | head -n 60", "只预览 NPC-only 调用链", "安全：不执行构建"]
      ]
    },
    {
      title: "C1 / NEMU 指令语义",
      description: "先用参考模型确认 ISA 语义，再用 NPC 看硬件是否等价。",
      commands: [
        ["make -C am-kernels/tests/cpu-tests ARCH=riscv32-nemu run git_commit=", "运行 NEMU CPU tests", "会生成构建产物与 NEMU 日志"],
        ["make -C nemu git_commit=", "按当前 NEMU 配置构建", "会写 nemu/build/，抑制 tracer 提交"]
      ]
    },
    {
      title: "C4 / NPC CPU tests",
      description: "cpu-tests 是 RV32E 核心最重要的回归基线。失败时优先找第一个差异。",
      commands: [
        ["make -C am-kernels/tests/cpu-tests ARCH=riscv32e-npc run git_commit=", "编译并逐项运行 RV32E NPC cpu-tests", "会写构建产物；已抑制 tracer 提交"],
        ["make -C npc npc IMG=/绝对路径/镜像.bin git_commit=", "NPC-only 仿真指定镜像", "会写 build/；已抑制 tracer 提交"],
        ["make -C npc run IMG=/绝对路径/镜像.bin git_commit=", "SoC 顶层仿真指定镜像", "会写 build/；已抑制 tracer 提交"]
      ]
    },
    {
      title: "C5 / C6 系统程序",
      description: "使用短程序验证异常、设备和系统运行时，再挑战 RT-Thread。",
      commands: [
        ["make -C am-kernels/tests/am-tests ARCH=riscv32e-ysyxsoc mainargs=h run git_commit=", "AM、SoC、IOE 与设备链路", "重型验证；可能打开窗口"],
        ["make -C am-kernels/kernels/yield-os ARCH=riscv32e-npc run git_commit=", "异常与上下文切换的快速 NPC-only 验证", "会写构建产物；已抑制 tracer 提交"],
        ["make -C am-kernels/kernels/yield-os ARCH=riscv32e-ysyxsoc run git_commit=", "异常与上下文切换的 SoC 联调", "重型验证；已抑制 tracer 提交"],
        ["make -C RT-Thread/bsp/abstract-machine ARCH=riscv32e-ysyxsoc run git_commit=", "RT-Thread on AM/ysyxSoC", "需要现有 RT-Thread BSP 配置"]
      ]
    },
    {
      title: "B阶段快速回归",
      description: "B阶段只用于串联当前实现：流水线、cache、总线和 SoC。",
      commands: [
        ["make -C npc -n run git_commit= | head -n 80", "只打印 SoC 仿真命令", "安全：不执行构建"],
        ["make -C npc/cachesim all", "构建离线 cache 分析器", "会写该子目录的构建产物"],
        ["make -C npc/branchsim all", "构建离线分支预测分析器", "会写该子目录的构建产物"]
      ]
    }
  ];

  const quizBank = [
    ["C1", "snpc 与 dnpc 的正确关系是？", ["snpc 是异常入口，dnpc 是返回地址", "snpc 是顺序下一 PC，dnpc 是实际下一 PC", "两者始终相等", "snpc 只用于 JALR"], 1, "分支、跳转和异常通过修改 dnpc 改变控制流。"],
    ["C1", "JALR 计算目标地址时必须做什么？", ["目标左移两位", "清零 bit 0", "清零低两位", "加上 pc"], 1, "JALR 目标为 (rs1 + imm) & ~1。"],
    ["C1", "为何 B-type 立即数需要特殊拼接？", ["它没有立即数", "编码位分散且分支偏移按 2 字节对齐", "只能表示正数", "它来自 rs2"], 1, "B 型立即数分散在多个字段，并在最低位补 0。"],
    ["C1", "NEMU 最适合作为什么？", ["周期精确时序模型", "ISA 语义参考模型", "综合工具", "AXI 从设备"], 1, "NEMU 是顺序执行的 ISA 状态机，是 DiffTest 的语义参照。"],
    ["C2", "组合逻辑未在所有路径赋值的典型后果是？", ["自动产生更快的寄存器", "推导 latch", "自动清零", "阻止综合"], 1, "组合逻辑需要默认赋值，避免工具推导不期望的锁存器。"],
    ["C2", "x0 写入后应当如何？", ["保持写入值", "下一周期随机", "读出始终为 0", "触发异常"], 2, "x0 是 RISC-V 恒零寄存器。"],
    ["C2", "为什么 ebreak 适合决定仿真结束？", ["能让程序显式报告结束与结果", "它比时钟快", "它不需要 C++", "它会清空内存"], 0, "固定运行周期会掩盖死循环或过早停止；ebreak 把结束权交给程序。"],
    ["C2", "当前代码中，ebreak 的 Good/Bad Trap 判定发生在哪里？", ["IFU 在取指时直接 DPI-C 回调", "IDU 在译码时写 GPIO", "C++ 在退休边界观察到已提交 ebreak 后调用 halt", "CSR 模块自动停止时钟"], 2, "当前 cpu_exec.cpp 在 ls2wb_valid 的提交路径中读取已退休指令，识别 ebreak 后由 C++ halt 输出 Good/Bad Trap；DPI-C 主要用于 NPC-only 内存。"],
    ["C3", "AM 启动链中，通常由谁调用 main？", ["Verilator", "_trm_init", "WBU", "NEMU 的 sdb"], 1, "_start 初始化后进入 _trm_init，由其调用 main 并在返回时 halt。"],
    ["C3", "定位第一条 ISA 差异时，优先使用什么？", ["先看百万周期波形", "DiffTest 与 ITrace", "直接改 RTL", "先删 cache"], 1, "先利用 DiffTest 定位首个不一致提交，再逐层降低观察成本。"],
    ["C3", "链接地址必须与什么保持一致？", ["显示器分辨率", "镜像加载地址、复位 PC 和存储器映射", "Git 分支名", "host CPU 架构"], 1, "地址不一致会导致取指、全局数据和栈访问落到错误位置。"],
    ["C4", "为什么 DiffTest 应在提交点比较？", ["RTL 每周期只执行一条", "流水线周期状态不等价，提交 ISA 状态才等价", "NEMU 没有 PC", "只能比较 store"], 1, "流水线中多条指令并行，只有退休提交时可与顺序模型一一对应。"],
    ["C4", "RV32E 的 GPR 数量是？", ["8", "16", "24", "32"], 1, "RV32E 使用 x0–x15，共 16 个通用寄存器。"],
    ["C4", "store 指令为什么不写回 GPR？", ["没有 rd，架构效果是写内存", "写回太慢", "它只能写 x0", "会由 PC 写回"], 0, "S 型指令没有 rd 字段，写回使能应关闭。"],
    ["C4", "slt 与 sltu 的差别是？", ["立即数宽度", "比较时是否按有符号解释", "是否写回", "是否访问内存"], 1, "slt 是 signed 比较，sltu 是 unsigned 比较。"],
    ["C4", "当前 npc/.config 中 DiffTest、ITrace 和 MTrace 的状态是？", ["默认全部开启", "默认全部关闭，需要先改配置", "只开启 MTrace", "只在 SoC 模式开启"], 1, "当前配置启用 RVE/性能计数/FAST_FLASH，但 DiffTest、ITrace、MTrace、设备和波形默认均关闭。"],
    ["C5", "MMIO 对 CPU 来说本质上是什么？", ["专用指令", "地址落入设备映射区的普通 load/store", "中断", "文件系统调用"], 1, "CPU 复用访存接口，地址译码将请求转给设备回调。"],
    ["C5", "为什么设备访问常需要 DiffTest skip？", ["设备没有地址", "设备读写有时间/外部副作用，REF 重放可能不等价", "DiffTest 不支持 load", "只为提升性能"], 1, "参考模型再次执行相同设备事务可能读到不同时间或产生重复副作用。"],
    ["C5", "UART 字符输出通常关注哪部分数据？", ["最高 8 位", "最低有效字节", "整个 128 位字", "只有地址"], 1, "串口通常按字节发送，写 strobe 决定哪一个字节有效。"],
    ["C5", "为什么不能把当前 NPC-only 的设备测试直接当成开箱可用？", ["NPC 没有 CPU", "当前 CONFIG_DEVICE 默认关闭", "UART 不支持字节写", "AM 不支持 IOE"], 1, "当前 .config 中 CONFIG_DEVICE 未启用；要验证 NPC-only MMIO 需先通过 menuconfig 改配置并重建，或使用 NEMU/SoC 路径。"],
    ["C6", "ecall 后 mtvec 的作用是？", ["保存栈顶", "提供异常处理入口", "保存返回值", "配置 UART"], 1, "ecall 保存异常信息后跳转到 mtvec 指向的入口。"],
    ["C6", "mepc 记录什么？", ["异常原因", "异常返回地址", "设备地址", "栈大小"], 1, "mepc 是 mret 恢复控制流的重要来源。"],
    ["C6", "yield 为什么可能切换到另一个线程？", ["它只是普通 C 函数", "它通过异常进入调度器，调度器可返回不同 Context", "它清零寄存器", "它让 ALU 停止"], 1, "yield 经 ecall 进入异常/调度路径，mret 可恢复任意被调度 Context。"],
    ["B1", "AXI valid/ready 的传输何时发生？", ["valid 为 1 即发生", "ready 为 1 即发生", "valid 与 ready 同时为 1", "时钟为 0"], 2, "AXI 每个通道在 valid && ready 的握手周期完成一次传输。"],
    ["B2", "SoC 集成时，CPU 与外设通常通过什么区分目标？", ["模块名", "地址映射/交叉开关", "Git 提交号", "编译器选项"], 1, "地址译码和互连决定请求被路由到 SRAM、UART、CLINT 等目标。"],
    ["B3", "cache miss 后最关键的控制是？", ["立即接受所有新请求", "保存未完成请求并等待 refill", "停止时钟", "清零寄存器堆"], 1, "阻塞式 cache 必须保留 miss 地址/上下文，在 refill 后正确返回或丢弃。"],
    ["B3", "fence.i 的主要目的？", ["刷新所有 GPR", "保证后续取指看到此前 store 修改的指令", "关闭总线", "设置 mtvec"], 1, "fence.i 需要 I-Cache 失效并冲刷潜在的过时前端指令。"],
    ["B3", "当前硬件 I-Cache 的实际组织是？", ["16 KiB、4-way", "4 行 × 16 B、直接映射", "仅有软件 CacheSim", "32 行 × 64 B、全相联"], 1, "IFU 当前实例化的硬件 I-Cache 为 4 行、每行 16 B 的 direct-mapped 缓存；npc/cachesim 是离线工具。"],
    ["B4", "load-use 冒险为何常需停顿？", ["load 结果在 EX 当拍已经可用", "数据在后续访存/写回阶段才真正返回", "寄存器堆不能读", "PC 不能加 4"], 1, "与普通 ALU 结果不同，load 数据晚到，前递源可能尚未准备好。"],
    ["B4", "分支预测错误的核心恢复动作？", ["只改 BHT", "冲刷流水线中年轻指令并重定向 PC", "清零内存", "跳过 DiffTest"], 1, "错误路径上的年轻指令不能提交，必须 flush 并从正确 PC 重新取指。"],
    ["PPT", "讲 NPC 微架构图时最应首先说明什么？", ["配色方案", "五级数据流、级间寄存器与控制/反馈路径", "所有模块代码行数", "Git 远端地址"], 1, "先建立数据主线，再说明 hazard、forwarding、redirect、cache 与总线等交叉控制。"],
    ["PPT", "Makefile 调用时序图中应包含哪条主链？", ["浏览器→CSS", "AM 应用→AM Makefile→平台 mk→npc Makefile→Verilator→仿真可执行文件", "NEMU→数据库", "VGA→键盘"], 1, "这是从用户程序到硬件仿真的可复现路径。"],
    ["PPT", "为什么网页的运行命令末尾统一带 git_commit=？", ["提高 Verilator 性能", "覆盖根 Makefile 的 tracer 提交宏，避免复习运行自动创建 tracer 提交", "自动打开波形", "切换 RV32E 到 RV32IM"], 1, "命令行变量会覆盖同名 Make 宏；保留 git_commit= 可抑制 tracer Git 记录，但构建产物和日志仍会写入工作区。"]
  ].map(([chapter, question, options, answer, explanation], index) => ({ id: `q${index + 1}`, chapter, question, options, answer, explanation }));

  const state = {
    view: "overview",
    completed: new Set(JSON.parse(localStorage.getItem(PROGRESS_KEY) || "[]")),
    quiz: JSON.parse(localStorage.getItem(QUIZ_KEY) || "null") || null,
    quizFilter: "all",
    timerId: null
  };

  workspaceInput.value = localStorage.getItem(ROOT_KEY) || DEFAULT_ROOT;
  const queryDistro = new URLSearchParams(window.location.search).get("wslDistro");
  wslDistroInput.value = queryDistro || localStorage.getItem(WSL_DISTRO_KEY) || "Ubuntu";
  if (queryDistro) localStorage.setItem(WSL_DISTRO_KEY, queryDistro);

  function escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function getRoot() {
    return workspaceInput.value.trim().replace(/\/+$/, "") || DEFAULT_ROOT;
  }

  function getWslDistro() {
    return wslDistroInput.value.trim() || "Ubuntu";
  }

  function formatCommand(command) {
    return command.replaceAll("{ROOT}", getRoot());
  }

  function vscodeHref(path, line) {
    const absolute = `${getRoot()}/${path}`.replaceAll("//", "/");
    const escapedPath = absolute.split("/").map(encodeURIComponent).join("/");
    return `vscode://vscode-remote/wsl+${encodeURIComponent(getWslDistro())}${escapedPath}${line ? `:${line}` : ""}`;
  }

  function codeLinks(links) {
    return `<div class="code-link-grid">${links.map(([path, line, label]) => `
      <a class="code-link" href="${vscodeHref(path, line)}" title="在 Windows VS Code 的 WSL Remote 中打开 ${escapeHtml(path)}">
        <span>${escapeHtml(label || path)}</span><em>${escapeHtml(path)}${line ? `:${line}` : ""}</em>
      </a>`).join("")}</div>`;
  }

  function commandCards(commands) {
    return `<div class="command-list">${commands.map(command => `
      <div class="command-card"><code>${escapeHtml(formatCommand(command))}</code><button class="command-button" type="button" data-copy="${escapeHtml(formatCommand(command))}">复制</button></div>`).join("")}</div>`;
  }

  function showToast(message) {
    toast.textContent = message;
    toast.classList.add("show");
    window.clearTimeout(showToast.timeout);
    showToast.timeout = window.setTimeout(() => toast.classList.remove("show"), 2200);
  }

  function allTasks() {
    return chapters.flatMap(chapter => chapter.tasks);
  }

  function updateProgress() {
    const tasks = allTasks();
    const percent = tasks.length ? Math.round((state.completed.size / tasks.length) * 100) : 0;
    document.querySelector("#sidebar-progress").textContent = `${percent}%`;
    document.querySelector("#sidebar-progress-bar").style.width = `${percent}%`;
    localStorage.setItem(PROGRESS_KEY, JSON.stringify([...state.completed]));
  }

  function setTopbar(kicker, title) {
    document.querySelector("#view-kicker").textContent = kicker;
    document.querySelector("#view-title").textContent = title;
  }

  function taskCard(task, chapter) {
    const done = state.completed.has(task.id);
    return `<article class="task-card ${task.required ? "" : "optional"}">
      <div class="task-card-header">
        <div><h4>${escapeHtml(task.title)}</h4><p>${escapeHtml(task.how)}</p></div>
        <label title="标记为已复习"><input class="task-done" type="checkbox" data-task-id="${task.id}" ${done ? "checked" : ""}/></label>
      </div>
      <div class="why-box"><strong>为什么要这样做</strong>${escapeHtml(task.why)}</div>
      <div class="command-list">${task.verify.map(command => `<div class="command-card"><code>${escapeHtml(formatCommand(command))}</code><button class="command-button" type="button" data-copy="${escapeHtml(formatCommand(command))}">复制</button></div>`).join("")}</div>
      ${codeLinks(task.links)}
      <span class="task-tag ${task.required ? "" : "optional"}">${task.required ? "必做" : "重要选做"}</span>
    </article>`;
  }

  function answerCards(answers) {
    return `<div class="bento cols-3">${answers.map(([question, answer]) => `
      <article class="card"><p class="eyebrow">考官可能会问</p><h3>${escapeHtml(question)}</h3><div class="answer-box"><strong>建议答案</strong>${escapeHtml(answer)}</div></article>`).join("")}</div>`;
  }

  function renderOverview() {
    setTopbar("C1–C6 · 考核导向复习", "把代码重新变成你能讲清楚的系统");
    const completed = state.completed.size;
    app.innerHTML = `
      <section class="hero">
        <div class="hero-grid">
          <div>
            <p class="eyebrow">ONE WEEK · C-STAGE REBUILD</p>
            <h2>不是再看一遍代码。<br/>是重新获得能设计、调试、答辩的掌控感。</h2>
            <p>以现在的代码为唯一事实来源，把 C1–C6 的必做能力映射到当前实现。每个任务都给出：当前实现在哪里、为什么这样实现、怎样验证、考官会怎样追问。</p>
            <div class="hero-actions">
              <button class="primary-button" type="button" data-view="chapters">从 C1 开始复习</button>
              <button class="secondary-button" type="button" data-view="quiz">进入模拟考核</button>
              <button class="secondary-button" type="button" data-view="architecture">先看三张架构图</button>
            </div>
          </div>
          <div class="hero-stats">
            <div class="metric"><strong>6</strong><span>C阶段主线<br/>C1–C6</span></div>
            <div class="metric"><strong>${allTasks().filter(task => task.required).length}</strong><span>必做复习任务<br/>可勾选追踪</span></div>
            <div class="metric"><strong>${quizBank.length}</strong><span>带答案的<br/>模拟题</span></div>
            <div class="metric"><strong>${completed}</strong><span>你已标记完成<br/>本机保存</span></div>
          </div>
        </div>
      </section>

      <div class="section-heading"><div><p class="eyebrow">复习方法</p><h2>每天都要留下四份证据</h2><p>阅读只占一部分。每一日结束前，必须有一张图、一条代码链、一次可复现验证和一段闭卷口述。</p></div></div>
      <section class="bento cols-2">
        <article class="card accent-cyan"><div class="card-icon">01</div><h3>先闭卷画图</h3><p>先画 ISA 状态、数据通路或异常路径，再打开代码校正。能画出因果关系，才算真正恢复记忆。</p></article>
        <article class="card accent-purple"><div class="card-icon">02</div><h3>沿当前代码追链路</h3><p>通过 VS Code 链接直接理解当前实现如何覆盖 C 阶段知识点与后续系统能力。</p></article>
        <article class="card accent-gold"><div class="card-icon">03</div><h3>运行最小验证</h3><p>先短程序，再 cpu-tests、yield-os、RT-Thread。失败时永远找“第一条不一致”，不从最后的报错倒推。</p></article>
        <article class="card accent-pink"><div class="card-icon">04</div><h3>强制口述答案</h3><p>把“我知道”变成一分钟能讲清楚的因果链。模拟题答案可直接当作答辩骨架。</p></article>
      </section>

      <div class="section-heading"><div><p class="eyebrow">七天冲刺</p><h2>按依赖关系而非讲义顺序机械堆砌</h2><p>每天约 7–8 小时；前六天重建 C 阶段，最后一天综合演练并轻量串联 B 阶段。</p></div></div>
      <section class="day-plan">${weeklyPlan.map(([day, title, description, hours]) => `
        <article class="day-row"><span class="day-index">D${day}</span><div><h3>${title}</h3><p>${description}</p></div><span class="day-hours">${hours}</span></article>`).join("")}</section>

      <div class="section-heading"><div><p class="eyebrow">建议的每日节奏</p><h2>用输出驱动输入</h2></div></div>
      <section class="bento cols-3">
        <article class="card"><h3>09:00–12:00</h3><p>闭卷回忆 + 讲义必做题。先写状态和图，后查答案。</p></article>
        <article class="card"><h3>14:00–18:00</h3><p>VS Code 跟读 + 小范围验证。一次只解决一个链路。</p></article>
        <article class="card"><h3>19:30–21:00</h3><p>答辩式口述 + 模拟题 + 记录当天唯一未解问题。</p></article>
      </section>`;
  }

  function renderChapters() {
    setTopbar("C1–C6 · 代码、原因、验证、答案", "从任务清单进入当前实现");
    app.innerHTML = `
      <div class="section-heading"><div><p class="eyebrow">课程主线</p><h2>C阶段知识库</h2><p>每张任务卡可保存本机进度。文件卡会跳转到当前工作区中的实现；若 VS Code 未响应，可复制显示的路径和行号。</p></div><button class="secondary-button" type="button" data-view="quiz">用题库检验</button></div>
      <section class="bento cols-3">
        <article class="card"><p class="eyebrow">C1 必做范围</p><h3>RV32IM NEMU / PA2 阶段 1</h3><p>指令格式、立即数、dnpc、x0、访存与 cpu-tests。当前 NPC 是 RV32E；这一章以当前 NEMU 作为 RV32IM 的真实代码依据。</p></article>
        <article class="card"><p class="eyebrow">C2 必做范围</p><h3>最简处理器与结束机制</h3><p>PC、GPR、addi、复位、存储器边界、ebreak/Good Trap。当前代码用五级流水实现相同架构语义，DPI-C 用于 NPC-only 内存。</p></article>
        <article class="card"><p class="eyebrow">C3 必做范围</p><h3>运行时与基础设施</h3><p>AM 启动、链接、ELF/BIN、SDB、表达式、监视点和 Trace；重点是从一个 C 程序走到第一条提交指令。</p></article>
        <article class="card"><p class="eyebrow">C4 必做范围</p><h3>RV32E NPC 验证闭环</h3><p>dummy、镜像加载、指令/访存、SDB、ITrace/MTrace、DiffTest、全部 cpu-tests；当前配置开关会决定哪些工具可直接使用。</p></article>
        <article class="card"><p class="eyebrow">C5 必做 / 选做</p><h3>MMIO、串口、时钟、FCEUX</h3><p>必做是 NEMU I/O、NPC 设备基础与字符模式；VGA/图形 FCEUX 是重要选做。NPC-only 设备当前默认关闭，页面已标出启用路径。</p></article>
        <article class="card"><p class="eyebrow">C6 必做 / 选做</p><h3>异常、CTE 与 RT-Thread</h3><p>ecall、CSR、mret、trap frame、NEMU/NPC 上启动 RT-Thread；最后一个 <code>msh /&gt;</code> 不输出属于重要排障选做。</p></article>
      </section>
      <section class="chapter-list">
        ${chapters.map((chapter, index) => `<details class="chapter-card" ${index === 0 ? "open" : ""}>
          <summary><div class="chapter-title"><span class="chapter-badge">${chapter.short}</span><div><h3>${chapter.title}</h3><p>${chapter.subtitle}</p></div></div><span class="chapter-toggle">＋</span></summary>
          <div class="chapter-body">
            <p class="chapter-overview">${chapter.overview} <a class="inline-link" href="${chapter.official}" target="_blank" rel="noreferrer">打开官方讲义 ↗</a></p>
            <div class="task-grid">${chapter.tasks.map(task => taskCard(task, chapter)).join("")}</div>
            <div class="section-heading"><div><p class="eyebrow">口述答案卡</p><h2>${chapter.short} 常见追问</h2></div></div>
            ${answerCards(chapter.answers)}
          </div>
        </details>`).join("")}
      </section>`;
  }

  function renderArchitecture() {
    setTopbar("三张核心图 · 当前工作树为准", "把系统、流水线与构建链画成可口述的因果关系");
    app.innerHTML = `
      <div class="section-heading"><div><p class="eyebrow">PPT / 答辩核心</p><h2>三张图，覆盖从程序到提交、从 RTL 到仿真</h2><p>图中只描述当前 <code>npc/vsrc</code> 的五级流水线和当前构建链。先闭卷重画，再沿每张图下方的 VS Code 链接核验。</p></div></div>
      <div class="warning-box"><strong>当前实现边界</strong>当前配置启用 RV32E 和性能计数；DiffTest、设备模型、各类 Trace 与波形默认关闭。硬件 I-Cache 是 4 行 × 16 B 的直接映射缓存；<code>npc/cachesim</code> 是离线分析器，不是当前 RTL 中的 D-Cache。</div>
      <div class="diagram-tabs" role="tablist" aria-label="架构图选择">
        <button class="chip-button active" type="button" data-diagram-tab="project">01 · 一生一芯项目架构</button>
        <button class="chip-button" type="button" data-diagram-tab="pipeline">02 · NPC 微架构</button>
        <button class="chip-button" type="button" data-diagram-tab="makeflow">03 · Makefile 调用时序</button>
      </div>

      <section class="diagram-panel" data-diagram-panel="project">
        <p class="eyebrow">01 · FROM C PROGRAM TO DUT</p>
        <div class="arch-grid" aria-label="一生一芯项目总体架构图">
          <div class="arch-column">
            <article class="arch-node"><h4>AM 应用 / am-kernels</h4><p>cpu-tests、am-tests、yield-os 与基准程序；它们是交叉编译后真正运行在被测 CPU 上的软件。</p></article>
            <article class="arch-node purple"><h4>RT-Thread BSP</h4><p>通过 AM BSP 构建，检验异常、定时器、串口与上下文切换是否同时成立。</p></article>
          </div>
          <div class="arch-arrow">→<small>ARCH +<br/>平台规则</small></div>
          <div class="arch-column">
            <article class="arch-node"><h4>AbstractMachine</h4><p>启动代码、运行时、CTE、IOE、链接脚本与平台 Makefile；把应用变成 ELF / BIN。</p></article>
            <article class="arch-node"><h4>NEMU / libnemu.so</h4><p>软件 ISA 参考模型、MMIO、SDB、Trace；可作为 NPC DiffTest 的 reference。</p></article>
            <article class="arch-node warning"><h4>离线分析器</h4><p>CacheSim / BranchSim 消费 NEMU Trace 做分析；不要把它误画成当前 RTL 的 D-Cache。</p></article>
          </div>
          <div class="arch-arrow">→<small>BIN / ELF<br/>镜像 + 符号</small></div>
          <div class="arch-column">
            <article class="arch-node"><h4>NPC + Verilator</h4><p>C++ monitor 加载镜像并驱动 Verilator；提交时可与 NEMU 比较架构状态。</p></article>
            <article class="arch-node purple"><h4>当前 CPU: ysyx_24110011</h4><p>IFU → IDU → EXU → LSU → WBU；BPU、I-Cache、AXI 仲裁、CSR 与流水控制都在 <code>npc/vsrc</code>。</p></article>
            <article class="arch-node"><h4>ysyxSoC / 外设</h4><p>AXI/APB 连接 Flash、SDRAM、SRAM、UART、GPIO、PS/2、VGA 与 SPI 等；SoC 模式复位从 Flash 取指。</p></article>
          </div>
        </div>
        <p class="diagram-caption">口述顺序：应用依赖 AM 生成镜像；NEMU 提供 ISA 参考；NPC 用 Verilator 把 RTL + C++ 仿真环境变成可执行文件；SoC 模式再把 CPU 接进真实地址映射与外设网络。<strong>不要混淆“软件参考模型”“离线分析器”“真实 RTL 数据通路”。</strong></p>
        ${codeLinks([
          ["abstract-machine/Makefile", 27, "AM 构建入口与 ARCH 解析"],
          ["nemu/src/isa/riscv32/inst.c", 57, "NEMU RV32 指令语义"],
          ["npc/Makefile", 56, "NPC 收集当前 vsrc 与 C++"],
          ["ysyxSoC/src/SoC.scala", 26, "SoC 地址映射与互连"]
        ])}
      </section>

      <section class="diagram-panel hidden" data-diagram-panel="pipeline">
        <p class="eyebrow">02 · CURRENT NPC MICRORARCHITECTURE</p>
        <div class="pipeline-diagram" aria-label="NPC 五级流水线微架构图">
          <article class="pipe-stage"><h4>IFU</h4><p>PC 选择<br/>BPU 预测<br/>I-Cache lookup/refill<br/>取回 inst + pred_taken</p></article>
          <div class="pipe-reg">if2id<br/>valid / ready</div>
          <article class="pipe-stage"><h4>IDU</h4><p>译码<br/>R/I/S/B/U/J/Z 立即数<br/>控制 packet<br/>RAW hazard 检测</p></article>
          <div class="pipe-reg">id2ex<br/>valid / ready</div>
          <article class="pipe-stage"><h4>EXU</h4><p>前递 mux<br/>ALU / 比较<br/>branch / jal / jalr<br/>实际跳转结果</p></article>
          <div class="pipe-reg">ex2ls<br/>valid / ready</div>
          <article class="pipe-stage"><h4>LSU</h4><p>load/store<br/>AXI 请求 / 等响应<br/>分支反馈<br/>MMIO 语义</p></article>
          <div class="pipe-reg">ls2wb<br/>valid / ready</div>
          <article class="pipe-stage"><h4>WBU</h4><p>架构提交点<br/>GPR 写回 / CSR<br/>ecall / mret<br/>fence.i flush</p></article>
        </div>
        <div class="pipeline-note-grid">
          <article class="pipe-note"><strong>前递与停顿</strong><br/>普通 ALU 结果可从 LS/WB 前递；load 与 CSR 的最终值较晚，冒险单元必须让 ID 停顿。更年轻的 EX 生产者优先。</article>
          <article class="pipe-note"><strong>控制流恢复</strong><br/>LSU 输出普通 CFI 的 redirect 与 BPU 更新；WBU 的 ecall / mret / fence.i redirect 优先，顶层据此 flush 年轻指令。</article>
          <article class="pipe-note"><strong>前端 / 总线</strong><br/>BPU 为 4-entry BTB + 32-entry BHT；I-Cache 为 4×16 B direct-mapped。IFU 为 AXI M0，LSU 为 M1，仲裁器锁定事务至响应结束。</article>
        </div>
        <p class="diagram-caption">答辩时先说“每级输入、输出和一条指令何时提交”，再说 valid/ready 保持、RAW 冒险、前递、flush/redirect、I-Cache miss 与 AXI 等待。不要只报模块名。</p>
        ${codeLinks([
          ["npc/vsrc/ysyx_24110011.sv", 107, "顶层：四个 packet、五级实例化与 redirect"],
          ["npc/vsrc/include/pipeline_pkt_pkg.sv", 204, "packet 结构定义"],
          ["npc/vsrc/pip_reg.sv", 18, "valid/ready 级间寄存器"],
          ["npc/vsrc/hazard_unit.sv", 24, "RAW 冒险与前递选择"],
          ["npc/vsrc/IFU.sv", 124, "IFU、BPU 与 I-Cache 参数"],
          ["npc/vsrc/WBU.sv", 41, "提交、CSR、ecall/mret/fence.i"]
        ])}
      </section>

      <section class="diagram-panel hidden" data-diagram-panel="makeflow">
        <p class="eyebrow">03 · BUILD AND RUN TIMELINE</p>
        <div class="sequence-diagram" aria-label="AM 到 NPC 仿真的 Makefile 调用时序图">
          <article class="sequence-lane"><h4>你 / 应用</h4><div class="sequence-event tone-cyan">1. <code>make -C am-kernels/... ARCH=riscv32e-npc run git_commit=</code></div><div class="sequence-event">应用声明 NAME、SRCS，包含 AM Makefile。</div></article>
          <article class="sequence-lane"><h4>AM Makefile</h4><div class="sequence-event tone-purple">2. 拆解 ARCH 为 ISA + PLATFORM，包含 <code>scripts/$(ARCH).mk</code>。</div><div class="sequence-event">编译 .c/.S，递归构建 am / klib，链接 ELF。</div></article>
          <article class="sequence-lane"><h4>平台 .mk</h4><div class="sequence-event tone-gold">3. 选择启动代码、CTE、IOE、链接脚本和入口地址。</div><div class="sequence-event">objcopy：ELF → BIN，并把镜像路径传给 npc。</div></article>
          <article class="sequence-lane"><h4>npc/Makefile</h4><div class="sequence-event tone-cyan">4. <code>npc</code> 走顶层 <code>ysyx</code>；<code>run</code> 走 <code>ysyxSoCFull</code>。</div><div class="sequence-event">收集 <code>npc/vsrc</code>、C/C++ 与 SoC Verilog，准备 build 目录。</div></article>
          <article class="sequence-lane"><h4>Verilator / monitor</h4><div class="sequence-event tone-purple">5. Verilator --build 生成 Vysyx / VysyxSoCFull。</div><div class="sequence-event">加载 BIN，复位，执行，SDB/Trace/PMC/DiffTest 在 C++ 一侧协助。</div></article>
          <article class="sequence-lane"><h4>提交与 tracer</h4><div class="sequence-event tone-gold">6. 每条退休指令可进行 DiffTest；未覆盖时，运行结束后 NPC Makefile 会调用根目录 tracer 逻辑。</div><div class="sequence-event">复习命令统一附 <code>git_commit=</code> 覆盖该宏；仍要先看 <code>git status</code>，因为构建本身会产生文件。</div></article>
        </div>
        <p class="diagram-caption">NPC-only 路径：<code>riscv32e-npc.mk → platform/npc.mk → make -C npc npc</code>，镜像/复位基址为 <code>0x80000000</code>。SoC 路径：<code>riscv32e-ysyxsoc.mk → platform/ysyxsoc.mk → make -C npc run</code>，CPU 从 <code>0x30000000</code> 的 Flash 区启动。复习运行时在末尾加 <code>git_commit=</code> 抑制 tracer 提交；RT-Thread 因 <code>NAME=rtthread</code> 选择专用链接脚本。</p>
        ${codeLinks([
          ["abstract-machine/Makefile", 27, "ARCH → ISA / PLATFORM"],
          ["abstract-machine/scripts/platform/npc.mk", 14, "NPC 链接地址、ELF→BIN、run"],
          ["abstract-machine/scripts/platform/ysyxsoc.mk", 15, "SoC / RT-Thread 链接脚本与 run"],
          ["npc/Makefile", 97, "NPC/SoC 两种 Verilator 构建路径"],
          ["Makefile", 21, "根目录 tracer Git 记录逻辑"]
        ])}
      </section>

      <div class="section-heading"><div><p class="eyebrow">VS CODE READING ROUTE</p><h2>不要按目录漫游：按“外壳 → 主线 → 控制 → 证据”阅读</h2><p>每次只打开一组文件，先回答卡片上的问题，再继续下一组。所有按钮会随左侧工作区路径变化，直接跳转到当前代码。</p></div></div>
      <section class="bento cols-3">
        <article class="card accent-cyan"><p class="eyebrow">READ 01 · 外壳</p><h3>先确认你到底运行了什么</h3><p>回答：<code>npc</code> 与 <code>run</code> 顶层分别是什么？哪些 SV、C++、SoC 文件被收进 Verilator？构建后为何要保留 <code>git_commit=</code>？</p>${codeLinks([["npc/Makefile", 56, "源文件收集与两种顶层"], ["Makefile", 21, "tracer 宏"]])}</article>
        <article class="card accent-purple"><p class="eyebrow">READ 02 · 主线</p><h3>从 packet 开始走一条指令</h3><p>先看 packet 定义，再依序打开 IFU、IDU、EXU、LSU、WBU。对每一级写下输入、输出、何时 valid、何时 ready。</p>${codeLinks([["npc/vsrc/ysyx_24110011.sv", 107, "顶层流水连线"], ["npc/vsrc/include/pipeline_pkt_pkg.sv", 204, "四个 packet"], ["npc/vsrc/IFU.sv", 38, "IF 起点"], ["npc/vsrc/WBU.sv", 28, "提交终点"]])}</article>
        <article class="card accent-gold"><p class="eyebrow">READ 03 · 控制与证据</p><h3>最后才看最容易迷路的横向逻辑</h3><p>回答：load-use 为什么停顿？谁发 redirect？为何 DiffTest 在退休比较？异常如何跨越 WBU、trap.S 和 CTE？</p>${codeLinks([["npc/vsrc/hazard_unit.sv", 24, "冒险与前递"], ["npc/csrc/src/cpu_exec.cpp", 191, "退休 / DiffTest"], ["abstract-machine/am/src/riscv/npc/trap.S", 41, "trap frame"], ["abstract-machine/am/src/riscv/npc/cte.c", 8, "CTE 事件"]])}</article>
      </section>

      <div class="section-heading"><div><p class="eyebrow">CURRENT-CODE CHECKPOINTS</p><h2>答辩时主动说出的边界，会比背模块名更有说服力</h2></div></div>
      <section class="bento cols-3">
        <article class="card"><h3>NPC-only 与 SoC 不是同一条路径</h3><p><code>ysyx</code> + DPI pmem 的复位 PC 为 <code>0x80000000</code>；<code>ysyxSoCFull</code> 通过 SoC 外设网络，从 Flash <code>0x30000000</code> 取指。验证命令应匹配目标。</p></article>
        <article class="card"><h3>当前前端很小，离线工具不等于 RTL</h3><p>BPU 是 4-entry BTB + 32-entry BHT；I-Cache 是 4 行 × 16 B 的 direct-mapped。当前没有硬件 D-Cache；<code>npc/cachesim</code> 仅做 Trace 离线分析。</p></article>
        <article class="card"><h3>配置与生成物必须诚实说明</h3><p>当前启用 RVE/PMC/FAST_FLASH，设备、DiffTest、trace、波形默认关闭。SoC Scala 的 CPU blackbox 名称与已生成 Verilog 存在未同步风险；未核对前不要重生成 SoC。</p></article>
      </section>

      <section class="bento cols-3">
        <article class="card accent-cyan"><p class="eyebrow">闭卷检查</p><h3>总架构图</h3><p>能否用 90 秒说清应用、AM、镜像、NEMU、NPC、SoC 和宿主机各在哪一层？</p></article>
        <article class="card accent-purple"><p class="eyebrow">闭卷检查</p><h3>NPC 微架构图</h3><p>能否指出一条 load、分支预测错误、ecall 分别在哪里停顿、redirect 和提交？</p></article>
        <article class="card accent-gold"><p class="eyebrow">闭卷检查</p><h3>Makefile 时序图</h3><p>能否从一个 C 源文件说到 ELF、BIN、Verilator 可执行文件，并解释 tracer 与 <code>git_commit=</code> 的关系？</p></article>
      </section>`;
  }

  function renderCommands() {
    setTopbar("验证命令实验室", "每个结论都要有一条可复现的验证路径");
    app.innerHTML = `
      <div class="section-heading"><div><p class="eyebrow">RUN WITH INTENT</p><h2>先读副作用，再复制命令</h2><p>命令只会复制，网页不会替你执行。建议按“环境/工作树 → NEMU → NPC cpu-tests → yield-os → RT-Thread”的由小到大路径运行。</p></div></div>
      <div class="warning-box"><strong>非常重要：tracer 与配置副作用</strong>未覆盖时，<code>make -C npc npc</code> 与 <code>make -C npc run</code> 会调用根目录 <code>git_commit</code> 宏，进入 tracer 分支并创建提交。本页所有运行命令都附 <code>git_commit=</code> 覆盖该宏；仍请先运行 <code>git status --short --branch</code>，因为构建会写入 build/、镜像和日志。<code>make -n</code> 只预览调用链；<code>make menuconfig</code> 会修改 <code>npc/.config</code>，不要把它当作无副作用检查。</div>
      <div class="tip-box"><strong>复习时不要碰的两个入口</strong>不要运行仓库根目录 <code>init.sh</code>；它是可能覆盖工程状态的历史初始化脚本。也不要把 RT-Thread BSP 的 <code>init</code> 当作普通验证命令，它会重新生成 <code>rtconfig.h</code>、<code>files.mk</code> 等工程状态。</div>
      <section class="command-section">
        ${commandGroups.map(group => `<article class="command-group"><h3>${escapeHtml(group.title)}</h3><p>${escapeHtml(group.description)}</p>${group.commands.map(([command, description, note]) => `<div class="command-card"><div><code>${escapeHtml(formatCommand(command))}</code><div class="command-meta"><span class="meta-pill">${escapeHtml(description)}</span><span class="meta-pill">${escapeHtml(note)}</span></div></div><button class="command-button" type="button" data-copy="${escapeHtml(formatCommand(command))}">复制</button></div>`).join("")}</article>`).join("")}
      </section>
      <section class="bento cols-3">
        <article class="card"><p class="eyebrow">失败时的第一步</p><h3>先找第一条差异</h3><p>DiffTest / ITrace / SDB 把范围缩到一条指令；不要从最终卡死或一大段波形开始猜。</p></article>
        <article class="card"><p class="eyebrow">验证边界</p><h3>先短后长</h3><p>先让一个最小镜像正确结束，再跑 CPU tests、yield-os，最后再运行 RT-Thread 与 SoC 外设链路。</p></article>
        <article class="card"><p class="eyebrow">保留证据</p><h3>记录命令与第一现场</h3><p>每次失败至少保存镜像、首个 PC/指令、寄存器差异和是否涉及 MMIO；它们比重复运行更有价值。</p></article>
      </section>`;
  }

  function shuffle(items) {
    const copy = [...items];
    for (let index = copy.length - 1; index > 0; index -= 1) {
      const swapIndex = Math.floor(Math.random() * (index + 1));
      [copy[index], copy[swapIndex]] = [copy[swapIndex], copy[index]];
    }
    return copy;
  }

  function saveQuiz() {
    const quiz = state.quiz ? {
      filter: state.quiz.filter,
      questionIds: state.quiz.questionIds,
      answers: state.quiz.answers,
      startedAt: state.quiz.startedAt,
      submitted: state.quiz.submitted,
      result: state.quiz.result
    } : null;
    localStorage.setItem(QUIZ_KEY, JSON.stringify(quiz));
  }

  function createQuiz(filter) {
    const eligible = quizBank.filter(question => filter === "all" || question.chapter === filter);
    const questionIds = shuffle(eligible).slice(0, Math.min(12, eligible.length)).map(question => question.id);
    state.quiz = { filter, questionIds, answers: {}, startedAt: null, submitted: false, result: null };
    state.quizFilter = filter;
    saveQuiz();
  }

  function currentQuizQuestions() {
    if (!state.quiz || !Array.isArray(state.quiz.questionIds)) createQuiz(state.quizFilter);
    const questions = state.quiz.questionIds.map(id => quizBank.find(question => question.id === id)).filter(Boolean);
    if (!questions.length) {
      createQuiz(state.quizFilter);
      return currentQuizQuestions();
    }
    return questions;
  }

  function timeRemaining() {
    if (!state.quiz || !state.quiz.startedAt || state.quiz.submitted) return 45 * 60;
    return Math.max(0, (45 * 60) - Math.floor((Date.now() - state.quiz.startedAt) / 1000));
  }

  function timerLabel(seconds) {
    const minutes = Math.floor(seconds / 60);
    return `${String(minutes).padStart(2, "0")}:${String(seconds % 60).padStart(2, "0")}`;
  }

  function clearQuizTimer() {
    if (state.timerId) window.clearInterval(state.timerId);
    state.timerId = null;
  }

  function submitQuiz(autoSubmit) {
    if (!state.quiz || state.quiz.submitted) return;
    const questions = currentQuizQuestions();
    const correct = questions.filter(question => state.quiz.answers[question.id] === question.answer).length;
    state.quiz.submitted = true;
    state.quiz.result = { correct, total: questions.length };
    saveQuiz();
    clearQuizTimer();
    if (autoSubmit) showToast("时间到，已自动提交。请检查每题解析。");
    renderView();
  }

  function startQuizTimer() {
    clearQuizTimer();
    if (!state.quiz || !state.quiz.startedAt || state.quiz.submitted) return;
    const update = () => {
      const element = document.querySelector("#quiz-timer-value");
      const remaining = timeRemaining();
      if (element) element.textContent = timerLabel(remaining);
      if (remaining <= 0) submitQuiz(true);
    };
    update();
    state.timerId = window.setInterval(update, 1000);
  }

  function quizControls(quiz) {
    const started = Boolean(quiz.startedAt);
    const note = quiz.submitted
      ? "本卷已提交；每题下方已显示解析。"
      : started
        ? "作答中；可随时交卷并查看解析。"
        : "先开始模拟，选项才会解锁；交卷后显示本卷解析。";
    return `<div class="quiz-actions quiz-controls"><span class="quiz-control-note">${note}</span>${!started ? `<button class="primary-button" type="button" data-quiz-start>开始 45 分钟模拟</button>` : ""}${started && !quiz.submitted ? `<button class="secondary-button" type="button" data-quiz-submit>交卷并查看解析</button>` : ""}<a class="secondary-button" href="#answer-deck">查看全部题库答案</a><button class="secondary-button" type="button" data-quiz-new="${quiz.filter}">换一套题</button></div>`;
  }

  function renderQuiz() {
    currentQuizQuestions();
    const questions = currentQuizQuestions();
    const quiz = state.quiz;
    const started = Boolean(quiz.startedAt);
    const answered = Object.keys(quiz.answers).length;
    setTopbar("模拟考核 · 45 分钟", "先在压力下作答，再用解析修复知识网络");
    app.innerHTML = `
      <div class="section-heading"><div><p class="eyebrow">EXAM MODE</p><h2>C 阶段为主，B / PPT 为辅</h2><p>每次从所选范围随机抽取至多 12 题。开始后限时 45 分钟；提交后显示正确答案和解释，题库速览可用作考前口述卡。</p></div></div>
      <div class="filter-row" role="group" aria-label="题目范围">${["all", "C1", "C2", "C3", "C4", "C5", "C6", "B1", "B2", "B3", "B4", "PPT"].map(filter => `<button class="chip-button ${quiz.filter === filter ? "active" : ""}" type="button" data-quiz-filter="${filter}">${filter === "all" ? "全部范围" : filter}</button>`).join("")}</div>
      <section class="quiz-dashboard">
        <article class="quiz-card">
          <div class="quiz-meta"><span>${quiz.submitted ? "已提交 · 查看解析" : started ? "考试进行中" : "尚未开始 · 选项锁定"}</span><span>${answered}/${questions.length} 已作答</span></div>
          ${quizControls(quiz)}
          ${questions.map((question, questionIndex) => {
            const chosen = quiz.answers[question.id];
            return `<section class="quiz-question-block"><p class="eyebrow">${question.chapter} · 第 ${questionIndex + 1} 题</p><h3 class="quiz-question">${escapeHtml(question.question)}</h3><div class="option-list">${question.options.map((option, optionIndex) => {
              const className = quiz.submitted ? (optionIndex === question.answer ? "correct" : optionIndex === chosen ? "wrong" : "") : "";
              const locked = !started && !quiz.submitted;
              return `<label class="option ${className} ${locked ? "locked" : ""}" ${locked ? "aria-disabled=\"true\"" : ""}><input type="radio" name="quiz-${question.id}" data-quiz-question="${question.id}" value="${optionIndex}" ${chosen === optionIndex ? "checked" : ""} ${!started || quiz.submitted ? "disabled" : ""}/><span>${String.fromCharCode(65 + optionIndex)}. ${escapeHtml(option)}</span></label>`;
            }).join("")}</div>${quiz.submitted ? `<div class="answer-box quiz-answer"><strong>解析</strong>正确答案：${String.fromCharCode(65 + question.answer)}。${escapeHtml(question.explanation)}</div>` : ""}`;
          }).join("")}
          ${quizControls(quiz)}
        </article>
        <aside class="quiz-sidebar">
          <div class="timer"><strong id="quiz-timer-value">${timerLabel(timeRemaining())}</strong><span>${quiz.submitted ? "本卷已结束" : "剩余时间"}</span></div>
          <div class="quiz-stat"><strong>${questions.filter(question => question.chapter.startsWith("C")).length}</strong><span>C 阶段题目数</span></div>
          <div class="quiz-stat"><strong>${quiz.submitted ? `${quiz.result.correct}/${quiz.result.total}` : "—"}</strong><span>${quiz.submitted ? "本卷得分" : "提交后显示得分"}</span></div>
          <div class="tip-box"><strong>作答策略</strong>先做能从代码链条推出答案的题；遇到不确定项，写下“需要打开的文件”，不要凭模糊印象硬猜。</div>
        </aside>
      </section>
      <section class="section-heading" id="answer-deck"><div><p class="eyebrow">ANSWER DECK</p><h2>全部题库答案速览</h2><p>用于模拟之后的口述复盘：先回答，再展开核对。</p></div></section>
      <section class="chapter-list">${quizBank.map(question => `<details class="chapter-card"><summary><div class="chapter-title"><span class="chapter-badge">${question.chapter}</span><div><h3>${escapeHtml(question.question)}</h3><p>展开查看标准答案与解释</p></div></div><span class="chapter-toggle">＋</span></summary><div class="chapter-body"><div class="answer-box"><strong>答案：${String.fromCharCode(65 + question.answer)}</strong>${escapeHtml(question.explanation)}</div></div></details>`).join("")}</section>`;
    startQuizTimer();
  }

  function renderPpt() {
    setTopbar("PPT 答辩清单", "把三张图讲成一条有证据的工程故事");
    const slides = [
      ["01", "项目目标与范围", "一句话说明：用 NEMU 作为 ISA 参考，把 AM 应用、NPC RTL、SoC 外设和 RT-Thread 连成可验证系统。明确本次重点是 C 阶段能力，当前代码已延伸到 B 阶段流水线。"],
      ["02", "一生一芯项目架构图", "展示应用 → AM → ELF/BIN → NEMU/NPC → ysyxSoC 的关系；明确 NEMU 是参考模型，CacheSim/BranchSim 是离线工具。"],
      ["03", "NPC 微架构图", "按 IFU、IDU、EXU、LSU、WBU 解释数据如何流动；补充 valid/ready、前递、RAW 停顿、redirect、BPU、I-Cache 与 AXI。"],
      ["04", "C 阶段必做能力", "用 C1–C6 说明：RV32IM 语义、最简 RTL、AM/调试、RV32E/DiffTest、MMIO、异常与 RT-Thread。每项都展示一条真实代码路径和验证命令。"],
      ["05", "验证闭环", "NEMU cpu-tests → NPC cpu-tests → yield-os → AM I/O → RT-Thread。强调失败时找第一条架构差异，而不是从最后一条报错猜。"],
      ["06", "Makefile 调用时序图", "从应用 Makefile 到 AM、平台 .mk、NPC Makefile、Verilator、仿真可执行文件；指出 tracer Git 记录会被复习命令中的 git_commit= 覆盖。"],
      ["07", "系统软件与设备", "把 ecall → CTE → mret、UART/timer/MMIO、RT-Thread 上下文切换串起来；说明为什么设备访问的 DiffTest 需要谨慎 skip。"],
      ["08", "当前实现的性能与边界", "说明当前五级流水、BPU、I-Cache、AXI/SoC 如何协同；同时诚实写出当前无硬件 D-Cache、哪些 config 默认关闭。"],
      ["09", "难点、修复与反思", "按“现象 → 第一证据 → 根因 → 修复 → 回归命令”讲一个冒险、控制流、MMIO 或启动问题；避免只讲‘改了某行代码’。"],
      ["10", "演示与问答", "准备一条短程序或 cpu-test，现场说明如何打开 VS Code、跑验证、定位第一条差异；最后回到三张图收束。"]
    ];
    app.innerHTML = `
      <div class="section-heading"><div><p class="eyebrow">PRESENTATION READINESS</p><h2>按已知要求生成的答辩骨架</h2><p>这一页给出你明确要求纳入的重点，以及一条可在考核中讲清的演示路径。</p></div><button class="secondary-button" type="button" data-view="architecture">打开三张图</button></div>
      <section class="ppt-status"><span>!</span><div><h3>飞书正文尚未读取，正式条目待核对</h3><p>当前环境访问这两个飞书链接会跳转登录页，因此无法可靠提取其中的正式评分要求；网页不会臆造它们。已根据你在任务中明确提出的重点，完整纳入项目架构图、NPC 微架构图、Makefile 调用时序图、代码导读、验证与模拟题。获得可访问权限或把正文粘贴/导出后，应逐条核对并补充本清单。</p><p><a class="inline-link" href="https://fa45epzd9c7.feishu.cn/wiki/VquRwj87QiH80AkJtz3cS97dnKc" target="_blank" rel="noreferrer">打开飞书 Wiki ↗</a>　<a class="inline-link" href="https://fa45epzd9c7.feishu.cn/docx/REAUdWQK1oVOuHxAs9JcKJf6nGe" target="_blank" rel="noreferrer">打开飞书文档 ↗</a></p></div></section>
      <section class="ppt-slide-list">${slides.map(([number, title, content]) => `<article class="ppt-slide"><strong>${number}</strong><div><h4>${title}</h4><p>${content}</p></div><button class="chip-button" type="button" data-view="${["02", "03", "06"].includes(number) ? "architecture" : "chapters"}">${["02", "03", "06"].includes(number) ? "看图" : "看代码"}</button></article>`).join("")}</section>
      <section class="bento cols-3">
        <article class="card accent-cyan"><p class="eyebrow">讲述公式</p><h3>功能 → 机制 → 证据</h3><p>每页至少回答三句：它解决什么问题？为什么此机制正确？我用哪份代码或哪条命令证明？</p></article>
        <article class="card accent-purple"><p class="eyebrow">图的正确打开方式</p><h3>先数据，后控制，再边界</h3><p>先沿主数据路径讲；再插入 hazard、flush、AXI；最后说明未实现项和配置开关。可信比“功能堆砌”重要。</p></article>
        <article class="card accent-gold"><p class="eyebrow">现场演示</p><h3>用可复现命令收尾</h3><p>演示前先检查 Git 状态；现场以小镜像或短回归为主，并保留命令末尾的 <code>git_commit=</code> 以抑制 tracer 提交。</p></article>
      </section>`;
  }

  function renderView() {
    clearQuizTimer();
    const renderers = {
      overview: renderOverview,
      chapters: renderChapters,
      architecture: renderArchitecture,
      commands: renderCommands,
      quiz: renderQuiz,
      ppt: renderPpt
    };
    (renderers[state.view] || renderOverview)();
    document.querySelectorAll("[data-view]").forEach(button => {
      button.classList.toggle("active", button.dataset.view === state.view && button.classList.contains("nav-item"));
    });
    app.focus({ preventScroll: true });
  }

  function copyCommand(value) {
    const copied = navigator.clipboard && navigator.clipboard.writeText ? navigator.clipboard.writeText(value) : Promise.reject(new Error("clipboard unavailable"));
    copied.then(() => showToast("命令已复制到剪贴板")).catch(() => {
      window.prompt("请复制下面的命令", value);
    });
  }

  document.addEventListener("click", event => {
    const viewButton = event.target.closest("[data-view]");
    if (viewButton) {
      state.view = viewButton.dataset.view;
      document.querySelector(".sidebar").classList.remove("open");
      renderView();
      return;
    }
    const brand = event.target.closest("[data-view-link]");
    if (brand) {
      event.preventDefault();
      state.view = brand.dataset.viewLink;
      renderView();
      return;
    }
    const copyButton = event.target.closest("[data-copy]");
    if (copyButton) {
      copyCommand(copyButton.dataset.copy);
      return;
    }
    const diagramButton = event.target.closest("[data-diagram-tab]");
    if (diagramButton) {
      const selected = diagramButton.dataset.diagramTab;
      document.querySelectorAll("[data-diagram-tab]").forEach(button => button.classList.toggle("active", button === diagramButton));
      document.querySelectorAll("[data-diagram-panel]").forEach(panel => panel.classList.toggle("hidden", panel.dataset.diagramPanel !== selected));
      return;
    }
    const filterButton = event.target.closest("[data-quiz-filter]");
    if (filterButton) {
      createQuiz(filterButton.dataset.quizFilter);
      renderView();
      return;
    }
    const startButton = event.target.closest("[data-quiz-start]");
    if (startButton && state.quiz) {
      state.quiz.startedAt = Date.now();
      saveQuiz();
      renderView();
      return;
    }
    const submitButton = event.target.closest("[data-quiz-submit]");
    if (submitButton) {
      submitQuiz(false);
      return;
    }
    const newQuizButton = event.target.closest("[data-quiz-new]");
    if (newQuizButton) {
      createQuiz(newQuizButton.dataset.quizNew || "all");
      renderView();
    }
  });

  document.addEventListener("change", event => {
    const task = event.target.closest("[data-task-id]");
    if (task) {
      if (task.checked) state.completed.add(task.dataset.taskId);
      else state.completed.delete(task.dataset.taskId);
      updateProgress();
      return;
    }
    const option = event.target.closest("[data-quiz-question]");
    if (option && state.quiz && !state.quiz.submitted && state.quiz.startedAt) {
      state.quiz.answers[option.dataset.quizQuestion] = Number(option.value);
      saveQuiz();
      const answeredCounter = document.querySelector(".quiz-meta span:last-child");
      if (answeredCounter) answeredCounter.textContent = `${Object.keys(state.quiz.answers).length}/${currentQuizQuestions().length} 已作答`;
    }
  });

  workspaceInput.addEventListener("change", () => {
    localStorage.setItem(ROOT_KEY, getRoot());
    renderView();
    showToast("WSL 工作区路径已更新");
  });

  wslDistroInput.addEventListener("change", () => {
    localStorage.setItem(WSL_DISTRO_KEY, getWslDistro());
    renderView();
    showToast("WSL 发行版已更新");
  });

  document.querySelector("#reset-progress").addEventListener("click", () => {
    if (!window.confirm("确认清除本浏览器保存的复习勾选进度？")) return;
    state.completed.clear();
    updateProgress();
    renderView();
    showToast("本机复习进度已重置");
  });

  document.querySelector("#toggle-focus").addEventListener("click", () => {
    document.body.classList.toggle("focus-mode");
    showToast(document.body.classList.contains("focus-mode") ? "已进入专注模式" : "已退出专注模式");
  });

  document.querySelector("#toggle-mobile-nav").addEventListener("click", () => {
    document.querySelector(".sidebar").classList.toggle("open");
  });

  detailDialog.querySelector(".dialog-close").addEventListener("click", () => detailDialog.close());
  updateProgress();
  renderView();
})();
