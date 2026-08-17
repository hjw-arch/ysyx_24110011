# 单发射乱序执行（Single-Issue OoO）设计文档

> 分支：`OoO_pre`  
> **唯一设计真源**（`npc/docs/` 仅本文）  
> 状态：与 `vsrc/` 同步 — Tier1 + Tier2 + **Tier3-A** 完成；工程清理（仿真契约展平、轻量 PMC、注释）已落地。

---

## 0. 一句话定位

**单发射、乱序执行 / 顺序提交** 的经典 ROB + 重命名 + IQ 核，带 **commit 后 SQ drain** 与 **全覆盖 STLF**。  
访存 **issue 仍按程序序**（`older_mem`），故是完整教学向 OoO，**不是**激进访存乱序或超标量。

---

## 1. 目标与原则

将 NPC 从五级顺序流水改造为单发射乱序：

- 有序前端：IFU → idu → rename/dispatch  
- 乱序后端：IQ → EXU / LSU  
- 有序提交：ROB commit（架构状态唯一提交点）

**正确性不变量**：

1. 架构状态（AMT 映射、CSR、**内存**）只在 ROB **commit** 对外部不可回滚。  
2. 推测执行可写 PRF、占 SQ，但 **store 不得在 commit 前进入 AXI**。  
3. flush 只信任 `rob.flush_o`；恢复用 **next_amt（含同拍 commit）** 重建 RAT 与 freelist。  
4. 宽度：dispatch / issue / commit 均为 **1**。

风格：组合优先 `assign`，时序 always 浅，中文注释写不变量；面积小、延迟低。

---

## 2. 当前状态（截至文档更新）

### 2.1 已完成

| 档 | 内容 | 状态 |
|----|------|------|
| **Tier1** | BPU 真实 PC、legacy 隔离、定向 TB、设计文档 | ✅ |
| **Tier2** | 精确异常；Store Queue（commit 后 AXI 写）；PRF 3W | ✅ |
| **Tier3-A** | SQ CAM STLF（全覆盖）；部分重叠 stall；无重叠可 AXI load | ✅ |
| **工程清理** | commit 仿真契约展平；OoO 轻量 PMC；接口/注释；Makefile 去 axi4_lite include | ✅ |

### 2.2 回归

| 项 | 结果 |
|----|------|
| `make -C npc test` | 全过（含 `store_queue` 25、`lsu` 54） |
| 经典 `*-riscv32-npc.bin`（除 bitrev） | **25/25** HIT GOOD TRAP |
| `fence-i-riscv32e-npc.bin` | PASS |
| bitrev | **不做**（按项目约定） |

### 2.3 明确不做（本阶段）

双发射、复杂 mem 预测、多 ALU、非对齐访存、部分字节合并前递、RAT checkpoint、多 outstanding AXI load（除非后续单独立项）。

### 2.4 周期基线（Tier2 → Tier3-A）

| 测试 | Tier2 | Tier3-A | Δ |
|------|------:|--------:|--:|
| dummy | 69 | 69 | 0 |
| add | 2315 | 2314 | -1 |
| load-store | 1371 | 1375 | +4 |
| unalign | 659 | 646 | -13 |
| fib | 1693 | 1693 | 0 |
| bit | 1400 | 1397 | -3 |
| bubble-sort | 7383 | 6873 | **-510** |
| quick-sort | 11674 | 11674 | 0 |
| recursion | 24597 | 24628 | +31 |
| hello-str | 14896 | 14870 | -26 |
| string | 3584 | 3573 | -11 |
| sum | 1157 | 960 | **-197** |
| select-sort | 5905 | 5905 | 0 |
| goldbach | 27456 | 27456 | 0 |
| leap-year | 29310 | 29310 | 0 |
| mul-longlong | 8479 | 8479 | 0 |
| add-longlong | 4036 | 4032 | -4 |
| fact | 613 | 615 | +2 |
| div | 358 | 358 | 0 |
| switch | 523 | 523 | 0 |
| to-lower-case | 6186 | 6186 | 0 |
| if-else | 927 | 927 | 0 |
| shift | 1005 | 1005 | 0 |
| max | 2915 | 2914 | -1 |

访密：`bubble-sort` ≈ **-6.9%**，`sum` ≈ **-17%**；多数算密项持平。  
T3-A 收益来自 **load 不必等 SQ 全空**（同字 STLF / 不同字 AXI），**不是** load 越过更老未发射 store（IQ `older_mem` 仍在）。

---

## 3. 流水线组织

```
IFU → idu → rename_stage → issue_queue → ┬→ exu  ── complete1 ──┐
                                         │                      ├→ ROB → commit
                                         └→ lsu/SQ ─ complete2 ─┘      ├→ AMT / freelist
                                                                       ├→ CSR / trap / fence.i
                                                                       ├→ SQ drain（store AXI）
                                                                       └→ redirect / icache_inval
                              physical_regfile ← complete(EXU/LD) + commit(CSR) 写
                              wakeup ×2 → rename busy_table + IQ
```

访存（Tier3-A）：

```
IQ ─ mem issue ─ LSU ┬ SQ CAM 全覆盖 → STLF complete（无 AXI）
                     ├ 部分重叠     → stall（ready=0）
                     └ 无重叠       → AXI load（idle & ~drain）
ST：issue → SQ + complete；commit → drain AXI
IQ older_mem 序不变
```

| 参数 | 值 | 说明 |
|------|----|------|
| ROB_SIZE | 32 | 重排序缓冲 |
| IQ_SIZE | 8 | 发射队列 |
| SQ_DEPTH | 8 | Store Queue |
| NUM_PHYS_REGS | 64 | 物理寄存器（p0 = x0 恒 0） |
| NUM_ARCH_REGS | 32 | RV32I |
| FETCH/DECODE/ISSUE/COMMIT_WIDTH | 1 | 单发射 |

---

## 4. 双表重命名（RAT + AMT）

| 表 | 模块字段 | 更新时机 | 作用 |
|----|----------|----------|------|
| **RAT**（推测） | `rename_map_table.map_table` | dispatch 分配新 phys_rd | 源操作数重命名 |
| **AMT**（架构） | `rename_map_table.arch_map` | **commit** 且 rd_wen | 提交后 arch→phys |
| next_amt | 组合：AMT 合入本拍 commit | flush 当拍 | 恢复 RAT；freelist 快照 |

- freelist：p0 永不分配/释放；commit 归还 `phys_rd_old`；flush 按 `amt_snapshot` 重建。  
- busy_table：dispatch set；wakeup clear（**双路**，clear 优先于 set）。  
- wakeup bypass：dispatch 同拍命中 rs 则直接 ready。

---

## 5. 核心模块

### 5.1 ROB（`rob.sv`）

- 循环队列；双路 complete（EXU / LSU 可同拍）。  
- store head：无异常时等 `store_commit_ready`（SQ drain 完成）才退休。  
- `commit_valid = head_ready & ~head_trap`；trap/redirect → `flush_o`。  
- 译码期 illegal：alloc 即 complete+exception，到 head 走 trap。  
- `exc_commit_*`：异常提交观测；顶层写 CSR trap。  
- `head_idx_o`：IQ 年龄与 sys-at-head。

### 5.2 Issue Queue（`issue_queue.sv`）

- 年龄：`(rob_idx - rob_head) mod 32`，选最小。  
- **访存序（保守）**：存在更老 mem 时不可发 mem。  
- **系统指令**：CSR / ecall / mret / fence.i 仅 `rob_idx == head` 可发。  
- 双路 wakeup 广播。

### 5.3 EXU（`exu.sv`）

- 非 mem 组合完成；mem 不 complete。  
- CSR：只把 `csr_src` 写入 ROB.result；**不** EXU wakeup/写 PRF。  
- 误预测 / fence.i / priv：complete 打 `redirect_valid`；目标 ecall/mret 在 commit 覆盖。  
- BPU 更新：valid/type/taken/**pc**/target（pc 必须为指令 PC）。

### 5.4 LSU + Store Queue（Tier2 + Tier3-A）

**不变量**：

1. store 不得在 commit 前进入 AXI。  
2. load 经 SQ CAM：全覆盖前递 / 部分重叠 stall / 无重叠 AXI。  
3. `axi4_full_master` 的 AXADDR/AXSIZE/WSTRB/WDATA **全程直通、不锁存** → LSU 必须在 inflight 期用稳定源驱动。  
4. **不对齐访存不支持**；不做部分字节合并前递。

**Store Queue（`store_queue.sv`，FIFO SQ_DEPTH=8）**：

- issue alloc：addr / **rs2 原值** / strb / size / rob_idx。  
- commit drain：ROB head store 匹配队头 → `drain_req`；fire 后 `committed`；done 后 `commit_ready` → ROB 退休 pop。  
- flush：丢弃未 committed 项；已发起 AXI 的队头跑完。  
- **CAM（load）**：  
  - `same_word = addr[31:2]`；  
  - `ld_mask`：B `0001<<addr[1:0]`，H `0011<<{addr[1],0}`，W `1111`；  
  - 全覆盖：`(st_strb & ld_mask) == ld_mask` → `cam_hit` + 低位对齐 `cam_data`；  
  - 部分重叠：`cam_stall`；  
  - 扫描 **尾→头（幼→老）**，首个重叠项决定 hit/stall。  
  - IQ mem 序保证 SQ 内均为更老 store，无需 rob_idx 比较。  
  - 前递字节摆放与 master WDATA/rdata 一致。  
- `empty_o`：仅 TB/调试；**load 门控不再依赖 empty**。

**LSU（`lsu.sv`）状态 `S_IDLE / S_LOAD / S_DRAIN`**：

| 路径 | 行为 |
|------|------|
| ST issue | 算 addr，入 SQ，同拍 complete；**不** AWVALID |
| LD STLF | `cam_hit`：同拍 complete；**idle 或 drain 中均可**（不占 AXI） |
| LD stall | `cam_stall`：ready=0 |
| LD AXI | `~hit & ~stall & idle & ~drain_req`；阻塞读 |
| ST commit drain | AXI 写完 → `drain_done`（fault → store access fault） |

优先级：drain 占 AXI > AXI load；STLF 不走 AXI。

**master 直通约束（实测必要）**：

- `S_LOAD`：`raddr/rsize` 用 `hold_mem_*`。  
- `S_DRAIN`：`size` 在 `drain_accept|state_drain` 整段选 `drain_size_i`。  
- store data 存 **rs2 原值**，字节摆放只在 master / CAM 做一次。

### 5.5 提交点系统语义（顶层 + `CSR.sv`）

- CSR 读写、ecall/trap、mret、fence.i inval 均在 **commit**。  
- 通用 trap：`trap_i` + `trap_pc_i` + `trap_cause_i`。  
- `commit_result_arch`：CSR 指令为旧 csr_rdata，供 DiffTest。  
- cause：`ILLEGAL=2`，`LOAD_AF=5`，`STORE_AF=7`，`ECALL_M=11`。

### 5.6 物理寄存器堆（`physical_regfile.sv`）

- **2R3W**：port1=EXU complete；port2=LSU load complete；port3=CSR 提交写 rd（port3 优先）。  
- p0 硬 0。

---

## 6. flush / 恢复

```
rob_flush
  → IFU redirect（redirect_pc_final：trap→mtvec，mret→mepc，else rob_flush_pc）
  → rename：RAT ← next_amt；freelist 重建；busy 清零
  → IQ 清空
  → LSU in-flight load 标记 flushed（不 complete）
  → SQ：丢弃未 committed；in-flight drain 跑完
```

---

## 7. 与五级流水对照

| 能力 | 五级 | OoO 现状 |
|------|------|----------|
| ALU/分支/跳转 | ✅ | ✅ 可乱序发射 |
| Load/Store | ✅ 顺序 | ✅ SQ + commit drain + CAM STLF；issue 仍 mem 序 |
| CSR/ecall/mret/fence.i | ✅ WBU | ✅ commit 点 |
| 精确异常 | 弱/少 | ✅ illegal + bus fault + ecall |
| 分支预测训练 | ✅ | ✅（pc 已接线） |
| 遗留源码 | — | `vsrc/legacy/`（不编译；`pip_reg` 仍供 icache） |

---

## 8. 文件布局与仿真契约

| 路径 | 说明 |
|------|------|
| `vsrc/ysyx_24110011.sv` | OoO 顶层 |
| `vsrc/store_queue.sv` | Store Queue + CAM |
| `vsrc/{idu,exu,lsu,rob,issue_queue,rename_* ,freelist,busy_table,physical_regfile,CSR}.sv` | OoO 后端 |
| `vsrc/legacy/` | 五级遗留，勿例化 |
| `vsrc/include/pipeline_pkt_pkg.sv` | 包；含 exception/is_store |
| `csrc/src/cpu_exec.cpp` | commit 驱动仿真 / DiffTest（只读展平信号） |
| `csrc/src/pmc/pmc.cpp` | OoO 轻量 PMC（默认 `CONFIG_PERFORMANCE_COUNTER` 关） |
| `docs/ooo-design.md` | **唯一**设计/状态/路线文档 |

### 8.1 仿真契约

顶层展平 `public_flat_rd`，**禁止**对 `rob_commit_t` / VlWide 手算位偏移：

| 信号 | 用途 |
|------|------|
| `commit_valid` / `commit_pc` / `commit_inst` / `commit_arch_rd` / `commit_rd_wen` / `commit_result_arch` | 顺序提交、DiffTest |
| `rob_flush` / `exu_redirect_valid` | 冲刷 / 误预测观测 |
| `u_lsu__DOT__axi_activity_done` / `mem_addr` / `axi_rdata` / … | mtrace、设备 skip |
| `u_lsu__DOT__stlf_fire_o` / `cam_stall_block` / `load_axi_issue` / `state_load` / `state_drain` | PMC |

改 `rob_commit_t` 或展平口时，同步 `cpu_exec.cpp`。  
可选后续：把 LSU probe **上提顶层**，去掉模块内多余 `public_flat`（行为不变）。

---

## 9. 验证

```bash
make -C npc test
# 路径相对 workbench 根
for img in am-kernels/tests/cpu-tests/build/*-riscv32-npc.bin; do
  [[ $img == *bitrev* ]] && continue
  timeout 60 npc/build/obj-npc/Vysyx -b -d ./npc/libnemu.so "$img"
done
# fence-i 为 riscv32e 镜像
timeout 60 npc/build/obj-npc/Vysyx -b -d ./npc/libnemu.so \
  am-kernels/tests/cpu-tests/build/fence-i-riscv32e-npc.bin
```

单元：`store_queue` 25、`lsu` 54（含 STLF / stall / drain 中 STLF）。  
集成：**25/25 + fence-i**。testbench 源码可本地保留，**不必纳入 git 跟踪**。

---

## 10. 后续可做

| 优先级 | 项 | 性质 | 说明 |
|--------|----|------|------|
| **P0** | 顶层集中 probe，收敛 LSU/IFU 多余 `public_flat` | 工程整理 | 行为不变；契约更清晰 |
| **P1** | **乱序访存 A1**：IQ 放开 load–load（store 仍挡后续相关 mem） | 微架构 | 改动面小，见 §11 |
| **P1** | **乱序访存 A2**：load 越过地址已知且不重叠的更老 store；重叠 STLF/stall | 微架构 | 正确性敏感；现 store issue 即知 addr，条件有利 |
| **P2** | **A3** 双 inflight / 非阻塞 load | 微架构 | 宜在 A1/A2 后；注意 master 直通与 flush |
| **P3** | 双发射（dispatch/issue 宽=2，最好双 commit） | 大改 | 全局端口；见 §11，**不优先** |
| 延期 | RAT checkpoint、部分字节合并、非对齐、复杂 mem 预测 | — | 默认不做 |

---

## 11. 决策备忘：双发射 vs 乱序访存

### 11.1 现状瓶颈

- ALU 路径已可乱序；**mem issue 被 `older_mem` 串行化**。  
- LSU 同时最多 1 个 AXI load；drain 占总线。  
- T3-A 已证明访密有周期可挖，但 `quick-sort` / `select-sort` 等几乎不动 → 卡在 **mem 序 / 单通道**，不是缺第二套 ALU。

### 11.2 乱序访存（推荐主线）

| 子步 | 内容 | 难度 | 风险 |
|------|------|------|------|
| A1 | IQ：放开 load–load | 低 | 低 |
| A2 | load 越过「地址已知 + CAM 不重叠」的更老 store | 中 | **高**（序与转发） |
| A3 | 2× inflight load | 中高 | 中 |

**为何更容易、更划算：**

1. 改动面窄：主战场 IQ 规则 + 已有 SQ/CAM/LSU。  
2. ROB / rename / PRF / IFU 基本不动。  
3. 与 T3-A 基础设施同向，可分期回归。  
4. store **issue 时已算 addr 入 SQ** → A2 不需再等「地址生成阶段」。  
5. 补齐「单发 OoO 访存短板」，叙事与收益一致。

### 11.3 双发射（不优先）

最小也要动：双取/双译或供给、双 rename（同拍 RAW）、双 ROB alloc、IQ 双选、PRF ≥4R、仿真双提交语义；前端仍 1-wide 时双发常饿；commit 宽 1 时退休成瓶颈；**面积/时序与当前目标张力大**。

在 **mem 未放松** 时双发：第二 slot 易被 mem/LSU 空转，ROI 差。

### 11.4 结论

| 维度 | 乱序访存 A1→A2→A3 | 双发射 |
|------|-------------------|--------|
| 实现难度 | **更低**（局部、可分期） | **高**（全局） |
| 与当前代码契合 | **高** | 低 |
| cpu-tests 收益倾向 | 访密 | 算密（且依赖前端/提交） |
| **推荐** | **先做** | mem 与非阻塞稳定后再评估 |

**若只能选一条主线：乱序访存 > 双发射。**  
建议顺序：`A1 → A2 →（可选）A3 →（可选）双 commit / 双 issue`；不要跳步先双发。

---

## 12. 路线图总表

| 档 | 内容 | 状态 |
|----|------|------|
| Tier1 | BPU pc、legacy、TB、文档 | ✅ |
| Tier2 | 异常 + SQ commit 写 + PRF 3W | ✅ |
| Tier3-A | CAM STLF + 非空 SQ 下 AXI load | ✅ |
| 工程清理 | 仿真契约、PMC、注释 | ✅ |
| Tier3-B（=A1/A2） | 访存 issue 放松 | 📋 推荐下一步 |
| Tier3-C（=A3 等） | 多 inflight load；checkpoint 仍默认不做 | 📋 可选 |
| 超标量 | 双发射 | 📋 更后 |
