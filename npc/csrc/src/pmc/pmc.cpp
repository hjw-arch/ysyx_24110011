#include <llvm/Support/JSON.h>
#include <llvm/Support/raw_ostream.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "common.h"
#include "log.h"
#include "pmc.h"

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
    PMC_INST_SYSTEM,
    PMC_INST_FENCE,
    PMC_INST_UNKNOWN,
    PMC_INST_NR
};

enum pmc_redirect_t {
    PMC_REDIR_BRANCH = 0,
    PMC_REDIR_JUMP,
    PMC_REDIR_SYSTEM,
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

typedef struct {
    uint64_t cycles;
    uint64_t retire_valid_cycles;
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
    uint64_t icache_refill_drop;
    uint64_t icache_invalidate;

    uint64_t load_count;
    uint64_t store_count;
    uint64_t lsu_busy_cycles;
    uint64_t lsu_empty_cycles;

    uint64_t redirect[PMC_REDIR_NR];
    uint64_t redirect_count;
    uint64_t redirect_recovery_cycles;
    uint64_t flush_killed_insts;

    uint64_t raw_stall_cycles;
    uint64_t load_use_stall_cycles;
    uint64_t csr_use_stall_cycles;

    uint64_t cpi_stack[PMC_STACK_NR];
} pmc_counter_t;

typedef struct {
    bool active;
    pmc_region_t region;
    uint32_t target_pc;
} recovery_t;

static pmc_counter_t pmc[PMC_REGION_NR];
static recovery_t recovery;

static const char *const region_key[PMC_REGION_NR] = {
    "bootloader",
    "normal"
};

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

static const char *const redirect_key[PMC_REDIR_NR] = {
    "branch",
    "jump",
    "system",
    "fence_i",
    "other"
};

static const char *const stack_key[PMC_STACK_NR] = {
    "lsu",
    "icache",
    "redirect",
    "raw",
    "ifu_flush",
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
        case 0x00: return PMC_INST_LOAD;
        case 0x08: return PMC_INST_STORE;
        case 0x18: return PMC_INST_BRANCH;
        case 0x19: return PMC_INST_JUMP;
        case 0x1b: return PMC_INST_JUMP;
        case 0x1c: return funct3 != 0 ? PMC_INST_CSR : PMC_INST_SYSTEM;
        case 0x03: return PMC_INST_FENCE;
        case 0x04:
        case 0x05:
        case 0x0c:
        case 0x0d:
            return PMC_INST_CAL;
        default:
            return PMC_INST_UNKNOWN;
    }
}

static pmc_redirect_t classify_redirect(uint32_t inst) {
    uint32_t opcode = bits(inst, 6, 2);
    if (opcode == 0x18) return PMC_REDIR_BRANCH;
    if (opcode == 0x19 || opcode == 0x1b) return PMC_REDIR_JUMP;
    if (inst == 0x00000073u || inst == 0x30200073u) return PMC_REDIR_SYSTEM;
    if (opcode == 0x03 && bits(inst, 14, 12) == 0x1) return PMC_REDIR_FENCE_I;
    return PMC_REDIR_OTHER;
}

static uint64_t icache_accesses(const pmc_counter_t *c) {
    return c->icache_hit + c->icache_miss;
}

static uint64_t ifu_cycles(const pmc_counter_t *c) {
    return c->ifu_fetch + c->ifu_wait_icache + c->ifu_wait_backend +
           c->ifu_wait_flush + c->ifu_wait_other;
}

static pmc_stack_t choose_stack(bool lsu_busy, bool icache_wait,
                                bool recovery_active, bool raw_stall,
                                bool ifu_flush) {
    if (lsu_busy) return PMC_STACK_LSU;
    if (icache_wait) return PMC_STACK_ICACHE;
    if (recovery_active) return PMC_STACK_REDIRECT;
    if (raw_stall) return PMC_STACK_RAW;
    if (ifu_flush) return PMC_STACK_IFU_FLUSH;
    return PMC_STACK_OTHER;
}

static void record_recovery_cycle(const pmc_cycle_sample_t *sample) {
    if (!recovery.active) {
        return;
    }

    pmc_counter_t *c = &pmc[recovery.region];
    c->redirect_recovery_cycles++;

    if (sample->wbu_valid && sample->wbu_pc == recovery.target_pc) {
        recovery.active = false;
    }
}

static void start_redirect(uint32_t pc, uint32_t target, uint32_t inst,
                           bool kill_if, bool kill_id, bool kill_ex, bool kill_ls) {
    pmc_region_t region = region_of_pc(pc);
    pmc_counter_t *c = &pmc[region];
    pmc_redirect_t kind = classify_redirect(inst);

    c->redirect[kind]++;
    c->redirect_count++;
    c->flush_killed_insts += (uint64_t)kill_if + (uint64_t)kill_id +
                             (uint64_t)kill_ex + (uint64_t)kill_ls;

    recovery.active = true;
    recovery.region = region;
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

static void print_avg(const char *name, uint64_t cycles, uint64_t count) {
    if (count == 0) {
        printf("  %-28s n/a\n", name);
        return;
    }
    printf("  %-28s %.2f\n", name, (double)cycles / (double)count);
}

void PerformanceCounter_record_cycle(const pmc_cycle_sample_t *sample) {
    pmc_counter_t *c = &pmc[region_of_pc(sample->pc)];
    bool empty_retire = !sample->wbu_valid;
    bool icache_wait = sample->icache_miss_busy ||
                       (sample->ifu_req_valid && !sample->ifu_req_ready);
    bool lsu_busy = sample->lsu_mem_req_fire || sample->lsu_wait_resp;
    bool raw_stall = sample->hazard_valid;
    bool count_younger_side = !sample->host_trap_commit;

    c->cycles++;
    if (sample->wbu_valid) {
        c->retire_valid_cycles++;
    } else {
        c->empty_cycles++;
    }

    if (sample->ifu_resp_valid && sample->ifu_resp_ready) {
        c->ifu_fetch++;
    }
    if (!sample->ifu_resp_valid) {
        if (sample->ifu_flush) {
            c->ifu_wait_flush++;
        } else if (icache_wait) {
            c->ifu_wait_icache++;
        } else {
            c->ifu_wait_other++;
        }
    } else if (!sample->ifu_resp_ready) {
        c->ifu_wait_backend++;
    }

    if (sample->icache_req_hit) c->icache_hit++;
    if (sample->icache_req_miss) c->icache_miss++;
    if (sample->icache_miss_busy) c->icache_miss_cycles++;
    if (sample->icache_drop_refill) c->icache_refill_drop++;
    if (sample->icache_invalidate) c->icache_invalidate++;

    if (count_younger_side && sample->lsu_mem_req_fire) {
        if (sample->lsu_input_is_load) c->load_count++;
        if (sample->lsu_input_is_store) c->store_count++;
    }
    if (count_younger_side && lsu_busy) {
        c->lsu_busy_cycles++;
        if (empty_retire) c->lsu_empty_cycles++;
    }

    if (raw_stall) c->raw_stall_cycles++;
    if ((sample->rs1_block_ex | sample->rs2_block_ex) & sample->ex_is_load) {
        c->load_use_stall_cycles++;
    }
    if (((sample->rs1_block_ex | sample->rs2_block_ex) & sample->ex_is_csr) |
        ((sample->rs1_block_ls | sample->rs2_block_ls) & sample->ls_is_csr)) {
        c->csr_use_stall_cycles++;
    }

    if (empty_retire) {
        c->cpi_stack[choose_stack(lsu_busy, icache_wait, recovery.active,
                                  raw_stall, sample->ifu_flush)]++;
    }

    record_recovery_cycle(sample);
}

void PerformanceCounter_record_lsu_redirect(const pmc_lsu_redirect_sample_t *sample) {
    start_redirect(sample->pc, sample->target, sample->inst,
                   sample->kill_if, sample->kill_id, sample->kill_ex, false);
}

void PerformanceCounter_record_wbu_redirect(const pmc_wbu_redirect_sample_t *sample) {
    start_redirect(sample->pc, sample->target, sample->inst,
                   sample->kill_if, sample->kill_id, sample->kill_ex, sample->kill_ls);
}

void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles) {
    (void)retire_cycles;

    pmc_counter_t *c = &pmc[region_of_pc(pc)];
    c->retired++;
    c->inst[classify_inst(inst)]++;
}

static void json_count(llvm::json::OStream &json, const char *key, uint64_t value) {
    json.attribute(key, value);
}

static void json_region(llvm::json::OStream &json, pmc_region_t region) {
    const pmc_counter_t *c = &pmc[region];

    json.attributeObject(region_key[region], [&] {
        json.attribute("label", region_name(region));

        json.attributeObject("overview", [&] {
            json_count(json, "cycles", c->cycles);
            json_count(json, "retired", c->retired);
            json_count(json, "retire_valid_cycles", c->retire_valid_cycles);
            json_count(json, "empty_cycles", c->empty_cycles);
        });

        json.attributeObject("instructions", [&] {
            for (int i = 0; i < PMC_INST_NR; i++) {
                json_count(json, inst_key[i], c->inst[i]);
            }
        });

        json.attributeObject("ifu", [&] {
            json_count(json, "fetch", c->ifu_fetch);
            json_count(json, "cycles", ifu_cycles(c));
            json_count(json, "wait_icache", c->ifu_wait_icache);
            json_count(json, "wait_backend", c->ifu_wait_backend);
            json_count(json, "wait_flush", c->ifu_wait_flush);
            json_count(json, "wait_other", c->ifu_wait_other);
        });

        json.attributeObject("icache", [&] {
            json_count(json, "access", icache_accesses(c));
            json_count(json, "hit", c->icache_hit);
            json_count(json, "miss", c->icache_miss);
            json_count(json, "miss_cycles", c->icache_miss_cycles);
            json_count(json, "refill_drop", c->icache_refill_drop);
            json_count(json, "invalidate", c->icache_invalidate);
        });

        json.attributeObject("lsu", [&] {
            json_count(json, "load", c->load_count);
            json_count(json, "store", c->store_count);
            json_count(json, "busy_cycles", c->lsu_busy_cycles);
            json_count(json, "empty_cycles", c->lsu_empty_cycles);
        });

        json.attributeObject("control", [&] {
            json_count(json, "redirect", c->redirect_count);
            json_count(json, "redirect_recovery_cycles", c->redirect_recovery_cycles);
            json_count(json, "flush_killed_insts", c->flush_killed_insts);
            json.attributeObject("redirect_kind", [&] {
                for (int i = 0; i < PMC_REDIR_NR; i++) {
                    json_count(json, redirect_key[i], c->redirect[i]);
                }
            });
        });

        json.attributeObject("stall", [&] {
            json_count(json, "raw", c->raw_stall_cycles);
            json_count(json, "load_use", c->load_use_stall_cycles);
            json_count(json, "csr_use", c->csr_use_stall_cycles);
        });

        json.attributeObject("cpi_stack", [&] {
            for (int i = 0; i < PMC_STACK_NR; i++) {
                json_count(json, stack_key[i], c->cpi_stack[i]);
            }
        });
    });
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
        json.attribute("schema", "npc-pmc-v2");
#ifdef SOC
        json.attribute("target", "soc");
#else
        json.attribute("target", "npc");
#endif
        json.attributeObject("regions", [&] {
            for (int r = 0; r < PMC_REGION_NR; r++) {
                json_region(json, (pmc_region_t)r);
            }
        });
    });
    json.flush();

    printf("Performance counter JSON written to %s\n", path);
}

void PerformanceCounter_display() {
    printf(ANSI_FG_YELLOW "===== CPU Performance Counter Statistics =====\n" ANSI_NONE);

    for (int r = 0; r < PMC_REGION_NR; r++) {
        pmc_counter_t *c = &pmc[r];
        uint64_t icache_total = icache_accesses(c);

        if (c->cycles == 0 && c->retired == 0) {
            continue;
        }

        printf(ANSI_FG_CYAN "\n[%s]\n" ANSI_NONE, region_name((pmc_region_t)r));

        printf("\n  Overview\n");
        print_u64("Cycles:", c->cycles);
        print_u64("Retired instructions:", c->retired);
        print_avg("CPI:", c->cycles, c->retired);
        print_avg("IPC:", c->retired, c->cycles);
        print_u64("Retire-valid cycles:", c->retire_valid_cycles);
        print_u64("Empty cycles:", c->empty_cycles);

        printf("\n  Instruction Mix\n");
        for (int i = 0; i < PMC_INST_NR; i++) {
            print_u64(inst_key[i], c->inst[i]);
        }

        printf("\n  Frontend\n");
        print_u64("IFU fetch:", c->ifu_fetch);
        print_u64("IFU total cycles:", ifu_cycles(c));
        print_u64("IFU wait icache:", c->ifu_wait_icache);
        print_u64("IFU wait backend:", c->ifu_wait_backend);
        print_u64("IFU wait flush:", c->ifu_wait_flush);
        print_u64("IFU wait other:", c->ifu_wait_other);
        print_u64("ICache hits:", c->icache_hit);
        print_u64("ICache misses:", c->icache_miss);
        print_ratio("ICache hit rate:", c->icache_hit, icache_total);
        print_u64("ICache miss cycles:", c->icache_miss_cycles);
        print_u64("ICache dropped refills:", c->icache_refill_drop);
        print_u64("ICache invalidates:", c->icache_invalidate);

        printf("\n  LSU\n");
        print_u64("Load requests:", c->load_count);
        print_u64("Store requests:", c->store_count);
        print_u64("LSU busy cycles:", c->lsu_busy_cycles);
        print_u64("LSU empty cycles:", c->lsu_empty_cycles);
        print_ratio("LSU empty / cycles:", c->lsu_empty_cycles, c->cycles);

        printf("\n  Control\n");
        print_u64("Redirects:", c->redirect_count);
        for (int i = 0; i < PMC_REDIR_NR; i++) {
            print_u64(redirect_key[i], c->redirect[i]);
        }
        print_u64("Redirect recovery cycles:", c->redirect_recovery_cycles);
        print_u64("Flush killed insts:", c->flush_killed_insts);

        printf("\n  RAW Stalls\n");
        print_u64("RAW stall cycles:", c->raw_stall_cycles);
        print_u64("Load-use stall cycles:", c->load_use_stall_cycles);
        print_u64("CSR-use stall cycles:", c->csr_use_stall_cycles);

        printf("\n  CPI Stack (empty cycles)\n");
        for (int i = 0; i < PMC_STACK_NR; i++) {
            print_ratio(stack_name[i], c->cpi_stack[i], c->empty_cycles);
        }
    }

    printf(ANSI_FG_YELLOW "\n===== End of Statistics =====\n" ANSI_NONE);
}
