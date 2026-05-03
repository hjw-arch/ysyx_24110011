# AGENTS.md

本文件用于指导在 `ysyx-workbench` 根目录及其子工程中的自动化/代理式改动。
如果子目录内存在更近的 `AGENTS.md`，以更近的文件为准；例如 `npc/AGENTS.md` 对 `npc/` 内的工作有更详细约束。

## 重要要求
- 除非用户明确要求使用其他语言，否则回答与新增文档优先使用中文。
- 可以自由执行读取、检索、查看状态等只读操作。
- 修改代码、构建脚本或工程配置前，先给出清晰的修改计划，并提醒用户进行 git 记录。
- 未得到用户显式许可前，不要执行可能修改代码或工程状态的命令；但用户明确要求 `/init`、创建/更新 `AGENTS.md` 等代理说明文件时，可按请求直接完成。
- 不要运行根目录 `init.sh`，它是历史初始化脚本，可能覆盖或破坏本地工程。
- 阅读代码时尽量结合完整上下文，不要只凭局部片段给出结论。

## 项目定位
- 本仓库是“一生一芯”整体工程，包含多个子工程和外部依赖。
- 主要语言为 SystemVerilog、Verilog、C/C++，辅以 Makefile、Scala/Chisel、Python 脚本。
- 顶层 `Makefile` 主要用于 tracer/记录逻辑，不负责普通构建；实际构建通常在各子工程目录中执行。
- `.gitignore` 采用白名单策略，仅显式跟踪部分子工程；不要误以为未显示在 `git status` 中的目录就不存在。

## 重要目录
- `nemu/`：NEMU 模拟器。
- `abstract-machine/`：AM 框架与平台脚本。
- `am-kernels/`：AM 测试用例，默认被顶层忽略。
- `npc/`：NPC/SoC 级处理器验证子工程，详见 `npc/AGENTS.md`。
- `ysyxSoC/`：SoC 外设、顶层与构建产物。
- `RT-Thread/`：RT-Thread 相关源码与 BSP。
- `nvboard/`、`fceux-am/`：外部/辅助项目，默认被顶层忽略。

## 常用命令
- 根目录默认目标只提示进入子工程：`make`。
- NPC/SoC 仿真：`make -C npc run`。
- NPC-only 仿真：`make -C npc npc`。
- NPC 清理：`make -C npc clean`。
- ysyxSoC 构建入口：`make -C ysyxSoC`，具体目标以该目录 Makefile 为准。
- NEMU 构建/运行入口：`make -C nemu`，具体目标以该目录 Makefile 与配置为准。

## 构建与环境注意
- 常见依赖包括 `verilator`、`llvm-config`、RISC-V 工具链、NVBoard 环境变量等。
- `npc/Makefile` 会包含根目录 `Makefile` 并触发 tracer 分支记录逻辑；运行仿真前确认当前 git 状态符合预期。
- 构建产物通常位于各子工程的 `build/`、`out/`、`.cache/` 等目录，不要手动提交无关产物。
- 如需运行耗时仿真或会生成大量波形/日志的命令，先说明目的、输入镜像和预计影响。

## 变更原则
- 优先遵循已有 Makefile、脚本和目录结构，不引入新的构建系统。
- 小改动优先局部修复，避免跨子工程重构。
- 不要随意修改学号、姓名、tracer、提交记录相关逻辑。
- 不要删除或覆盖外部依赖目录、构建缓存、用户本地镜像和波形文件，除非用户明确要求。
- 处于 dirty worktree 时，只处理与当前任务直接相关的文件；不要回滚用户已有改动。

## 代码风格
- SystemVerilog/Verilog：模块名与文件名尽量保持一致，信号名多用 `snake_case`，方向后缀常见 `_i/_o`。
- SystemVerilog：时序逻辑优先使用 `always_ff`，组合逻辑优先使用 `always_comb`，默认分支保持明确。
- C/C++：遵循现有 `snake_case` 命名、显式位宽类型、`Log`/`Assert`/`panic` 等本地宏。
- Makefile：变量多用全大写加下划线；保持现有目标命名和 include 关系。
- Python：4 空格缩进，函数/变量使用 `snake_case`，复杂脚本优先延续现有结构。

## 验证建议
- 修改 `npc/` 后，优先参考 `npc/AGENTS.md` 中列出的验证命令。
- 修改单个硬件模块时，可使用 `npc/vsrc_pip/testbench/` 或 `npc/vsrc/testbench/` 中的局部 testbench。
- 修改跨模块流水线、总线、缓存、DiffTest 或 SoC 连接时，应说明未跑/已跑的仿真范围和剩余风险。
- 不能运行验证时，要在最终回复中明确说明原因。

## 外部文档
- YSYX 文档主页：`https://ysyx.oscc.cc/docs/`
- YSYX 英文文档仓库：`https://github.com/oscc-web/ysyx-docs-en`
