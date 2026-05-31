#include "common.h"
#include "log.h"
#include <stdint.h>
#include <stdio.h>

enum pmc_region_t {
    PMC_BOOT = 0,
    PMC_NORMAL,
    PMC_REGION_NR
};

enum pmc_inst_t {
    PMC_INST_CAL = 0,
    PMC_INST_LOAD,
    PMC_INST_STORE,
    PMC_INST_BRANCH,
    PMC_INST_JUMP,
    PMC_INST_CSR,
    PMC_INST_FENCE,
    PMC_INST_UNKNOWN,
    PMC_INST_NR
};

typedef struct {
    uint64_t cycles;
    uint64_t retire_cycles;
    uint64_t empty_retire_cycles;
    uint64_t retired;
    uint64_t inst[PMC_INST_NR];
    uint64_t inst_cycles[PMC_INST_NR];

    uint64_t ifu_resp;
    uint64_t ifu_wait_cache;
    uint64_t ifu_wait_backend;
    uint64_t ifu_wait_flush;
    uint64_t ifu_wait_other;

    uint64_t icache_hit;
    uint64_t icache_miss;
    uint64_t icache_miss_cycles;
    uint64_t icache_refill_drop;
    uint64_t icache_invalidate;

    uint64_t lsu_load;
    uint64_t lsu_store;
    uint64_t lsu_load_cycles;
    uint64_t lsu_store_cycles;
    uint64_t lsu_redirect;

    uint64_t csr_inst;
    uint64_t ecall_inst;
    uint64_t mret_inst;
    uint64_t fence_i_inst;
} pmc_counter_t;

static pmc_counter_t pmc[PMC_REGION_NR];

static const char *const inst_name[PMC_INST_NR] = {
    "CAL",
    "LOAD",
    "STORE",
    "BRANCH",
    "JUMP",
    "CSR",
    "FENCE",
    "UNKNOWN"
};

static pmc_region_t region_of_pc(uint32_t pc) {
#ifdef SOC
    return pc >= 0xa0000000u ? PMC_NORMAL : PMC_BOOT;
#else
    return PMC_NORMAL;
#endif
}

static const char *region_name(pmc_region_t region) {
#ifdef SOC
    return region == PMC_BOOT ? "Bootloader (Flash/SRAM)" : "Normal (SDRAM)";
#else
    return region == PMC_BOOT ? "Boot/unused" : "NPC program";
#endif
}

static inline uint32_t bits(uint32_t value, int hi, int lo) {
    return (value >> lo) & ((1u << (hi - lo + 1)) - 1u);
}

static pmc_inst_t classify_inst(uint32_t inst) {
    uint32_t opcode = bits(inst, 6, 2);
    uint32_t funct3 = bits(inst, 14, 12);

    switch (opcode) {
        case 0x00: return PMC_INST_LOAD;    // LOAD
        case 0x08: return PMC_INST_STORE;   // STORE
        case 0x18: return PMC_INST_BRANCH;  // BRANCH
        case 0x19: return PMC_INST_JUMP;    // JALR
        case 0x1b: return PMC_INST_JUMP;    // JAL
        case 0x1c: return PMC_INST_CSR;     // SYSTEM
        case 0x03:
            return funct3 == 0x1 ? PMC_INST_FENCE : PMC_INST_UNKNOWN; // MISC-MEM/FENCE.I
        case 0x04:                          // OP-IMM
        case 0x05:                          // AUIPC
        case 0x0c:                          // OP
        case 0x0d:                          // LUI
            return PMC_INST_CAL;
        default:
            return PMC_INST_UNKNOWN;
    }
}

static void print_ratio(uint64_t part, uint64_t total) {
    if (total == 0) {
        printf("  ratio:                         n/a\n");
        return;
    }

    printf("  ratio:                         %.2f%%\n", 100.0 * (double)part / (double)total);
}

static void print_avg(const char *name, uint64_t cycles, uint64_t count) {
    if (count == 0) {
        printf("  %-30s n/a\n", name);
        return;
    }

    printf("  %-30s %.2f\n", name, (double)cycles / (double)count);
}

static bool is_csr_inst(uint32_t inst) {
    return bits(inst, 6, 2) == 0x1c && bits(inst, 14, 12) != 0;
}

static bool is_ecall_inst(uint32_t inst) {
    return inst == 0x00000073u;
}

static bool is_mret_inst(uint32_t inst) {
    return inst == 0x30200073u;
}

static bool is_fence_i_inst(uint32_t inst) {
    return bits(inst, 6, 2) == 0x03 && bits(inst, 14, 12) == 0x1;
}

void PerformanceCounter_record_cycle(
    uint32_t pc,
    bool wbu_valid,
    bool ifu_req_valid,
    bool ifu_req_ready,
    bool ifu_resp_valid,
    bool ifu_resp_ready,
    bool ifu_flush,
    bool icache_req_hit,
    bool icache_req_miss,
    bool icache_miss_busy,
    bool icache_drop_refill,
    bool icache_invalidate,
    bool lsu_mem_req_fire,
    bool lsu_input_is_load,
    bool lsu_input_is_store,
    bool lsu_state_busy
) {
    pmc_counter_t *c = &pmc[region_of_pc(pc)];
    c->cycles++;
    if (wbu_valid) {
        c->retire_cycles++;
    } else {
        c->empty_retire_cycles++;
    }

    if (ifu_resp_valid && ifu_resp_ready) {
        c->ifu_resp++;
    }

    if (!ifu_resp_valid) {
        if (ifu_flush) {
            c->ifu_wait_flush++;
        } else if (icache_miss_busy || (ifu_req_valid && !ifu_req_ready)) {
            c->ifu_wait_cache++;
        } else {
            c->ifu_wait_other++;
        }
    } else if (!ifu_resp_ready) {
        c->ifu_wait_backend++;
    }

    if (icache_req_hit) {
        c->icache_hit++;
    }
    if (icache_req_miss) {
        c->icache_miss++;
    }
    if (icache_miss_busy) {
        c->icache_miss_cycles++;
    }
    if (icache_drop_refill) {
        c->icache_refill_drop++;
    }
    if (icache_invalidate) {
        c->icache_invalidate++;
    }

    if (lsu_mem_req_fire) {
        if (lsu_input_is_load) c->lsu_load++;
        if (lsu_input_is_store) c->lsu_store++;
    }
    if (lsu_state_busy) {
        if (lsu_input_is_load) c->lsu_load_cycles++;
        if (lsu_input_is_store) c->lsu_store_cycles++;
    }
}

void PerformanceCounter_record_lsu_redirect(uint32_t pc) {
    pmc[region_of_pc(pc)].lsu_redirect++;
}

void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles) {
    pmc_counter_t *c = &pmc[region_of_pc(pc)];
    pmc_inst_t type = classify_inst(inst);

    c->retired++;
    c->inst[type]++;
    c->inst_cycles[type] += retire_cycles;

    if (is_csr_inst(inst)) {
        c->csr_inst++;
    }
    if (is_ecall_inst(inst)) {
        c->ecall_inst++;
    }
    if (is_mret_inst(inst)) {
        c->mret_inst++;
    }
    if (is_fence_i_inst(inst)) {
        c->fence_i_inst++;
    }
}

// 保留旧 DPI-C 函数名，避免以后临时打开旧 RTL 注释时链接失败。
void is_finish_bootloader(int pc) { (void)pc; }
void PerformanceCounter_ifu_fetch() {}
void PerformanceCounter_ifu_fetch_cycles(int start, int finish) { (void)start; (void)finish; }
void PerformanceCounter_inst_type_total_cycles(int start, int inst) { (void)start; (void)inst; }
void PerformanceCounter_icache_hit() {}
void PerformanceCounter_icache_AMAT() {}
void PerformanceCounter_lsu_load() {}
void PerformanceCounter_lsu_load_cycles(int start, int finish) { (void)start; (void)finish; }
void PerformanceCounter_lsu_store() {}
void PerformanceCounter_lsu_store_cycles(int start, int finish) { (void)start; (void)finish; }
void PerformanceCounter_exu_finish_cal() {}
void PerformanceCounter_idu_identify_inst(int inst) { (void)inst; }

void PerformanceCounter_display() {
    printf(ANSI_FG_YELLOW "===== CPU Performance Counter Statistics =====\n" ANSI_NONE);

    for (int r = 0; r < PMC_REGION_NR; r++) {
        pmc_counter_t *c = &pmc[r];

        if (c->cycles == 0 && c->retired == 0) {
            continue;
        }

        printf(ANSI_FG_CYAN "\n[%s]\n" ANSI_NONE, region_name((pmc_region_t)r));
        printf("  Cycles:                        %llu\n", (unsigned long long)c->cycles);
        printf("  Retired instructions:          %llu\n", (unsigned long long)c->retired);
        print_avg("CPI:", c->cycles, c->retired);
        printf("  Retire-valid cycles:           %llu\n", (unsigned long long)c->retire_cycles);
        printf("  Empty-retire cycles:           %llu\n", (unsigned long long)c->empty_retire_cycles);
        print_avg("cycles per retire-valid:", c->cycles, c->retire_cycles);

        printf("\n  Instruction Mix\n");
        for (int i = 0; i < PMC_INST_NR; i++) {
            printf("  %-8s count:                 %llu\n",
                inst_name[i], (unsigned long long)c->inst[i]);
            print_ratio(c->inst[i], c->retired);
            print_avg("avg retire interval:", c->inst_cycles[i], c->inst[i]);
        }

        printf("\n  IFU\n");
        printf("  Fetched responses:             %llu\n", (unsigned long long)c->ifu_resp);
        printf("  Wait ICache/refill cycles:     %llu\n", (unsigned long long)c->ifu_wait_cache);
        printf("  Wait backend cycles:           %llu\n", (unsigned long long)c->ifu_wait_backend);
        printf("  Wait flush cycles:             %llu\n", (unsigned long long)c->ifu_wait_flush);
        printf("  Wait other cycles:             %llu\n", (unsigned long long)c->ifu_wait_other);
        print_avg("avg IFU cycles/fetch:", c->cycles, c->ifu_resp);

        printf("\n  ICache\n");
        printf("  Hits:                          %llu\n", (unsigned long long)c->icache_hit);
        printf("  Misses:                        %llu\n", (unsigned long long)c->icache_miss);
        printf("  Miss busy cycles:              %llu\n", (unsigned long long)c->icache_miss_cycles);
        printf("  Dropped refills:               %llu\n", (unsigned long long)c->icache_refill_drop);
        printf("  Invalidates:                   %llu\n", (unsigned long long)c->icache_invalidate);
        print_avg("avg miss penalty:", c->icache_miss_cycles, c->icache_miss);

        printf("\n  LSU\n");
        printf("  Load operations:               %llu\n", (unsigned long long)c->lsu_load);
        printf("  Load busy cycles:              %llu\n", (unsigned long long)c->lsu_load_cycles);
        print_avg("avg load latency:", c->lsu_load_cycles, c->lsu_load);
        printf("  Store operations:              %llu\n", (unsigned long long)c->lsu_store);
        printf("  Store busy cycles:             %llu\n", (unsigned long long)c->lsu_store_cycles);
        print_avg("avg store latency:", c->lsu_store_cycles, c->lsu_store);

        printf("\n  Control/System Events\n");
        printf("  LSU redirects:                 %llu\n", (unsigned long long)c->lsu_redirect);
        printf("  CSR instructions:              %llu\n", (unsigned long long)c->csr_inst);
        printf("  ECALL instructions:            %llu\n", (unsigned long long)c->ecall_inst);
        printf("  MRET instructions:             %llu\n", (unsigned long long)c->mret_inst);
        printf("  FENCE.I instructions:          %llu\n", (unsigned long long)c->fence_i_inst);
    }

    printf(ANSI_FG_YELLOW "\n===== End of Statistics =====\n" ANSI_NONE);
}
