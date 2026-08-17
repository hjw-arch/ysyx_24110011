// OoO 轻量性能计数（单发射）
// 依赖顶层/LSU 展平 public 信号；不再采样五级 ex2ls/ls2wb/hazard_unit

#include "pmc.h"
#include "config.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef CONFIG_PERFORMANCE_COUNTER

#include <llvm/Support/JSON.h>
#include <llvm/Support/raw_ostream.h>

#include "common.h"
#include "log.h"

#ifdef SOC
#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
extern VysyxSoCFull dut;
#define CORE_SIG(name) dut.rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__##name
#else
#include "Vysyx.h"
#include "Vysyx___024root.h"
extern Vysyx dut;
#define CORE_SIG(name) dut.rootp->ysyx__DOT__u_cpu__DOT__##name
#endif

enum pmc_inst_t {
    PMC_INST_CAL = 0,
    PMC_INST_LOAD,
    PMC_INST_STORE,
    PMC_INST_BRANCH,
    PMC_INST_JUMP,
    PMC_INST_CSR,
    PMC_INST_SYSTEM,
    PMC_INST_FENCE,
    PMC_INST_UNKNOWN,
    PMC_INST_NR
};

typedef struct {
    uint64_t cycles;
    uint64_t empty_cycles;
    uint64_t retired;
    uint64_t inst[PMC_INST_NR];

    uint64_t rob_flush;
    uint64_t exu_redirect;

    uint64_t stlf_fire;
    uint64_t cam_stall_cycles;
    uint64_t load_axi_issue;
    uint64_t load_axi_busy_cycles;
    uint64_t drain_busy_cycles;
} pmc_counter_t;

static pmc_counter_t pmc;

static const char *const inst_key[PMC_INST_NR] = {
    "calculate", "load", "store", "branch", "jump",
    "csr", "system", "fence", "unknown"
};

static inline uint32_t bits(uint32_t value, int hi, int lo) {
    return (value >> lo) & ((1u << (hi - lo + 1)) - 1u);
}

static pmc_inst_t classify_inst(uint32_t inst) {
    uint32_t opcode = bits(inst, 6, 2);
    uint32_t funct3 = bits(inst, 14, 12);

    switch (opcode) {
        case 0x00: return PMC_INST_LOAD;
        case 0x08: return PMC_INST_STORE;
        case 0x18: return PMC_INST_BRANCH;
        case 0x19:
        case 0x1b:
            return PMC_INST_JUMP;
        case 0x1c:
            return funct3 != 0 ? PMC_INST_CSR : PMC_INST_SYSTEM;
        case 0x03:
            return PMC_INST_FENCE;
        case 0x04:
        case 0x05:
        case 0x0c:
        case 0x0d:
            return PMC_INST_CAL;
        default:
            return PMC_INST_UNKNOWN;
    }
}

static void print_u64(const char *name, uint64_t value) {
    printf("  %-28s %llu\n", name, (unsigned long long)value);
}

static void print_avg(const char *name, uint64_t part, uint64_t total) {
    if (total == 0) {
        printf("  %-28s n/a\n", name);
        return;
    }
    printf("  %-28s %.2f\n", name, (double)part / (double)total);
}

void PerformanceCounter_record_cycle() {
    pmc.cycles++;

    if (!CORE_SIG(commit_valid)) {
        pmc.empty_cycles++;
    }

    if (CORE_SIG(rob_flush)) {
        pmc.rob_flush++;
    }
    if (CORE_SIG(exu_redirect_valid)) {
        pmc.exu_redirect++;
    }

    // LSU 观测（组合脉冲 / 状态）
    if (CORE_SIG(u_lsu__DOT__stlf_fire_o)) {
        pmc.stlf_fire++;
    }
    if (CORE_SIG(u_lsu__DOT__cam_stall_block)) {
        pmc.cam_stall_cycles++;
    }
    if (CORE_SIG(u_lsu__DOT__load_axi_issue)) {
        pmc.load_axi_issue++;
    }
    if (CORE_SIG(u_lsu__DOT__state_load)) {
        pmc.load_axi_busy_cycles++;
    }
    if (CORE_SIG(u_lsu__DOT__state_drain)) {
        pmc.drain_busy_cycles++;
    }
}

void PerformanceCounter_record_lsu_redirect() {
    // OoO：误预测在 EXU complete 记入 ROB，冲刷在 rob_flush
    // 保留 API；周期采样已计 exu_redirect_valid
}

void PerformanceCounter_record_wbu_redirect() {
    // 同上；rob_flush 在 record_cycle 中计数
}

void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles) {
    (void)pc;
    (void)retire_cycles;
    pmc.retired++;
    pmc.inst[classify_inst(inst)]++;
}

static void json_count(llvm::json::OStream &json, const char *key, uint64_t value) {
    json.attribute(key, value);
}

void PerformanceCounter_export_json() {
    const char *path = getenv("NPC_PMC_JSON");
    if (path == NULL || path[0] == '\0') {
        return;
    }

    std::error_code ec;
    llvm::raw_fd_ostream os(path, ec);
    if (ec) {
        printf("open NPC_PMC_JSON failed: %s\n", ec.message().c_str());
        return;
    }

    llvm::json::OStream json(os, 2);
    json.object([&] {
        json.attribute("schema", "npc-pmc-ooo-v1");
#ifdef SOC
        json.attribute("target", "soc");
#else
        json.attribute("target", "npc");
#endif
        json.attributeObject("overview", [&] {
            json_count(json, "cycles", pmc.cycles);
            json_count(json, "retired", pmc.retired);
            json_count(json, "empty_cycles", pmc.empty_cycles);
        });
        json.attributeObject("instructions", [&] {
            for (int i = 0; i < PMC_INST_NR; i++) {
                json_count(json, inst_key[i], pmc.inst[i]);
            }
        });
        json.attributeObject("control", [&] {
            json_count(json, "rob_flush", pmc.rob_flush);
            json_count(json, "exu_redirect", pmc.exu_redirect);
        });
        json.attributeObject("mem", [&] {
            json_count(json, "stlf_fire", pmc.stlf_fire);
            json_count(json, "cam_stall_cycles", pmc.cam_stall_cycles);
            json_count(json, "load_axi_issue", pmc.load_axi_issue);
            json_count(json, "load_axi_busy_cycles", pmc.load_axi_busy_cycles);
            json_count(json, "drain_busy_cycles", pmc.drain_busy_cycles);
        });
    });
    json.flush();
    printf("Performance counter JSON written to %s\n", path);
}

void PerformanceCounter_display() {
    printf(ANSI_FG_YELLOW "===== OoO Performance Counter =====\n" ANSI_NONE);

    if (pmc.cycles == 0 && pmc.retired == 0) {
        printf("  No samples recorded.\n");
        printf(ANSI_FG_YELLOW "===== End =====\n" ANSI_NONE);
        return;
    }

    printf("\n  Overview\n");
    print_u64("Cycles:", pmc.cycles);
    print_u64("Retired:", pmc.retired);
    print_avg("CPI:", pmc.cycles, pmc.retired);
    print_avg("IPC:", pmc.retired, pmc.cycles);
    print_u64("Empty (no commit):", pmc.empty_cycles);

    printf("\n  Instruction Mix\n");
    for (int i = 0; i < PMC_INST_NR; i++) {
        print_u64(inst_key[i], pmc.inst[i]);
    }

    printf("\n  Control\n");
    print_u64("ROB flush:", pmc.rob_flush);
    print_u64("EXU redirect mark:", pmc.exu_redirect);

    printf("\n  Memory (LSU/SQ)\n");
    print_u64("STLF fire:", pmc.stlf_fire);
    print_u64("CAM stall cycles:", pmc.cam_stall_cycles);
    print_u64("Load AXI issue:", pmc.load_axi_issue);
    print_u64("Load AXI busy cycles:", pmc.load_axi_busy_cycles);
    print_u64("Drain busy cycles:", pmc.drain_busy_cycles);
    print_avg("Avg AXI load occ:", pmc.load_axi_busy_cycles, pmc.load_axi_issue);

    printf(ANSI_FG_YELLOW "\n===== End =====\n" ANSI_NONE);
}

#else

void PerformanceCounter_display() {}
void PerformanceCounter_export_json() {}
void PerformanceCounter_record_cycle() {}
void PerformanceCounter_record_lsu_redirect() {}
void PerformanceCounter_record_wbu_redirect() {}
void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles) {
    (void)pc;
    (void)inst;
    (void)retire_cycles;
}

#endif
