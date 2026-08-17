# legacy — 五级顺序流水线遗留源码

本目录文件**不被** OoO 顶层例化，仅作对照/考古。

OoO 对应模块在 `vsrc/` 根目录，小写命名：
- `idu.sv` / `exu.sv` / `lsu.sv`（取代 IDU/EXU/LSU）
- 提交语义在 `rob.sv` + 顶层 CSR（取代 WBU）
- `physical_regfile.sv`（取代 registerfile）
- 无 hazard_unit（`pip_reg.sv` 仍在 `vsrc/`，供 icache 使用）

`npc/Makefile` 的仿真源列表排除 `*/legacy/*`；
请勿把本目录加入仿真编译列表。
