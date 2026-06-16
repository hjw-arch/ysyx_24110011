#include <getopt.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "log.h"

/*
 * BranchSim 读取 NEMU 导出的 BTRACE.bin，离线评估分支预测策略。
 *
 * 这个工具的输入不是完整指令流，而是“已经执行完成的控制流指令记录”。
 * 因此它做的是离线重放：每读到一条真实分支记录，就先让预测器根据当前
 * 历史状态给出 next_pc，再用记录里的 dnpc 判断预测是否正确，最后用真实
 * 结果更新预测器状态。
 *
 * BTRACE 每条记录对应一条控制流指令：
 *   pc   : 当前指令地址
 *   snpc : 顺序下一条地址，通常是 pc + 4
 *   dnpc : 实际下一条地址
 *   inst : 原始 32-bit 指令
 *
 * 对于当前 RV32I/RV32E：
 *   actual_taken = (dnpc != snpc)
 *
 * 统计时同时给出“方向命中”和“下一 PC 命中”：
 *   - 方向命中只看 taken/not-taken 是否判断正确；
 *   - 下一 PC 命中直接比较预测 next_pc 和 dnpc，更接近 IFU 是否会被冲刷。
 *
 * 例如 JALR 一定是 taken，但如果没有 BTB 给出正确 target，仅方向正确仍然
 * 不足以避免取错指令。因此性能建模应主要看“下一 PC 命中”。
 */
#define DEFAULT_TRACE_FILE "/home/hjw-arch/ysyx-workbench/BTRACE.bin"

#define OPC_BRANCH 0x63
#define OPC_JAL    0x6f
#define OPC_JALR   0x67

/*
 * BTRACE.bin 的磁盘格式。
 *
 * 这里必须和 NEMU 侧 btrace_record_t 完全一致，并使用 1 字节对齐，避免
 * 编译器在字段之间插入 padding。branchsim 按 sizeof(btrace_entry_t) 顺序
 * fread，因此格式不一致会导致后续每条记录整体错位。
 */
#pragma pack(push, 1)
typedef struct {
    uint64_t pc;
    uint64_t snpc;
    uint64_t dnpc;
    uint32_t inst;
} btrace_entry_t;
#pragma pack(pop)

typedef enum {
    PRED_NONE,
    PRED_ALWAYS_TAKEN,
    PRED_BTFNT,
    PRED_BIMODAL,
    PRED_BTB,
} predictor_kind_t;

/*
 * 当前 BTRACE 只记录三类 RISC-V 控制流指令：
 *   BR_COND : 条件分支，如 beq/bne/blt...
 *   BR_JAL  : 直接无条件跳转，目标可由 J immediate 算出
 *   BR_JALR : 间接无条件跳转，目标依赖寄存器值，离线解码无法提前算出
 */
typedef enum {
    BR_COND,
    BR_JAL,
    BR_JALR,
    BR_NR,
    BR_UNKNOWN = BR_NR,
} branch_type_t;

typedef struct {
    uint64_t pc;
    uint64_t snpc;
    uint64_t dnpc;
    branch_type_t type;
    bool actual_taken;
    bool direct_target_valid;
    uint64_t direct_target;
    int64_t imm;
} branch_info_t;

/*
 * 预测器每次预测只需要给出“认为下一拍应该取哪里”。
 *
 * taken 用于统计方向命中；next_pc 用于统计真正会不会冲刷流水线；
 * btb_hit 只用于观察 BTB 自身命中率，不直接等价于预测正确。
 */
typedef struct {
    bool taken;
    uint64_t next_pc;
    bool btb_hit;
} pred_result_t;

/*
 * 极简 direct-mapped BTB。
 *
 * tag 保存完整 PC，target 保存上一次看到的真实 dnpc。条件分支方向仍由 BHT
 * 决定；BTB 主要解决“预测 taken 时目标地址从哪里来”的问题，尤其是 JALR。
 */
typedef struct {
    bool valid;
    uint64_t tag;
    uint64_t target;
    branch_type_t type;
} btb_entry_t;

typedef struct {
    uint8_t counter;  // 2-bit 饱和计数器：0/1 预测不跳，2/3 预测跳
} bht_entry_t;

typedef struct {
    predictor_kind_t kind;
    uint32_t entries;
    bht_entry_t *bht;
    btb_entry_t *btb;
} predictor_t;

typedef struct {
    const char *trace_file;
    predictor_kind_t predictor;
    uint32_t entries;
    double penalty;
    uint64_t insts;
} config_t;

typedef struct {
    uint64_t total;
    // 按分支类型统计数量和“下一 PC 预测失败”次数。
    uint64_t type_count[BR_NR];
    uint64_t type_miss[BR_NR];
    uint64_t taken;

    // dir_hit 是方向命中；pc_hit 是最终 next_pc 命中。
    uint64_t dir_hit;
    uint64_t pc_hit;

    // 只有 PRED_BTB 使用，用来判断 BTB 表项容量是否足够。
    uint64_t btb_access;
    uint64_t btb_hit;
} stats_t;

static const char *branch_type_cn[BR_NR] = {
    [BR_COND] = "条件分支",
    [BR_JAL]  = "JAL",
    [BR_JALR] = "JALR",
};

static const char *branch_miss_cn[BR_NR] = {
    [BR_COND] = "条件分支失败",
    [BR_JAL]  = "JAL 失败",
    [BR_JALR] = "JALR 失败",
};

static const char *predictor_name(predictor_kind_t kind) {
    switch (kind) {
        case PRED_NONE:         return "none";
        case PRED_ALWAYS_TAKEN: return "always-taken";
        case PRED_BTFNT:        return "btfnt";
        case PRED_BIMODAL:      return "bimodal";
        case PRED_BTB:          return "btb";
        default:                return "unknown";
    }
}

static predictor_kind_t parse_predictor(const char *name) {
    if (strcmp(name, "none") == 0) return PRED_NONE;
    if (strcmp(name, "always-taken") == 0 || strcmp(name, "taken") == 0) return PRED_ALWAYS_TAKEN;
    if (strcmp(name, "btfnt") == 0) return PRED_BTFNT;
    if (strcmp(name, "bimodal") == 0) return PRED_BIMODAL;
    if (strcmp(name, "btb") == 0) return PRED_BTB;
    panic("未知预测器: %s", name);
}

static bool is_pow2(uint32_t n) {
    return n != 0 && (n & (n - 1)) == 0;
}

static double rate(uint64_t part, uint64_t total) {
    return total == 0 ? 0.0 : 100.0 * (double)part / (double)total;
}

static uint32_t parse_u32(const char *text, const char *name) {
    char *end = NULL;
    unsigned long value = strtoul(text, &end, 0);
    Assert(end != text && *end == '\0', "%s 参数非法: %s", name, text);
    Assert(value <= UINT32_MAX, "%s 参数过大: %s", name, text);
    return (uint32_t)value;
}

static uint64_t parse_u64(const char *text, const char *name) {
    char *end = NULL;
    unsigned long long value = strtoull(text, &end, 0);
    Assert(end != text && *end == '\0', "%s 参数非法: %s", name, text);
    return (uint64_t)value;
}

static double parse_double(const char *text, const char *name) {
    char *end = NULL;
    double value = strtod(text, &end);
    Assert(end != text && *end == '\0', "%s 参数非法: %s", name, text);
    return value;
}

static int64_t sign_extend(uint64_t value, uint32_t bits) {
    uint64_t sign = 1ull << (bits - 1);
    return (int64_t)((value ^ sign) - sign);
}

// 用无符号地址承载 PC，单独处理有符号偏移，避免隐式类型转换把负立即数弄乱。
static uint64_t add_signed(uint64_t base, int64_t offset) {
    return offset >= 0 ? base + (uint64_t)offset : base - (uint64_t)(-offset);
}

// B-type immediate 分散在 inst[31], inst[7], inst[30:25], inst[11:8]。
static int64_t decode_b_imm(uint32_t inst) {
    uint32_t imm =
        ((inst >> 31) & 0x1) << 12 |
        ((inst >> 7)  & 0x1) << 11 |
        ((inst >> 25) & 0x3f) << 5 |
        ((inst >> 8)  & 0xf) << 1;
    return sign_extend(imm, 13);
}

// J-type immediate 分散在 inst[31], inst[19:12], inst[20], inst[30:21]。
static int64_t decode_j_imm(uint32_t inst) {
    uint32_t imm =
        ((inst >> 31) & 0x1) << 20 |
        ((inst >> 12) & 0xff) << 12 |
        ((inst >> 20) & 0x1) << 11 |
        ((inst >> 21) & 0x3ff) << 1;
    return sign_extend(imm, 21);
}

// JALR 使用 I-type immediate，但真正 target 还要加 rs1 的运行时值。
static int64_t decode_i_imm(uint32_t inst) {
    return sign_extend((inst >> 20) & 0xfff, 12);
}

static branch_type_t decode_type(uint32_t inst) {
    switch (inst & 0x7f) {
        case OPC_BRANCH: return BR_COND;
        case OPC_JAL:    return BR_JAL;
        case OPC_JALR:   return BR_JALR;
        default:         return BR_UNKNOWN;
    }
}

static branch_info_t make_branch_info(const btrace_entry_t *entry) {
    uint32_t inst = entry->inst;
    branch_info_t br = {
        .pc = entry->pc,
        .snpc = entry->snpc,
        .dnpc = entry->dnpc,
        .type = decode_type(inst),
        .actual_taken = entry->dnpc != entry->snpc,
        .direct_target_valid = false,
        .direct_target = entry->snpc,
        .imm = 0,
    };

    /*
     * 这里把“二进制 trace 记录”转换成预测器更关心的分支语义。
     *
     * 条件分支和 JAL 是 PC-relative direct branch/jump，target 可由
     * pc + immediate 在预测时直接得到；JALR 是 indirect jump，target 依赖
     * rs1 的运行时值，所以没有 BTB 时只能预测 snpc，无法猜到真实 dnpc。
     */
    if (br.type == BR_COND) {
        br.imm = decode_b_imm(inst);
        br.direct_target_valid = true;
        br.direct_target = add_signed(br.pc, br.imm);
    } else if (br.type == BR_JAL) {
        br.imm = decode_j_imm(inst);
        br.direct_target_valid = true;
        br.direct_target = add_signed(br.pc, br.imm);
    } else if (br.type == BR_JALR) {
        br.imm = decode_i_imm(inst);
        // JALR 目标依赖寄存器值，纯离线指令解码不能提前知道目标，只能靠 BTB 学习。
    }

    return br;
}

static uint32_t pc_index(uint64_t pc, uint32_t entries) {
    // 模拟硬件里最便宜的 direct-mapped 索引：忽略低两位字节偏移。
    return (uint32_t)((pc >> 2) & (entries - 1));
}

static bool bht_taken(const predictor_t *pred, uint64_t pc) {
    return pred->bht[pc_index(pc, pred->entries)].counter >= 2;
}

static void update_bht(predictor_t *pred, uint64_t pc, bool taken) {
    uint8_t *counter = &pred->bht[pc_index(pc, pred->entries)].counter;
    if (taken) {
        if (*counter < 3) (*counter)++;
    } else {
        if (*counter > 0) (*counter)--;
    }
}

static pred_result_t direct_target_result(const branch_info_t *br, bool taken) {
    pred_result_t result = {
        .taken = taken,
        .next_pc = br->snpc,
        .btb_hit = false,
    };

    /*
     * 没有 BTB 时，只有 direct target 可以在 IFU 中由 PC+imm 得到。
     * JAL/JALR 都是 taken，但 JALR 的 target 不在指令立即数里，所以这里
     * direct_target_valid 为 false 时仍然只能给 snpc。
     */
    if (taken && br->direct_target_valid) {
        result.next_pc = br->direct_target;
    }
    return result;
}

static pred_result_t predictor_predict(predictor_t *pred, const branch_info_t *br) {
    switch (pred->kind) {
        case PRED_NONE:
            // 当前无分支预测 NPC 的等价基线：永远顺序取下一条。
            return direct_target_result(br, false);

        case PRED_ALWAYS_TAKEN:
            // 静态总是跳转：direct branch 可立即给 target，JALR 仍需要 BTB 才能给 target。
            return direct_target_result(br, true);

        case PRED_BTFNT:
            // 经典静态策略：向后分支多为循环，预测 taken；向前分支多为 if，预测 not taken。
            if (br->type == BR_COND) {
                return direct_target_result(br, br->imm < 0);
            }
            return direct_target_result(br, true);

        case PRED_BIMODAL:
            // 2-bit BHT 只学习条件分支方向；JAL/JALR 按无条件跳转处理。
            if (br->type == BR_COND) {
                return direct_target_result(br, bht_taken(pred, br->pc));
            }
            return direct_target_result(br, true);

        case PRED_BTB: {
            /*
             * BTB 未命中时保守预测 snpc；命中后：
             *   - 条件分支方向由 BHT 决定，target 来自 BTB；
             *   - JAL/JALR 是无条件跳转，直接使用 BTB target。
             */
            pred_result_t result = direct_target_result(br, false);
            uint32_t index = pc_index(br->pc, pred->entries);
            btb_entry_t *entry = &pred->btb[index];
            if (!entry->valid || entry->tag != br->pc) {
                return result;
            }

            result.btb_hit = true;
            if (entry->type == BR_COND) {
                result.taken = bht_taken(pred, br->pc);
            } else {
                result.taken = true;
            }
            result.next_pc = result.taken ? entry->target : br->snpc;
            return result;
        }

        default:
            panic("非法预测器");
    }
}

static void predictor_update(predictor_t *pred, const branch_info_t *br) {
    /*
     * 真实处理器在分支结果解析后更新预测器；离线模拟也必须先 predict/count，
     * 再 update，否则会把当前分支的真实结果提前泄漏给当前预测。
     */
    if ((pred->kind == PRED_BIMODAL || pred->kind == PRED_BTB) && br->type == BR_COND) {
        update_bht(pred, br->pc, br->actual_taken);
    }

    if (pred->kind != PRED_BTB) {
        return;
    }

    /*
     * BTB 只记录实际跳转过的控制流目标：
     *   - taken 条件分支需要记 target；
     *   - JAL/JALR 永远改变 PC，也需要记 target；
     *   - not-taken 条件分支不写 BTB，默认 snpc 就是正确路径。
     */
    if (br->actual_taken || br->type == BR_JAL || br->type == BR_JALR) {
        uint32_t index = pc_index(br->pc, pred->entries);
        pred->btb[index] = (btb_entry_t) {
            .valid = true,
            .tag = br->pc,
            .target = br->dnpc,
            .type = br->type,
        };
    }
}

static void predictor_init(predictor_t *pred, predictor_kind_t kind, uint32_t entries) {
    pred->kind = kind;
    pred->entries = entries;
    pred->bht = NULL;
    pred->btb = NULL;

    if (kind == PRED_BIMODAL || kind == PRED_BTB) {
        pred->bht = calloc(entries, sizeof(bht_entry_t));
        Assert(pred->bht != NULL, "无法分配 BHT");
        for (uint32_t i = 0; i < entries; i++) {
            // 初始为弱不跳：第一次 taken 会错，但一次更新后就能转向弱跳。
            pred->bht[i].counter = 1;
        }
    }

    if (kind == PRED_BTB) {
        pred->btb = calloc(entries, sizeof(btb_entry_t));
        Assert(pred->btb != NULL, "无法分配 BTB");
    }
}

static void predictor_free(predictor_t *pred) {
    free(pred->bht);
    free(pred->btb);
    pred->bht = NULL;
    pred->btb = NULL;
}

static void update_stats(stats_t *stats, const branch_info_t *br, const pred_result_t *pred, predictor_kind_t kind) {
    stats->total++;
    stats->taken += br->actual_taken;
    stats->type_count[br->type]++;

    /*
     * 方向命中和下一 PC 命中故意分开统计：
     *   - 方向命中体现 BHT/静态策略是否知道 taken；
     *   - 下一 PC 命中体现 IFU 是否真的取到了正确地址。
     *
     * 对 direct branch 来说，方向对通常 next_pc 也对；对 JALR 来说，如果 BTB
     * 没有正确 target，即使“知道它会跳”，下一 PC 仍然是错的。
     */
    bool dir_hit = pred->taken == br->actual_taken;
    bool pc_hit = pred->next_pc == br->dnpc;

    stats->dir_hit += dir_hit;
    stats->pc_hit += pc_hit;
    stats->type_miss[br->type] += !pc_hit;

    if (kind == PRED_BTB) {
        stats->btb_access++;
        stats->btb_hit += pred->btb_hit;
    }
}

static void display_usage(const char *prog) {
    fprintf(stderr,
        "用法: %s -f <BTRACE.bin> -p <预测器> [选项]\n"
        "\n"
        "预测器:\n"
        "  none          永远预测 pc+4，等价无分支预测基线\n"
        "  always-taken  条件/直接跳转默认预测跳转，JALR 无 BTB 时无法知道目标\n"
        "  btfnt         backward taken, forward not taken\n"
        "  bimodal       2-bit BHT，仅学习条件分支方向\n"
        "  btb           direct-mapped BTB + 2-bit BHT\n"
        "\n"
        "选项:\n"
        "  -f, --file <path>       BTRACE 文件，默认 %s\n"
        "  -p, --predictor <name>  预测器，默认 none\n"
        "  -e, --entries <num>     BHT/BTB 表项数，默认 16，必须是 2 的幂\n"
        "      --penalty <cycles>  单次误预测损失周期，默认 3\n"
        "      --insts <num>       总指令数，可选，用于计算 MPKI/分支间隔\n"
        "  -h, --help             显示帮助\n",
        prog, DEFAULT_TRACE_FILE);
}

static config_t parse_args(int argc, char **argv) {
    enum {
        OPT_PENALTY = 1000,
        OPT_INSTS,
    };

    static const struct option long_options[] = {
        {"file",      required_argument, NULL, 'f'},
        {"predictor", required_argument, NULL, 'p'},
        {"entries",   required_argument, NULL, 'e'},
        {"penalty",   required_argument, NULL, OPT_PENALTY},
        {"insts",     required_argument, NULL, OPT_INSTS},
        {"help",      no_argument,       NULL, 'h'},
        {0, 0, 0, 0},
    };

    config_t config = {
        .trace_file = DEFAULT_TRACE_FILE,
        .predictor = PRED_NONE,
        .entries = 16,
        .penalty = 3.0,
        .insts = 0,
    };

    int opt;
    while ((opt = getopt_long(argc, argv, "f:p:e:h", long_options, NULL)) != -1) {
        switch (opt) {
            case 'f': config.trace_file = optarg; break;
            case 'p': config.predictor = parse_predictor(optarg); break;
            case 'e': config.entries = parse_u32(optarg, "entries"); break;
            case OPT_PENALTY: config.penalty = parse_double(optarg, "penalty"); break;
            case OPT_INSTS: config.insts = parse_u64(optarg, "insts"); break;
            case 'h': display_usage(argv[0]); exit(0);
            default: display_usage(argv[0]); exit(1);
        }
    }

    Assert(is_pow2(config.entries), "entries 必须是 2 的幂: %u", config.entries);
    Assert(config.penalty >= 0.0, "penalty 不能为负数");
    return config;
}

static stats_t run_trace(const config_t *config) {
    FILE *fp = fopen(config->trace_file, "rb");
    Assert(fp != NULL, "无法打开 BTRACE 文件: %s", config->trace_file);

    predictor_t predictor;
    predictor_init(&predictor, config->predictor, config->entries);

    stats_t stats = {0};
    btrace_entry_t entry;
    while (fread(&entry, sizeof(entry), 1, fp) == 1) {
        branch_info_t br = make_branch_info(&entry);
        if (br.type == BR_UNKNOWN) {
            continue;
        }

        /*
         * 离线重放顺序必须和硬件时序一致：
         *   1. 用旧预测器状态预测当前分支；
         *   2. 用 BTRACE 里的真实 dnpc 统计预测结果；
         *   3. 用真实结果更新预测器，供后续分支使用。
         */
        pred_result_t pred = predictor_predict(&predictor, &br);
        update_stats(&stats, &br, &pred, predictor.kind);
        predictor_update(&predictor, &br);
    }

    fclose(fp);
    predictor_free(&predictor);
    return stats;
}

static void print_stats(const config_t *config, const stats_t *stats) {
    uint64_t pc_miss = stats->total - stats->pc_hit;
    uint64_t not_taken = stats->total - stats->taken;
    double lost_cycles = (double)pc_miss * config->penalty;

    /*
     * 人类可读统计用于直接看结果；最后一行 RESULT 是给 research.py 解析的
     * 稳定接口，后续调整中文输出时尽量不要随意改 RESULT 字段名。
     */
    printf("BranchSim result\n");
    printf("  预测器: %s\n", predictor_name(config->predictor));
    printf("  表项数: %u\n", config->entries);
    printf("  BTRACE: %s\n", config->trace_file);
    printf("\n");

    printf("  总分支数:       %" PRIu64 "\n", stats->total);
    for (branch_type_t type = 0; type < BR_NR; type++) {
        printf("  %s: %" PRIu64 "\n", branch_type_cn[type], stats->type_count[type]);
    }
    printf("  Taken:          %" PRIu64 " (%.4f%%)\n", stats->taken, rate(stats->taken, stats->total));
    printf("  Not taken:      %" PRIu64 " (%.4f%%)\n", not_taken, rate(not_taken, stats->total));
    printf("\n");

    printf("  方向命中:       %" PRIu64 " (%.4f%%)\n", stats->dir_hit, rate(stats->dir_hit, stats->total));
    printf("  下一 PC 命中:   %" PRIu64 " (%.4f%%)\n", stats->pc_hit, rate(stats->pc_hit, stats->total));
    printf("  下一 PC 失败:   %" PRIu64 "\n", pc_miss);
    for (branch_type_t type = 0; type < BR_NR; type++) {
        printf("  %s: %" PRIu64 "\n", branch_miss_cn[type], stats->type_miss[type]);
    }

    if (config->predictor == PRED_BTB) {
        printf("  BTB 命中:       %" PRIu64 " (%.4f%%)\n", stats->btb_hit, rate(stats->btb_hit, stats->btb_access));
    }

    printf("  估计损失周期:   %.2f\n", lost_cycles);
    if (config->insts != 0 && stats->total != 0) {
        printf("  分支间隔:       %.4f inst/branch\n", (double)config->insts / (double)stats->total);
        printf("  误预测 MPKI:    %.4f\n", 1000.0 * (double)pc_miss / (double)config->insts);
    }

    printf(
        "RESULT predictor=%s entries=%u branches=%" PRIu64
        " pc_hit=%" PRIu64 " pc_miss=%" PRIu64 " pc_accuracy=%.6f"
        " dir_accuracy=%.6f btb_hit_rate=%.6f lost_cycles=%.2f"
        " cond=%" PRIu64 " jal=%" PRIu64 " jalr=%" PRIu64 "\n",
        predictor_name(config->predictor),
        config->entries,
        stats->total,
        stats->pc_hit,
        pc_miss,
        rate(stats->pc_hit, stats->total),
        rate(stats->dir_hit, stats->total),
        rate(stats->btb_hit, stats->btb_access),
        lost_cycles,
        stats->type_count[BR_COND],
        stats->type_count[BR_JAL],
        stats->type_count[BR_JALR]);
}

int main(int argc, char **argv) {
    config_t config = parse_args(argc, argv);
    stats_t stats = run_trace(&config);
    print_stats(&config, &stats);
    return 0;
}
