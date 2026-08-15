# 单发射乱序执行（Single-Issue OoO）处理器设计文档

## 项目信息

- **项目名称**：NPC 单发射乱序执行改造
- **开始日期**：2026-08-15
- **Git 分支**：OoO_pre
- **目标**：将 NPC 从单发射顺序流水线改造为单发射乱序执行流水线

---

## 一、架构概览

### 1.1 流水线组织

**旧架构（5级顺序）**：
```
┌─────┬─────┬─────┬─────┬─────┐
│ IF  │ ID  │ EX  │ LS  │ WB  │
└─────┴─────┴─────┴─────┴─────┘
```

**新架构（7阶段乱序）**：
```
┌─────┬────────┬────────┬───────────┬─────────┬─────────┬────────┐
│ IF  │ Decode │ Rename │  Issue    │ RegRead │ Execute │ Commit │
│     │        │Dispatch│  Queue    │         │Writeback│  (ROB) │
└─────┴────────┴────────┴───────────┴─────────┴─────────┴────────┘
  ↑───── 有序前端 ─────↑  ↑───── 乱序后端 ─────↑  ↑─ 有序提交 ─↑
```

### 1.2 核心参数

| 参数 | 值 | 说明 |
|-----|---|------|
| ROB_SIZE | 32 | 重排序缓冲深度 |
| IQ_SIZE | 8 | 发射队列深度 |
| NUM_PHYS_REGS | 64 | 物理寄存器数量 |
| NUM_ARCH_REGS | 32 | 架构寄存器数量（RV32I）|
| MAX_BR_COUNT | 8 | 最多跟踪分支数 |
| FETCH_WIDTH | 1 | 每周期取指数量 |
| DECODE_WIDTH | 1 | 每周期解码数量 |
| ISSUE_WIDTH | 1 | 每周期发射数量 |
| COMMIT_WIDTH | 1 | 每周期提交数量 |

---

## 二、新增模块设计

### 2.1 物理寄存器堆（physical_regfile.sv）

**功能**：存储 64 个物理寄存器，支持多端口读写

**参数**：
- 64 个物理寄存器（p0-p63）
- 2 个读端口（rs1, rs2）
- 2 个写端口（ALU, LSU）

**关键特性**：
- p0 硬连线为 0（RISC-V x0 约定）
- 支持同周期写后读旁路

---

### 2.2 空闲列表（freelist.sv）

**功能**：跟踪物理寄存器的分配状态

**实现**：
- 位向量：64 位，1 表示空闲
- 初始化：p0-p31 占用（映射架构寄存器），p32-p63 空闲
- 优先编码器：找第一个空闲寄存器

**操作**：
- 分配：重命名阶段请求，返回空闲寄存器编号
- 释放：提交阶段释放旧物理寄存器

---

### 2.3 重命名映射表（rename_map_table.sv）

**功能**：维护架构寄存器到物理寄存器的映射

**数据结构**：
```systemverilog
logic [5:0] map_table [32];  // 32 个架构寄存器 → 64 个物理寄存器
```

**初始化**：恒等映射（x0→p0, x1→p1, ..., x31→p31）

**操作**：
- 查询：给定架构寄存器编号，返回对应物理寄存器编号（组合逻辑）
- 更新：重命名时更新映射（时序逻辑）

---

### 2.4 忙碌表（busy_table.sv）

**功能**：跟踪物理寄存器的就绪状态

**数据结构**：
```systemverilog
logic [63:0] busy_table;  // 位向量：0=就绪，1=忙碌
```

**操作**：
- 设置忙碌：重命名阶段分配新物理寄存器时
- 清除忙碌：执行单元写回时（唤醒）
- 查询：重命名阶段查询源操作数是否就绪

---

### 2.5 重排序缓冲（rob.sv）

**功能**：维护程序序，支持乱序完成、顺序提交、精确异常

**数据结构**：
```systemverilog
typedef struct packed {
    logic       valid;
    logic       complete;       // 执行完成标志
    logic [31:0] pc;
    logic [4:0] arch_rd;
    logic [5:0] phys_rd;
    logic [5:0] phys_rd_old;    // 提交时释放
    logic [31:0] result;
    logic       rd_wen;
    logic       exception;
} rob_entry_t;

rob_entry_t rob [32];
```

**管理**：
- 循环队列：`rob_head`（提交指针），`rob_tail`（分配指针）
- 分配：重命名阶段分配 ROB 项
- 完成：执行单元完成时标记对应 ROB 项
- 提交：ROB 头部完成的指令按序提交

**提交条件**：
```systemverilog
commit_valid = rob[head].valid && rob[head].complete && !rob[head].exception
```

---

### 2.6 发射队列（issue_queue.sv）

**功能**：存储等待执行的指令，跟踪操作数就绪状态，选择就绪指令发射

**数据结构**：
```systemverilog
typedef struct packed {
    logic       valid;
    logic [4:0] rob_idx;
    logic [5:0] phys_rs1, phys_rs2, phys_rd;
    logic       rs1_ready, rs2_ready;
    logic [31:0] imm;
    ex_ctrl_t   ex;
    mem_ctrl_t  mem;
} iq_entry_t;

iq_entry_t iq [8];
```

**关键逻辑**：

1. **就绪检测**：
   ```systemverilog
   ready = rs1_ready && rs2_ready
   ```

2. **选择算法**（年龄优先）：
   ```systemverilog
   // 选择 ROB index 最小的就绪指令
   for (int i = 0; i < IQ_SIZE; i++) begin
       if (iq[i].valid && iq[i].rs1_ready && iq[i].rs2_ready) begin
           if (iq[i].rob_idx < min_rob_idx) begin
               min_rob_idx = iq[i].rob_idx;
               selected_idx = i;
           end
       end
   end
   ```

3. **唤醒逻辑**：
   ```systemverilog
   // 监听写回总线，广播写回的物理寄存器编号
   if (wakeup_valid) begin
       for (int i = 0; i < IQ_SIZE; i++) begin
           if (iq[i].phys_rs1 == wakeup_preg) iq[i].rs1_ready <= 1'b1;
           if (iq[i].phys_rs2 == wakeup_preg) iq[i].rs2_ready <= 1'b1;
       end
   end
   ```

---

### 2.7 重命名阶段（rename_stage.sv）

**功能**：集成映射表、空闲列表、忙碌表，执行寄存器重命名

**工作流程**：
1. 从 Decode 阶段接收指令
2. 查询映射表：rs1/rs2/rd → 物理寄存器
3. 从空闲列表分配新物理寄存器给 rd
4. 更新映射表：rd_arch → rd_phys_new
5. 查询忙碌表：rs1/rs2 是否就绪
6. 分配 ROB 项
7. 输出到 Issue Queue

---

## 三、现有模块修改

### 3.1 保留模块（100% 复用）

- **ALU.sv**：纯组合逻辑，无需修改
- **BPU.sv**：分支预测逻辑，无需修改
- **CSR.sv**：CSR 寄存器，无需修改
- **AXI 基础设施**：axi4_full_master.sv, axi4_full_arbiter.sv 等
- **icache.sv**：指令缓存

### 3.2 修改模块

#### IFU.sv（85% 复用）
**保留**：ICache、BPU、PC 逻辑
**修改**：刷新信号源从 EXU 改为 ROB

#### IDU.sv（70% 复用）
**保留**：解码逻辑、立即数生成、控制信号
**删除**：寄存器堆读取、前递选择
**新增**：输出架构寄存器编号

#### EXU.sv（60% 复用）
**保留**：ALU 实例、分支比较
**删除**：前递 mux
**修改**：从 Issue Queue 接收指令，输出完成信号和唤醒广播

#### LSU.sv（40% 复用）
**保留**：AXI 接口、Load 类型解码
**修改**：添加 ROB 索引跟踪，完成时报告给 ROB
**初期**：保持阻塞（后续改为乱序访存）

#### WBU.sv（20% 复用）
**改造**：从写回阶段改为 ROB 提交逻辑

### 3.3 移除模块

- **hazard_unit.sv**：OoO 通过重命名消除冒险
- **pip_reg.sv**：流水线寄存器替换为队列（ROB、IQ）
- **registerfile.sv**：替换为 physical_regfile.sv

---

## 四、数据结构定义

### 4.1 新增类型（pipeline_pkt_pkg.sv）

```systemverilog
// 物理寄存器编号
typedef logic [5:0] phys_reg_t;

// ROB 索引
typedef logic [4:0] rob_idx_t;

// Decode → Rename
typedef struct packed {
    logic [31:0]    pc;
    logic [31:0]    inst;
    logic [4:0]     rs1_arch;
    logic [4:0]     rs2_arch;
    logic [4:0]     rd_arch;
    logic           rs1_used;
    logic           rs2_used;
    logic           rd_wen;
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic [31:0]    imm;
} decode_pkt_t;

// Rename → Issue Queue
typedef struct packed {
    logic [31:0]    pc;
    logic [31:0]    inst;
    rob_idx_t       rob_idx;
    phys_reg_t      phys_rs1;
    phys_reg_t      phys_rs2;
    phys_reg_t      phys_rd;
    logic           rs1_ready;
    logic           rs2_ready;
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic [31:0]    imm;
} rename2issue_pkt_t;

// Issue Queue → Execute
typedef struct packed {
    logic [31:0]    pc;
    logic [31:0]    inst;
    rob_idx_t       rob_idx;
    phys_reg_t      phys_rd;
    logic [31:0]    rs1_data;
    logic [31:0]    rs2_data;
    ex_ctrl_t       ex;
    mem_ctrl_t      mem;
    sys_ctrl_t      sys;
    logic [31:0]    imm;
} issue2ex_pkt_t;

// ROB 分配
typedef struct packed {
    logic [31:0]    pc;
    logic [31:0]    inst;
    logic [4:0]     arch_rd;
    phys_reg_t      phys_rd;
    phys_reg_t      phys_rd_old;
    logic           rd_wen;
    sys_ctrl_t      sys;
} rob_alloc_pkt_t;

// ROB 提交
typedef struct packed {
    logic           valid;
    logic [4:0]     arch_rd;
    phys_reg_t      phys_rd_old;
    logic [31:0]    result;
    logic           rd_wen;
    sys_ctrl_t      sys;
    redirect_t      redirect;
} rob_commit_t;
```

---

## 五、实施计划

### 阶段 0：准备工作（1 天）✅
- [x] 创建 Git 分支 `OoO_pre`
- [ ] 运行基准测试，记录当前性能
- [x] 创建设计文档

### 阶段 1：基础设施模块（3-4 天）
- [ ] 物理寄存器堆（0.5 天）
- [ ] 空闲列表（0.5 天）
- [ ] 重命名映射表（0.5 天）
- [ ] 忙碌表（0.5 天）
- [ ] ROB（1 天）
- [ ] 发射队列（1 天）

### 阶段 2：重命名阶段集成（2 天）
- [ ] 更新 pipeline_pkt_pkg.sv
- [ ] 创建 rename_stage.sv
- [ ] 集成测试

### 阶段 3：修改现有模块（2-3 天）
- [ ] 修改 IDU.sv
- [ ] 修改 EXU.sv
- [ ] 修改 LSU.sv
- [ ] 改造 WBU.sv

### 阶段 4：顶层集成（2-3 天）
- [ ] 修改 ysyx_24110011.sv
- [ ] 连接所有模块
- [ ] 通过编译

### 阶段 5：功能验证（3-5 天）
- [ ] 简单指令测试
- [ ] WAW/WAR 测试
- [ ] 分支测试
- [ ] 访存测试
- [ ] riscv-tests

### 阶段 6：分支处理优化（2 天）
- [ ] 分支检查点
- [ ] 快速恢复

### 阶段 7：性能测试（2-3 天）
- [ ] 性能计数器
- [ ] IPC 测量
- [ ] 瓶颈分析
- [ ] 文档完善

---

## 六、预期成果

- ✅ 完整的单发射乱序执行处理器
- ✅ 通过 riscv-tests
- ✅ IPC 提升 20-40%（相比顺序流水线）
- ✅ 简历亮点：乱序执行、寄存器重命名、ROB、动态调度

---

## 七、参考资料

1. **BOOM 处理器**：Berkeley Out-of-Order Machine
   - GitHub: https://github.com/riscv-boom/riscv-boom
   - 文档: https://docs.boom-core.org/

2. **经典 OoO 处理器**：
   - MIPS R10000
   - Alpha 21264

3. **计算机体系结构：量化研究方法**（Hennessy & Patterson）
   - 第 3 章：指令级并行
   - 附录 C：流水线

---

## 八、变更记录

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2026-08-15 | 1.0 | 初始版本，创建设计文档 | - |
