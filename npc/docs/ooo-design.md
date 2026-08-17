# 单发射乱序执行（Single-Issue OoO）设计文档

> 分支：`OoO_pre`  
> 状态：与 `vsrc/` 实现同步（Tier1 起）；Tier2/3 路线见文末。

## 1. 目标与原则

将 NPC 从五级顺序流水改造为**单发射乱序**：

- 有序前端：IFU → idu → rename/dispatch  
- 乱序后端：IQ → EXU / LSU  
- 有序提交：ROB commit（架构状态唯一提交点）

**正确性不变量（对照 H&P / 超标量教材）**：

1. 架构状态（AMT 映射、CSR、**内存**）只在 ROB **commit** 对外部不可回滚。  
2. 推测执行可写 PRF、占 SQ，但 **store 不得在 commit 前进入 AXI**（Tier2 起强制；Tier1 仍为阻塞 LSU + IQ mem 序保守正确）。  
3. flush 只信任 `rob.flush_o`；恢复用 **next_amt（含同拍 commit）** 重建 RAT 与 freelist。  
4. 宽度：dispatch/issue/commit 均为 1。

风格：组合优先 `assign`，时序 always 浅，中文注释写不变量。

## 2. 流水线组织

```
IFU → idu → rename_stage → issue_queue → ┬→ exu  ── complete1 ──┐
                                         │                      ├→ ROB → commit
                                         └→ lsu  ── complete2 ──┘      ├→ AMT / freelist
                                                                       ├→ CSR / trap / fence.i
                                                                       └→ redirect / icache_inval
                              physical_regfile ← complete 写回 + CSR 提交写 rd
                              wakeup ×2 → rename busy_table + IQ
```

| 参数 | 值 | 说明 |
|------|----|------|
| ROB_SIZE | 32 | 重排序缓冲 |
| IQ_SIZE | 8 | 发射队列 |
| NUM_PHYS_REGS | 64 | 物理寄存器（p0= x0 恒 0） |
| NUM_ARCH_REGS | 32 | RV32I |
| FETCH/DECODE/ISSUE/COMMIT_WIDTH | 1 | 单发射 |

## 3. 双表重命名（RAT + AMT）

| 表 | 模块字段 | 更新时机 | 作用 |
|----|----------|----------|------|
| **RAT**（推测） | `rename_map_table.map_table` | dispatch 分配新 phys_rd | 源操作数重命名 |
| **AMT**（架构） | `rename_map_table.arch_map` | **commit** 且 rd_wen | 提交后 arch→phys |
| next_amt | 组合：AMT 合入本拍 commit | flush 当拍 | 恢复 RAT；freelist 快照 |

- freelist：p0 永不分配/释放；commit 归还 `phys_rd_old`；flush 按 `amt_snapshot` 重建。  
- busy_table：dispatch set；wakeup clear（**双路**，clear 优先于 set）。  
- wakeup bypass：dispatch 同拍命中 rs 则直接 ready。

## 4. 核心模块

### 4.1 ROB（`rob.sv`）

- 循环队列；双路 complete（EXU / LSU 可同拍）。  
- `commit_valid = head.valid & complete & !exception`。  
- 分支误预测：head 仍可 commit（如 JAL 写链路），同时 `flush_o` 清 younger。  
- `flush_pc`：redirect 用 `redirect_addr`，异常用 `pc+4` 占位（顶层 ecall/mret 覆盖为 mtvec/mepc）。  
- `head_idx_o`：IQ 年龄与 sys-at-head。

### 4.2 Issue Queue（`issue_queue.sv`）

- 年龄：`(rob_idx - rob_head) mod 32`，选最小。  
- **访存序（保守）**：存在更老 mem 时不可发 mem（无 LSQ 时的正确性保险丝）。  
- **系统指令**：CSR / ecall / mret / fence.i 仅 `rob_idx == head` 可发。  
- 双路 wakeup 广播。

### 4.3 EXU（`exu.sv`）

- 非 mem 组合完成；mem 不 complete。  
- CSR：只把 `csr_src` 写入 ROB.result；**不** EXU wakeup/写 PRF。  
- 误预测 / fence.i / priv：complete 打 `redirect_valid`；目标 ecall/mret 在 commit 覆盖。  
- BPU 更新：valid/type/taken/**pc**/target（pc 必须为指令 PC）。

### 4.4 LSU（`lsu.sv`）— Tier1

- 阻塞 IDLE/WAIT_RESP；锁存字段；flush 丢弃 complete。  
- load complete → PRF + wakeup；store 当前仍可能在 issue 后走 AXI（**Tier2 改为 SQ + commit drain**）。

### 4.5 提交点系统语义（顶层 + `CSR.sv`）

对齐五级 `WBU.sv`：

- CSR 读写、ecall（mepc/mcause/mtvec）、mret、fence.i inval 均在 **commit**。  
- `commit_result_arch`：CSR 指令为旧 csr_rdata，供 DiffTest。  
- PRF：port1=EXU 普通完成；port2=CSR 提交优先否则 LSU load（Tier2 将加 port3）。

### 4.6 物理寄存器堆（`physical_regfile.sv`）

- 2R2W（Tier2→2R3W）；p0 硬 0；同拍双写 port2 优先。

## 5. flush / 恢复

```
rob_flush
  → IFU redirect（redirect_pc_final）
  → rename：RAT ← next_amt；freelist 重建；busy 清零
  → IQ 清空
  → LSU in-flight 标记 flushed（不 complete）
```

## 6. 与五级流水对照

| 能力 | 五级 | OoO 现状 |
|------|------|----------|
| ALU/分支/跳转 | ✅ | ✅ |
| Load/Store | ✅ 顺序 | ✅ 阻塞 + IQ mem 序 |
| CSR/ecall/mret/fence.i | ✅ WBU | ✅ commit 点 |
| 精确异常 | 弱/少 | 通道有，生产者 Tier2 补 |
| 分支预测训练 | ✅ | ✅（pc 已接线） |
| 遗留源码 | — | `vsrc/legacy/`（不编译） |

## 7. 文件布局

| 路径 | 说明 |
|------|------|
| `vsrc/ysyx_24110011.sv` | OoO 顶层 |
| `vsrc/{idu,exu,lsu,rob,issue_queue,rename_* ,freelist,busy_table,physical_regfile}.sv` | OoO 后端 |
| `vsrc/legacy/` | 五级遗留，勿例化 |
| `vsrc/include/pipeline_pkt_pkg.sv` | 包；含 legacy 五级 pkt 标注 |
| `csrc/src/cpu_exec.cpp` | commit 驱动仿真 / DiffTest |

## 8. 验证

```bash
make -C npc test
# 经典集（除 bitrev）
for img in am-kernels/tests/cpu-tests/build/*-riscv32-npc.bin; do
  [[ $img == *bitrev* ]] && continue
  build/obj-npc/Vysyx -b -d ./libnemu.so "$img"
done
```

## 9. 路线图

| 档 | 内容 | 状态 |
|----|------|------|
| **Tier1** | BPU pc、文档、legacy 隔离、定向 TB、回归 | ✅ 完成 |
| **Tier2** | 精确异常；**Store Queue**（commit 后 AXI 写）；PRF 3W | 待做 |
| **Tier3** | 非阻塞 load；地址不重叠越过；STLF；可选 checkpoint | 待做 |

明确不做（本阶段）：双发射、复杂 mem 预测、多 ALU。
