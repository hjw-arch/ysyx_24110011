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

#define EBREAK_INST 0x00100073u

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

enum pmc_stack_t {
    PMC_STACK_LSU = 0,
    PMC_STACK_ICACHE,
    PMC_STACK_REDIRECT,
    PMC_STACK_RAW,
    PMC_STACK_OTHER,
    PMC_STACK_NR
};

typedef struct {
    uint64_t cycles;
    uint64_t empty_cycles;
    uint64_t retired;

    uint64_t inst[PMC_INST_NR];

    uint64_t ifu_fetch;
    uint64_t ifu_wait_icache;
    uint64_t ifu_wait_backend;
    uint64_t ifu_wait_flush;
    uint64_t ifu_wait_other;

    uint64_t icache_hit;
    uint64_t icache_miss;
    uint64_t icache_miss_cycles;
    uint64_t icache_invalidate;

    uint64_t load_count;
    uint64_t store_count;
    uint64_t load_wait_cycles;
    uint64_t store_wait_cycles;

    uint64_t redirect_count;
    uint64_t redirect_recovery_cycles;
    uint64_t flush_killed_insts;

    uint64_t raw_stall_cycles;
    uint64_t load_use_stall_cycles;
    uint64_t csr_use_stall_cycles;

    uint64_t cpi_stack[PMC_STACK_NR];
} pmc_counter_t;

typedef struct {
    uint32_t pc;
    bool wbu_valid;
    uint32_t wbu_pc;

    bool ifu_fetch;
    bool ifu_backend_stall;
    bool ifu_flush;

    bool icache_hit;
    bool icache_miss;
    bool icache_wait;
    bool icache_invalidate;

    bool load_req;
    bool store_req;
    bool load_busy;
    bool store_busy;

    bool raw_stall;
    bool load_use_stall;
    bool csr_use_stall;
    bool count_younger_side;
} pmc_cycle_sample_t;

typedef struct {
    bool active;
    uint32_t target_pc;
} recovery_t;

typedef struct {
    bool valid;
    uint32_t pc;
    uint32_t inst;
} pmc_wbu_info_t;

static pmc_counter_t pmc;
static recovery_t recovery;

static const char *const inst_key[PMC_INST_NR] = {
    "calculate",
    "load",
    "store",
    "branch",
    "jump",
    "csr",
    "system",
    "fence",
    "unknown"
};

static const char *const stack_key[PMC_STACK_NR] = {
    "lsu",
    "icache",
    "redirect",
    "raw",
    "other"
};

static const char *const stack_name[PMC_STACK_NR] = {
    "LSU busy",
    "ICache/refill",
    "Redirect recovery",
    "RAW hazard",
    "Other"
};

static uint32_t get_wide_bits(const WData *data, int hi, int lo) {
    uint32_t value = 0;
    for (int bit = lo; bit <= hi; bit++) {
        if (data[bit / 32] & (1u << (bit % 32))) {
            value |= 1u << (bit - lo);
        }
    }
    return value;
}

static uint32_t get_lsu_pc() {
    return get_wide_bits(CORE_SIG(ex2ls_data).data(), 168, 137);
}

static pmc_wbu_info_t sample_wbu() {
    pmc_wbu_info_t wbu = {};

    wbu.valid = CORE_SIG(ls2wb_valid);
    wbu.pc = get_wide_bits(CORE_SIG(ls2wb_data).data(), 101, 70);
    wbu.inst = get_wide_bits(CORE_SIG(ls2wb_data).data(), 69, 38);

    return wbu;
}

static bool pmc_pc_enabled(uint32_t pc) {
#ifdef SOC
    return pc >= 0xa0000000u;
#else
    (void)pc;
    return true;
#endif
}

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

static uint64_t icache_accesses() {
    return pmc.icache_hit + pmc.icache_miss;
}

static uint64_t ifu_cycles() {
    return pmc.ifu_fetch + pmc.ifu_wait_icache + pmc.ifu_wait_backend +
           pmc.ifu_wait_flush + pmc.ifu_wait_other;
}

static uint64_t lsu_busy_cycles() {
    return pmc.load_wait_cycles + pmc.store_wait_cycles;
}

static pmc_stack_t choose_stack(bool lsu_busy, bool icache_wait,
                                bool recovery_active, bool raw_stall) {
    if (lsu_busy) return PMC_STACK_LSU;
    if (icache_wait) return PMC_STACK_ICACHE;
    if (recovery_active) return PMC_STACK_REDIRECT;
    if (raw_stall) return PMC_STACK_RAW;
    return PMC_STACK_OTHER;
}

static pmc_cycle_sample_t sample_cycle() {
    pmc_cycle_sample_t sample = {};
    pmc_wbu_info_t wbu = sample_wbu();

    bool ifu_req_stall = CORE_SIG(u_IFU__DOT__ic_req_valid) &&
                         !CORE_SIG(u_IFU__DOT__ic_req_ready);
    bool ifu_resp_valid = CORE_SIG(u_IFU__DOT__ic_resp_valid);
    bool ifu_resp_ready = CORE_SIG(u_IFU__DOT__ic_resp_ready);
    bool icache_busy = CORE_SIG(u_IFU__DOT__u_icache__DOT__state) != 0;

    bool lsu_mem_req_fire = CORE_SIG(u_LSU__DOT__mem_req_fire);
    bool lsu_input_is_load = CORE_SIG(u_LSU__DOT__input_is_load);
    bool lsu_input_is_store = CORE_SIG(u_LSU__DOT__input_is_store);
    bool lsu_wait_resp = CORE_SIG(u_LSU__DOT__state_wait_resp);

    bool rs1_block_ex = CORE_SIG(u_hazard_unit__DOT__rs1_block_ex);
    bool rs2_block_ex = CORE_SIG(u_hazard_unit__DOT__rs2_block_ex);
    bool rs1_block_ls = CORE_SIG(u_hazard_unit__DOT__rs1_block_ls);
    bool rs2_block_ls = CORE_SIG(u_hazard_unit__DOT__rs2_block_ls);
    bool ex_wait = rs1_block_ex || rs2_block_ex;
    bool ls_wait = rs1_block_ls || rs2_block_ls;

    sample.pc = CORE_SIG(u_IFU__DOT__pc_r);
    sample.wbu_valid = wbu.valid;
    sample.wbu_pc = wbu.pc;

    sample.ifu_fetch = ifu_resp_valid && ifu_resp_ready;
    sample.ifu_backend_stall = ifu_resp_valid && !ifu_resp_ready;
    sample.ifu_flush = CORE_SIG(u_IFU__DOT__redirect_valid_i);

    sample.icache_hit = CORE_SIG(u_IFU__DOT__u_icache__DOT__req_hit);
    sample.icache_miss = CORE_SIG(u_IFU__DOT__u_icache__DOT__req_miss);
    sample.icache_wait = icache_busy || ifu_req_stall;
    sample.icache_invalidate = CORE_SIG(u_IFU__DOT__icache_inval_i);

    sample.load_req = lsu_mem_req_fire && lsu_input_is_load;
    sample.store_req = lsu_mem_req_fire && lsu_input_is_store;
    sample.load_busy = sample.load_req || (lsu_wait_resp && lsu_input_is_load);
    sample.store_busy = sample.store_req || (lsu_wait_resp && lsu_input_is_store);

    sample.raw_stall = CORE_SIG(hazard_valid);
    sample.load_use_stall = ex_wait && CORE_SIG(ex_is_load);
    sample.csr_use_stall = (ex_wait && CORE_SIG(ex_is_csr)) ||
                            (ls_wait && CORE_SIG(ls_is_csr));
    sample.count_younger_side = !(wbu.valid && wbu.inst == EBREAK_INST);

    return sample;
}

static void record_recovery_cycle(const pmc_cycle_sample_t *sample) {
    if (!recovery.active) {
        return;
    }

    pmc.redirect_recovery_cycles++;
    if (sample->wbu_valid && sample->wbu_pc == recovery.target_pc) {
        recovery.active = false;
    }
}

static void start_redirect(uint32_t pc, uint32_t target,
                           bool kill_if, bool kill_id, bool kill_ex, bool kill_ls) {
    if (!pmc_pc_enabled(pc)) {
        return;
    }

    pmc.redirect_count++;
    pmc.flush_killed_insts += (uint64_t)kill_if + (uint64_t)kill_id +
                              (uint64_t)kill_ex + (uint64_t)kill_ls;

    recovery.active = true;
    recovery.target_pc = target;
}

static void print_u64(const char *name, uint64_t value) {
    printf("  %-28s %llu\n", name, (unsigned long long)value);
}

static void print_ratio(const char *name, uint64_t part, uint64_t total) {
    if (total == 0) {
        printf("  %-28s n/a\n", name);
        return;
    }
    printf("  %-28s %.2f%%\n", name, 100.0 * (double)part / (double)total);
}

static void print_avg(const char *name, uint64_t part, uint64_t total) {
    if (total == 0) {
        printf("  %-28s n/a\n", name);
        return;
    }
    printf("  %-28s %.2f\n", name, (double)part / (double)total);
}

void PerformanceCounter_record_cycle() {
    pmc_cycle_sample_t sample = sample_cycle();
    if (!pmc_pc_enabled(sample.pc)) {
        return;
    }

    bool empty_retire = !sample.wbu_valid;

    pmc.cycles++;
    if (empty_retire) {
        pmc.empty_cycles++;
    }

    if (sample.ifu_fetch) {
        pmc.ifu_fetch++;
    } else if (sample.ifu_backend_stall) {
        pmc.ifu_wait_backend++;
    } else if (sample.ifu_flush) {
        pmc.ifu_wait_flush++;
    } else if (sample.icache_wait) {
        pmc.ifu_wait_icache++;
    } else {
        pmc.ifu_wait_other++;
    }

    if (sample.icache_hit) pmc.icache_hit++;
    if (sample.icache_miss) pmc.icache_miss++;
    if (sample.icache_wait) pmc.icache_miss_cycles++;
    if (sample.icache_invalidate) pmc.icache_invalidate++;

    if (sample.count_younger_side) {
        if (sample.load_req) pmc.load_count++;
        if (sample.store_req) pmc.store_count++;
        if (sample.load_busy) pmc.load_wait_cycles++;
        if (sample.store_busy) pmc.store_wait_cycles++;
    }

    if (sample.raw_stall) pmc.raw_stall_cycles++;
    if (sample.load_use_stall) pmc.load_use_stall_cycles++;
    if (sample.csr_use_stall) pmc.csr_use_stall_cycles++;

    if (empty_retire) {
        pmc.cpi_stack[choose_stack(sample.load_busy || sample.store_busy, sample.icache_wait,
                                   recovery.active, sample.raw_stall)]++;
    }

    record_recovery_cycle(&sample);
}

void PerformanceCounter_record_lsu_redirect() {
    start_redirect(get_lsu_pc(), CORE_SIG(lsu_redirect_pc),
                   CORE_SIG(if2id_pre_valid), CORE_SIG(if2id_valid),
                   CORE_SIG(id2ex_valid), false);
}

void PerformanceCounter_record_wbu_redirect() {
    pmc_wbu_info_t wbu = sample_wbu();

    start_redirect(wbu.pc, CORE_SIG(wbu_redirect_pc),
                   CORE_SIG(if2id_pre_valid), CORE_SIG(if2id_valid),
                   CORE_SIG(id2ex_valid), CORE_SIG(ex2ls_valid));
}

void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles) {
    (void)retire_cycles;

    if (!pmc_pc_enabled(pc)) {
        return;
    }

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
        json.attribute("schema", "npc-pmc-v3");
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

        json.attributeObject("ifu", [&] {
            json_count(json, "fetch", pmc.ifu_fetch);
            json_count(json, "wait_icache", pmc.ifu_wait_icache);
            json_count(json, "wait_backend", pmc.ifu_wait_backend);
            json_count(json, "wait_flush", pmc.ifu_wait_flush);
            json_count(json, "wait_other", pmc.ifu_wait_other);
        });

        json.attributeObject("icache", [&] {
            json_count(json, "access", icache_accesses());
            json_count(json, "hit", pmc.icache_hit);
            json_count(json, "miss", pmc.icache_miss);
            json_count(json, "miss_cycles", pmc.icache_miss_cycles);
            json_count(json, "invalidate", pmc.icache_invalidate);
        });

        json.attributeObject("lsu", [&] {
            json_count(json, "load", pmc.load_count);
            json_count(json, "store", pmc.store_count);
            json_count(json, "load_wait_cycles", pmc.load_wait_cycles);
            json_count(json, "store_wait_cycles", pmc.store_wait_cycles);
            json_count(json, "busy_cycles", lsu_busy_cycles());
        });

        json.attributeObject("control", [&] {
            json_count(json, "redirect", pmc.redirect_count);
            json_count(json, "redirect_recovery_cycles", pmc.redirect_recovery_cycles);
            json_count(json, "flush_killed_insts", pmc.flush_killed_insts);
        });

        json.attributeObject("stall", [&] {
            json_count(json, "raw", pmc.raw_stall_cycles);
            json_count(json, "load_use", pmc.load_use_stall_cycles);
            json_count(json, "csr_use", pmc.csr_use_stall_cycles);
        });

        json.attributeObject("cpi_stack", [&] {
            for (int i = 0; i < PMC_STACK_NR; i++) {
                json_count(json, stack_key[i], pmc.cpi_stack[i]);
            }
        });
    });
    json.flush();

    printf("Performance counter JSON written to %s\n", path);
}

void PerformanceCounter_display() {
    uint64_t icache_total = icache_accesses();

    printf(ANSI_FG_YELLOW "===== CPU Performance Counter Statistics =====\n" ANSI_NONE);
    printf(ANSI_FG_CYAN "\n[Main program]\n" ANSI_NONE);

    if (pmc.cycles == 0 && pmc.retired == 0) {
        printf("  No main-program samples recorded.\n");
        printf(ANSI_FG_YELLOW "\n===== End of Statistics =====\n" ANSI_NONE);
        return;
    }

    printf("\n  Overview\n");
    print_u64("Cycles:", pmc.cycles);
    print_u64("Retired instructions:", pmc.retired);
    print_avg("CPI:", pmc.cycles, pmc.retired);
    print_avg("IPC:", pmc.retired, pmc.cycles);
    print_u64("Empty cycles:", pmc.empty_cycles);

    printf("\n  Instruction Mix\n");
    for (int i = 0; i < PMC_INST_NR; i++) {
        print_u64(inst_key[i], pmc.inst[i]);
    }

    printf("\n  Frontend\n");
    print_u64("IFU fetch:", pmc.ifu_fetch);
    print_u64("IFU total cycles:", ifu_cycles());
    print_u64("IFU wait icache:", pmc.ifu_wait_icache);
    print_u64("IFU wait backend:", pmc.ifu_wait_backend);
    print_u64("IFU wait flush:", pmc.ifu_wait_flush);
    print_u64("IFU wait other:", pmc.ifu_wait_other);
    print_u64("ICache hits:", pmc.icache_hit);
    print_u64("ICache misses:", pmc.icache_miss);
    print_ratio("ICache hit rate:", pmc.icache_hit, icache_total);
    print_u64("ICache miss cycles:", pmc.icache_miss_cycles);
    print_u64("ICache invalidates:", pmc.icache_invalidate);

    printf("\n  LSU\n");
    print_u64("Load requests:", pmc.load_count);
    print_u64("Load wait cycles:", pmc.load_wait_cycles);
    print_avg("Avg load cycles:", pmc.load_wait_cycles, pmc.load_count);
    print_u64("Store requests:", pmc.store_count);
    print_u64("Store wait cycles:", pmc.store_wait_cycles);
    print_avg("Avg store cycles:", pmc.store_wait_cycles, pmc.store_count);
    print_u64("LSU busy cycles:", lsu_busy_cycles());

    printf("\n  Control\n");
    print_u64("Redirects:", pmc.redirect_count);
    print_u64("Redirect recovery cycles:", pmc.redirect_recovery_cycles);
    print_u64("Flush killed insts:", pmc.flush_killed_insts);

    printf("\n  RAW Stalls\n");
    print_u64("RAW stall cycles:", pmc.raw_stall_cycles);
    print_u64("Load-use stall cycles:", pmc.load_use_stall_cycles);
    print_u64("CSR-use stall cycles:", pmc.csr_use_stall_cycles);

    printf("\n  CPI Stack (empty cycles)\n");
    for (int i = 0; i < PMC_STACK_NR; i++) {
        print_ratio(stack_name[i], pmc.cpi_stack[i], pmc.empty_cycles);
    }

    printf(ANSI_FG_YELLOW "\n===== End of Statistics =====\n" ANSI_NONE);
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
