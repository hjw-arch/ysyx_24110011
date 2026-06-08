#include "common.h"
#include "log.h"
#include "pmc.h"
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

enum pmc_redirect_t {
    PMC_REDIR_BRANCH = 0,
    PMC_REDIR_JUMP,
    PMC_REDIR_ECALL,
    PMC_REDIR_MRET,
    PMC_REDIR_FENCE_I,
    PMC_REDIR_OTHER,
    PMC_REDIR_NR
};

enum pmc_stack_t {
    PMC_STACK_LSU = 0,
    PMC_STACK_ICACHE,
    PMC_STACK_REDIRECT,
    PMC_STACK_RAW,
    PMC_STACK_IFU_FLUSH,
    PMC_STACK_OTHER,
    PMC_STACK_NR
};

enum pmc_drop_cause_t {
    PMC_DROP_NONE = 0,
    PMC_DROP_BRANCH,
    PMC_DROP_JUMP,
    PMC_DROP_SYSTEM,
    PMC_DROP_FENCE_I,
    PMC_DROP_OTHER,
    PMC_DROP_NR
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
    uint64_t icache_drop_cause[PMC_DROP_NR];

    uint64_t lsu_load;
    uint64_t lsu_store;
    uint64_t lsu_load_cycles;
    uint64_t lsu_store_cycles;
    uint64_t lsu_redirect;

    uint64_t redirect[PMC_REDIR_NR];
    uint64_t redirect_recovery_cycles;
    uint64_t redirect_recovery_empty_cycles;
    uint64_t redirect_recovery_closed;
    uint64_t redirect_recovery_interrupted;
    uint64_t redirect_to_target_cycles;
    uint64_t redirect_to_target_empty_cycles;
    uint64_t redirect_ifu_wait_cache;
    uint64_t redirect_ifu_wait_backend;
    uint64_t redirect_ifu_wait_flush;
    uint64_t redirect_ifu_wait_other;
    uint64_t flush_kill_if;
    uint64_t flush_kill_id;
    uint64_t flush_kill_ex;
    uint64_t flush_kill_ls;
    uint64_t flush_killed_insts;

    uint64_t raw_hazard_cycles;
    uint64_t load_use_stall_cycles;
    uint64_t csr_use_stall_cycles;
    uint64_t ls_not_ready_stall_cycles;
    uint64_t fwd_rs1_from_ls;
    uint64_t fwd_rs2_from_ls;
    uint64_t fwd_rs1_from_wb;
    uint64_t fwd_rs2_from_wb;
    uint64_t rf_bypass_rs1;
    uint64_t rf_bypass_rs2;

    uint64_t cpi_stack_control_first[PMC_STACK_NR];
    uint64_t cpi_stack_resource_first[PMC_STACK_NR];

    uint64_t csr_inst;
    uint64_t ecall_inst;
    uint64_t mret_inst;
    uint64_t fence_i_inst;
} pmc_counter_t;

static pmc_counter_t pmc[PMC_REGION_NR];

typedef struct {
    bool active;
    pmc_region_t region;
    pmc_redirect_t kind;
    uint32_t source_pc;
    uint32_t target_pc;
    bool source_match_armed;
    bool source_committed;
    uint64_t cycles;
    uint64_t empty_cycles;
} pmc_recovery_t;

static pmc_recovery_t recovery = {};
static pmc_drop_cause_t pending_drop_cause = PMC_DROP_NONE;

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

static const char *const redirect_name[PMC_REDIR_NR] = {
    "branch",
    "jump",
    "ecall",
    "mret",
    "fence.i",
    "other"
};

static const char *const stack_name[PMC_STACK_NR] = {
    "LSU busy",
    "ICache/refill",
    "Redirect recovery",
    "RAW hazard",
    "IFU flush",
    "Other"
};

static const char *const drop_cause_name[PMC_DROP_NR] = {
    "unattributed",
    "branch",
    "jump",
    "system",
    "fence.i",
    "other"
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

static bool is_branch_inst(uint32_t inst) {
    return bits(inst, 6, 2) == 0x18;
}

static bool is_jump_inst(uint32_t inst) {
    uint32_t opcode = bits(inst, 6, 2);
    return opcode == 0x19 || opcode == 0x1b;
}

static pmc_redirect_t classify_redirect(uint32_t inst) {
    if (is_branch_inst(inst)) return PMC_REDIR_BRANCH;
    if (is_jump_inst(inst)) return PMC_REDIR_JUMP;
    if (inst == 0x00000073u) return PMC_REDIR_ECALL;
    if (inst == 0x30200073u) return PMC_REDIR_MRET;
    if (bits(inst, 6, 2) == 0x03 && bits(inst, 14, 12) == 0x1) return PMC_REDIR_FENCE_I;
    return PMC_REDIR_OTHER;
}

static pmc_drop_cause_t drop_cause_of_redirect(pmc_redirect_t kind) {
    switch (kind) {
        case PMC_REDIR_BRANCH:  return PMC_DROP_BRANCH;
        case PMC_REDIR_JUMP:    return PMC_DROP_JUMP;
        case PMC_REDIR_FENCE_I: return PMC_DROP_FENCE_I;
        case PMC_REDIR_ECALL:
        case PMC_REDIR_MRET:    return PMC_DROP_SYSTEM;
        default:                return PMC_DROP_OTHER;
    }
}

static pmc_stack_t stack_control_first(bool recovery_active, bool lsu_busy, bool icache_wait,
                                       bool hazard_valid, bool ifu_flush) {
    if (recovery_active) return PMC_STACK_REDIRECT;
    if (lsu_busy) return PMC_STACK_LSU;
    if (icache_wait) return PMC_STACK_ICACHE;
    if (hazard_valid) return PMC_STACK_RAW;
    if (ifu_flush) return PMC_STACK_IFU_FLUSH;
    return PMC_STACK_OTHER;
}

static pmc_stack_t stack_resource_first(bool recovery_active, bool lsu_busy, bool icache_wait,
                                        bool hazard_valid, bool ifu_flush) {
    if (lsu_busy) return PMC_STACK_LSU;
    if (icache_wait) return PMC_STACK_ICACHE;
    if (recovery_active) return PMC_STACK_REDIRECT;
    if (hazard_valid) return PMC_STACK_RAW;
    if (ifu_flush) return PMC_STACK_IFU_FLUSH;
    return PMC_STACK_OTHER;
}

static void account_flush_kills(pmc_counter_t *c, bool kill_if, bool kill_id,
                                bool kill_ex, bool kill_ls) {
    if (kill_if) c->flush_kill_if++;
    if (kill_id) c->flush_kill_id++;
    if (kill_ex) c->flush_kill_ex++;
    if (kill_ls) c->flush_kill_ls++;
    c->flush_killed_insts += (uint64_t)kill_if + (uint64_t)kill_id +
                             (uint64_t)kill_ex + (uint64_t)kill_ls;
}

static void start_redirect_recovery(uint32_t pc, uint32_t target, uint32_t inst,
                                    bool kill_if, bool kill_id, bool kill_ex, bool kill_ls,
                                    bool icache_miss_busy, bool source_in_wbu) {
    pmc_region_t region = region_of_pc(pc);
    pmc_counter_t *c = &pmc[region];
    pmc_redirect_t kind = classify_redirect(inst);

    c->redirect[kind]++;
    if (kind == PMC_REDIR_BRANCH || kind == PMC_REDIR_JUMP) {
        c->lsu_redirect++;
    }
    account_flush_kills(c, kill_if, kill_id, kill_ex, kill_ls);

    if (recovery.active) {
        pmc[recovery.region].redirect_recovery_interrupted++;
    }

    recovery.active = true;
    recovery.region = region;
    recovery.kind = kind;
    recovery.source_pc = pc;
    recovery.target_pc = target;
    recovery.source_match_armed = source_in_wbu;
    recovery.source_committed = false;
    recovery.cycles = 0;
    recovery.empty_cycles = 0;

    if (icache_miss_busy && pending_drop_cause == PMC_DROP_NONE) {
        pending_drop_cause = drop_cause_of_redirect(kind);
    }
}

static void record_active_recovery(bool wbu_valid, uint32_t wbu_pc, bool empty_retire,
                                   bool ifu_resp_valid, bool ifu_resp_ready, bool ifu_flush,
                                   bool icache_wait) {
    if (!recovery.active) {
        return;
    }

    pmc_counter_t *c = &pmc[recovery.region];
    recovery.cycles++;
    c->redirect_recovery_cycles++;

    if (empty_retire) {
        recovery.empty_cycles++;
        c->redirect_recovery_empty_cycles++;
    }

    if (!ifu_resp_valid) {
        if (ifu_flush) {
            c->redirect_ifu_wait_flush++;
        } else if (icache_wait) {
            c->redirect_ifu_wait_cache++;
        } else {
            c->redirect_ifu_wait_other++;
        }
    } else if (!ifu_resp_ready) {
        c->redirect_ifu_wait_backend++;
    }

    if (!recovery.source_match_armed) {
        recovery.source_match_armed = true;
        return;
    }

    if (!wbu_valid) {
        return;
    }

    if (!recovery.source_committed && wbu_pc == recovery.source_pc) {
        recovery.source_committed = true;
        return;
    }

    if (recovery.source_committed && wbu_pc == recovery.target_pc) {
        c->redirect_recovery_closed++;
        c->redirect_to_target_cycles += recovery.cycles;
        c->redirect_to_target_empty_cycles += recovery.empty_cycles;
        recovery.active = false;
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

static void print_counter_with_pct(const char *name, uint64_t value, uint64_t total) {
    if (total == 0) {
        printf("  %-30s %llu\n", name, (unsigned long long)value);
        return;
    }

    printf("  %-30s %llu (%.2f%%)\n", name, (unsigned long long)value,
           100.0 * (double)value / (double)total);
}

static void print_stack(const char *title, uint64_t stack[PMC_STACK_NR], uint64_t total) {
    printf("\n  %s\n", title);
    for (int i = 0; i < PMC_STACK_NR; i++) {
        print_counter_with_pct(stack_name[i], stack[i], total);
    }
}

static void print_percent_metric(const char *name, uint64_t part, uint64_t total) {
    if (total == 0) {
        printf("  %-30s n/a\n", name);
        return;
    }

    printf("  %-30s %.2f%%\n", name, 100.0 * (double)part / (double)total);
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

void PerformanceCounter_record_cycle(const pmc_cycle_sample_t *sample) {
    pmc_counter_t *c = &pmc[region_of_pc(sample->pc)];
    bool empty_retire = !sample->wbu_valid;
    bool icache_wait = sample->icache_miss_busy ||
                       (sample->ifu_req_valid && !sample->ifu_req_ready);

    c->cycles++;
    if (sample->wbu_valid) {
        c->retire_cycles++;
    } else {
        c->empty_retire_cycles++;
    }

    if (sample->ifu_resp_valid && sample->ifu_resp_ready) {
        c->ifu_resp++;
    }

    if (!sample->ifu_resp_valid) {
        if (sample->ifu_flush) {
            c->ifu_wait_flush++;
        } else if (sample->icache_miss_busy ||
                   (sample->ifu_req_valid && !sample->ifu_req_ready)) {
            c->ifu_wait_cache++;
        } else {
            c->ifu_wait_other++;
        }
    } else if (!sample->ifu_resp_ready) {
        c->ifu_wait_backend++;
    }

    if (sample->icache_req_hit) {
        c->icache_hit++;
    }
    if (sample->icache_req_miss) {
        c->icache_miss++;
    }
    if (sample->icache_miss_busy) {
        c->icache_miss_cycles++;
    }
    if (sample->icache_drop_refill) {
        c->icache_refill_drop++;
        c->icache_drop_cause[pending_drop_cause]++;
        pending_drop_cause = PMC_DROP_NONE;
    }
    if (sample->icache_invalidate) {
        c->icache_invalidate++;
    }

    if (sample->lsu_mem_req_fire) {
        if (sample->lsu_input_is_load) c->lsu_load++;
        if (sample->lsu_input_is_store) c->lsu_store++;
    }
    if (sample->lsu_wait_resp) {
        if (sample->lsu_input_is_load) c->lsu_load_cycles++;
        if (sample->lsu_input_is_store) c->lsu_store_cycles++;
    }

    if (sample->hazard_valid) {
        c->raw_hazard_cycles++;
    }
    if ((sample->rs1_block_ex | sample->rs2_block_ex) & sample->ex_is_load) {
        c->load_use_stall_cycles++;
    }
    if (((sample->rs1_block_ex | sample->rs2_block_ex) & sample->ex_is_csr) |
        ((sample->rs1_block_ls | sample->rs2_block_ls) & sample->ls_is_csr)) {
        c->csr_use_stall_cycles++;
    }
    if ((sample->rs1_block_ls | sample->rs2_block_ls) &
        !sample->ls_can_wb & !sample->ls_is_csr) {
        c->ls_not_ready_stall_cycles++;
    }

    if (sample->idu_valid && !sample->hazard_valid) {
        if (sample->fwd_rs1_sel & 0x1) c->fwd_rs1_from_ls++;
        if (sample->fwd_rs2_sel & 0x1) c->fwd_rs2_from_ls++;
        if (sample->fwd_rs1_sel & 0x2) c->fwd_rs1_from_wb++;
        if (sample->fwd_rs2_sel & 0x2) c->fwd_rs2_from_wb++;
    }
    if (sample->rf_rs1_bypass) c->rf_bypass_rs1++;
    if (sample->rf_rs2_bypass) c->rf_bypass_rs2++;

    if (empty_retire) {
        pmc_stack_t control_first = stack_control_first(recovery.active, sample->lsu_wait_resp,
                                                        icache_wait, sample->hazard_valid,
                                                        sample->ifu_flush);
        pmc_stack_t resource_first = stack_resource_first(recovery.active, sample->lsu_wait_resp,
                                                          icache_wait, sample->hazard_valid,
                                                          sample->ifu_flush);
        c->cpi_stack_control_first[control_first]++;
        c->cpi_stack_resource_first[resource_first]++;
    }

    record_active_recovery(sample->wbu_valid, sample->wbu_pc, empty_retire,
                           sample->ifu_resp_valid, sample->ifu_resp_ready,
                           sample->ifu_flush, icache_wait);
}

void PerformanceCounter_record_lsu_redirect(const pmc_lsu_redirect_sample_t *sample) {
    start_redirect_recovery(sample->pc, sample->target, sample->inst,
                            sample->kill_if, sample->kill_id, sample->kill_ex,
                            false, sample->icache_miss_busy, false);
}

void PerformanceCounter_record_wbu_redirect(const pmc_wbu_redirect_sample_t *sample) {
    start_redirect_recovery(sample->pc, sample->target, sample->inst,
                            sample->kill_if, sample->kill_id, sample->kill_ex,
                            sample->kill_ls, sample->icache_miss_busy, true);
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
        for (int i = 0; i < PMC_DROP_NR; i++) {
            if (c->icache_drop_cause[i] != 0) {
                printf("  drop %-22s %llu\n", drop_cause_name[i],
                    (unsigned long long)c->icache_drop_cause[i]);
            }
        }

        printf("\n  LSU\n");
        printf("  Load operations:               %llu\n", (unsigned long long)c->lsu_load);
        printf("  Load busy cycles:              %llu\n", (unsigned long long)c->lsu_load_cycles);
        print_avg("avg load latency:", c->lsu_load_cycles, c->lsu_load);
        printf("  Store operations:              %llu\n", (unsigned long long)c->lsu_store);
        printf("  Store busy cycles:             %llu\n", (unsigned long long)c->lsu_store_cycles);
        print_avg("avg store latency:", c->lsu_store_cycles, c->lsu_store);

        printf("\n  RAW/Forwarding\n");
        printf("  RAW stall cycles:              %llu\n", (unsigned long long)c->raw_hazard_cycles);
        printf("  load-use stall cycles:         %llu\n", (unsigned long long)c->load_use_stall_cycles);
        printf("  CSR-use stall cycles:          %llu\n", (unsigned long long)c->csr_use_stall_cycles);
        printf("  LS not-ready stall cycles:     %llu\n", (unsigned long long)c->ls_not_ready_stall_cycles);
        printf("  fwd rs1 from LS:               %llu\n", (unsigned long long)c->fwd_rs1_from_ls);
        printf("  fwd rs2 from LS:               %llu\n", (unsigned long long)c->fwd_rs2_from_ls);
        printf("  fwd rs1 from WB:               %llu\n", (unsigned long long)c->fwd_rs1_from_wb);
        printf("  fwd rs2 from WB:               %llu\n", (unsigned long long)c->fwd_rs2_from_wb);
        printf("  RF same-cycle bypass rs1:      %llu\n", (unsigned long long)c->rf_bypass_rs1);
        printf("  RF same-cycle bypass rs2:      %llu\n", (unsigned long long)c->rf_bypass_rs2);

        printf("\n  Control/System Events\n");
        printf("  LSU redirects:                 %llu\n", (unsigned long long)c->lsu_redirect);
        for (int i = 0; i < PMC_REDIR_NR; i++) {
            printf("  redirect %-19s %llu\n", redirect_name[i],
                (unsigned long long)c->redirect[i]);
        }
        printf("  Redirect recovery cycles:      %llu\n", (unsigned long long)c->redirect_recovery_cycles);
        printf("  Redirect empty-retire cycles:  %llu\n", (unsigned long long)c->redirect_recovery_empty_cycles);
        printf("  Redirect windows closed:       %llu\n", (unsigned long long)c->redirect_recovery_closed);
        printf("  Redirect windows interrupted:  %llu\n", (unsigned long long)c->redirect_recovery_interrupted);
        print_avg("avg cycles to target retire:", c->redirect_to_target_cycles,
                  c->redirect_recovery_closed);
        print_avg("avg empty cycles to target:", c->redirect_to_target_empty_cycles,
                  c->redirect_recovery_closed);
        printf("  Redirect IFU wait cache:       %llu\n", (unsigned long long)c->redirect_ifu_wait_cache);
        printf("  Redirect IFU wait backend:     %llu\n", (unsigned long long)c->redirect_ifu_wait_backend);
        printf("  Redirect IFU wait flush:       %llu\n", (unsigned long long)c->redirect_ifu_wait_flush);
        printf("  Redirect IFU wait other:       %llu\n", (unsigned long long)c->redirect_ifu_wait_other);
        printf("  Flush killed IF responses:     %llu\n", (unsigned long long)c->flush_kill_if);
        printf("  Flush killed ID stage:         %llu\n", (unsigned long long)c->flush_kill_id);
        printf("  Flush killed EX stage:         %llu\n", (unsigned long long)c->flush_kill_ex);
        printf("  Flush killed LS stage:         %llu\n", (unsigned long long)c->flush_kill_ls);
        printf("  Flush killed total:            %llu\n", (unsigned long long)c->flush_killed_insts);
        print_avg("avg killed per redirect:", c->flush_killed_insts,
                  c->lsu_redirect + c->redirect[PMC_REDIR_ECALL] +
                  c->redirect[PMC_REDIR_MRET] + c->redirect[PMC_REDIR_FENCE_I] +
                  c->redirect[PMC_REDIR_OTHER]);
        print_avg("branch interval:", c->retired, c->inst[PMC_INST_BRANCH]);
        print_avg("control-flow interval:", c->retired,
                  c->inst[PMC_INST_BRANCH] + c->inst[PMC_INST_JUMP]);
        print_avg("redirect interval:", c->retired,
                  c->redirect[PMC_REDIR_BRANCH] + c->redirect[PMC_REDIR_JUMP]);
        print_percent_metric("taken branch rate:", c->redirect[PMC_REDIR_BRANCH],
                             c->inst[PMC_INST_BRANCH]);
        printf("  CSR instructions:              %llu\n", (unsigned long long)c->csr_inst);
        printf("  ECALL instructions:            %llu\n", (unsigned long long)c->ecall_inst);
        printf("  MRET instructions:             %llu\n", (unsigned long long)c->mret_inst);
        printf("  FENCE.I instructions:          %llu\n", (unsigned long long)c->fence_i_inst);

        print_stack("CPI Stack, control first", c->cpi_stack_control_first,
                    c->empty_retire_cycles);
        print_stack("CPI Stack, resource first", c->cpi_stack_resource_first,
                    c->empty_retire_cycles);
    }

    printf(ANSI_FG_YELLOW "\n===== End of Statistics =====\n" ANSI_NONE);
}
