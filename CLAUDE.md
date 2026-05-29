# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 用户交互规则（最高优先级，覆盖默认行为）

来源于 [npc/AGENTS.md](npc/AGENTS.md) 中用户自定义的前两节，对整个 workbench 同样适用：

- **回答与文档使用中文**，除非用户显式要求英文。
- **读取操作不需审查**，可以使用任何工具自由阅读代码。
- **修改操作必须先获得显式许可**：在执行任何修改/添加文件、运行可能改变工作区状态的 shell 命令之前，必须先输出**详细的修改/添加计划**，并提醒用户进行 git 记录，等待用户给出"审查完毕，允许执行"后才可执行。
- 禁止在未提交详细计划之前就索要"审查完毕，允许执行"，也禁止在未获得该指令时直接动手改代码。
- **不要把"修改代码"任务派发给子代理**——会与上述前置审查规则冲突，造成死锁；遇到死锁时也不要随意取消子代理。
- 阅读代码尽量全面，避免只看片段就下结论。审查力度要大，倾向于"提出建议"而非"侵入式修改"。
- **禁止修改 [npc/AGENTS.md](npc/AGENTS.md) 的前两节**，那是用户自定义内容。
- 顶层根目录的 [init.sh](init.sh) 是历史脚本，**禁止运行**或在建议中引用，避免破坏本地工程。

## Workbench 总览（"一生一芯" / ysyx）

本仓库是"整体工程"的容器，聚合了多个独立子工程与外部依赖。顶层并不构建任何东西：

- 顶层 [Makefile](Makefile) 仅承载 `tracer-ysyx` 自动提交逻辑（`.git_commit` / `.clean_index`），各子工程的 Makefile 末尾通过 `include ../Makefile` 接入。**不要修改顶层 Makefile**，其中包含 `STUID`/`STUNAME` 学号信息以及上游强制的 tracer 提交流程。
- [.gitignore](.gitignore) 采用"先忽略全部、再显式放行"的白名单策略；当前显式追踪：`nemu/`、`abstract-machine/`、`nanos-lite/`、`navy-apps/`、`npc/`、`ysyxSoC/`、`RT-Thread/`、`AGENTS.md`、`README.md`、`Makefile`、`init.sh`、`.gitignore`。`nvboard/`、`fceux-am/`、`am-kernels/` 默认不追踪。修改 `.gitignore` 时保持白名单结构。
- [.gitmodules](.gitmodules)：`RT-Thread/` 是子模块（`Hjw-Arch/RT-Thread-AM`），其它子工程是直接 commit 进来的拷贝（不是 submodule）。

## 子工程关系（who depends on whom）

```
abstract-machine (AM, 统一运行时与平台脚本)
        │
        ├── 平台脚本 scripts/platform/*.mk 选择目标
        │     ├── nemu.mk     → 调用 $(NEMU_HOME) 的 `make run`
        │     ├── npc.mk      → 调用 $(NPC_HOME) 的 `make npc`
        │     └── ysyxsoc.mk  → 调用 $(NPC_HOME) 的 `make run`（带 ysyxSoC 链接脚本）
        │
        ├── am-kernels / navy-apps / RT-Thread → 通过 AM 在不同平台运行
        │
nemu (RISC-V32 模拟器, ITRACE/差分测试参考实现)
        │
        └── 编译为 libnemu.so（位于 npc/ 根，符号链接 npc/riscv32-nemu-interpreter-so），
            供 npc/ 通过 `-d ./libnemu.so` 做 DiffTest

npc  (本人 RTL 实现, 5 级流水 + AXI4 + SoC 顶层)
        │
        └── ysyxSoC（SoC 外设/顶层）— 通过 npc/Makefile 的 `make run` 联合仿真
```

关键耦合：`npc/` 顶层 [Makefile](npc/Makefile) 中 `SIM_LDFLAGS` 写死了 `-L/home/hjw-arch/ysyx-workbench/npc/ -lnemu`，并通过 `libnemu.so → ../npc/riscv32-nemu-interpreter-so` 这一软链接形成 NPC ↔ NEMU 差分测试通路。修改路径或删除该 .so 会破坏 DiffTest。

## 常用命令

> 所有命令都假设环境变量 `NEMU_HOME` / `AM_HOME` / `NPC_HOME` / `NVBOARD_HOME` 已正确设置。**不要运行 `init.sh` 或 `addenv` 来"自动设置"**，请手动配置并核对。

### NPC（主要工作区，[npc/](npc/)）
- 默认运行（NPC + ysyxSoC 联合仿真）：`make -C npc run` 或 `make -C npc`
- 仅 NPC（不带 SoC）：`make -C npc npc`
- 接 NVBoard 仿真：`make -C npc sim`
- 清理：`make -C npc clean`
- 指定运行镜像：`make -C npc run IMG=/abs/path/to/image.bin`
- 关闭 DiffTest：`make -C npc npc NPCARGS=""`
- 单模块 testbench（Verilator）：`make -C npc/vsrc_pip/testbench run TOP_NAME=ALU`
- 关闭波形：`make -C npc/vsrc_pip/testbench run TOP_NAME=adder32 TRACE_IS_ON=OFF`
- 旧版 testbench：`make -C npc/vsrc/testbench run TOP_NAME=registerfile`
- cachesim 工具：`make -C npc/cachesim all`，多配置搜索：`python3 npc/cachesim/research.py`

### NEMU（[nemu/](nemu/)）
- 配置：`make -C nemu menuconfig`（当前 `.config` 已选 `riscv32` + `interpreter` + `TARGET_AM`）
- 构建并运行：在 AM 平台调用，或直接 `make -C nemu run`（需 `CONFIG_TARGET_NATIVE_ELF`/`CONFIG_TARGET_SHARE` 等模式）
- NEMU 当前配置为 `CONFIG_TARGET_AM=y`，意味着它依赖 AM；改为 native 需要重新 menuconfig。

### 通过 AM 运行用户程序
AM 平台脚本的运行模式：`make -C <user-program-dir> ARCH=riscv32-<platform> run`，其中 `<platform>` ∈ `{nemu, npc, ysyxsoc}`。该规则会进入 `$(NEMU_HOME)` 或 `$(NPC_HOME)` 调用对应 `run`/`npc` 目标。

## 调试 / Trace / DiffTest

- DiffTest 由 npc 侧的 `CONFIG_DIFFTEST` 宏控制（见 [npc/csrc/Include/config.h](npc/csrc/Include/config.h)），通过 `NPCARGS="-d ./libnemu.so"` 启用，禁用就把该参数置空。
- 其他 trace 宏：`CONFIG_ITRACE` / `CONFIG_MTRACE` / `CONFIG_FTRACE` / `WAVE` / `PERFORMANCE_COUNTER`。改宏开关时务必确认对仿真器的影响范围。
- Verilator 默认带 `--trace`，波形位于 `npc/build/` 或子 testbench 的 `build/obj_dir/`。
- 顶层 Makefile 中 `ASAN_OPTIONS=verify_asan_link_order=0` 用于关闭外设引入的"内存泄漏"误报，不要随意去掉。

## 测试与 Lint

仓库未配置 `pytest`/`ctest`/统一 lint。模块级验证只能依赖 `npc/vsrc_pip/testbench/` 与 `npc/vsrc/testbench/` 下的 Verilator 构建。Verilator 警告抑制写在 `npc/Makefile` 的 `VERILATOR_WNO`，源码内可用 `/* verilator lint_off ... */` 局部屏蔽。

## NPC 内部架构提示（仅看一眼时的入口）

详细规则、目录约定、代码风格、宏配置请阅读 [npc/AGENTS.md](npc/AGENTS.md)（已涵盖 SystemVerilog/C++/Python/Makefile 风格、5 级流水线（IFU/IDU/EXU/LSU/WBU）+ AXI4 总线 + Crossbar/CLINT 的整体结构、DiffTest/ITRACE/MTRACE/FTRACE 等开关、testbench 用法）。本 CLAUDE.md 不复述其中内容，请直接阅读该文件以获取一手信息。

入口文件参考：
- 主流水线 SV：[npc/vsrc_pip/](npc/vsrc_pip/) — `IFU.sv` / `IDU.sv` / `EXU.sv` / `LSU.sv` / `WBU.sv` / `Xbar.sv` / `axi4_full_arbiter.sv`
- C++ 仿真主回路：[npc/csrc/src/cpu_exec.cpp](npc/csrc/src/cpu_exec.cpp)、[npc/csrc/src/monitor.cpp](npc/csrc/src/monitor.cpp)
- 配置宏：[npc/csrc/Include/config.h](npc/csrc/Include/config.h)、[npc/csrc/Include/macro.h](npc/csrc/Include/macro.h)、[npc/csrc/Include/log.h](npc/csrc/Include/log.h)

## 当前 git 上下文

- 主分支为 `ysyx2204`，当前工作分支通常为 `pip`（流水线开发）。
- 顶层 Makefile 的 tracer 逻辑会在每次 `make run` 后自动在 `tracer-ysyx` 分支记录学号提交，**不要试图重写或绕过该流程**。
