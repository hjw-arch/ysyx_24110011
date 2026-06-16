#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <time.h>
#include "log.h"

#define MTRACE_MAIN_MAGIC	0x4d41494eU

#define ADDR_WIDTH		32

#if ADDR_WIDTH == 32
	typedef uint32_t addr_t;
#elif ADDR_WIDTH == 64
	typedef uint64_t addr_t;
#else
	#error "Address width must be 32 or 64!"
#endif


#define LOG2(n)		({	\
	int num = (n);	\
	int result = -1;	\
	while(num) {	\
		num >>= 1;	\
		result++;	\
	}	\
	result;	\
})

#define BIT_MASK(bits)			((1ull << (bits)) - 1)
#define GET_BITS(a, hi, lo)		(((a) & BIT_MASK((hi) + 1)) >> (lo))
#define GET_OFFSET(addr)		GET_BITS(addr, config.bits_for_offset - 1, 0)
#define GET_INDEX(addr)			GET_BITS(addr, config.bits_for_offset + config.bits_for_index - 1, config.bits_for_offset)
#define GET_TAG(addr)			GET_BITS(addr, ADDR_WIDTH - 1, config.bits_for_offset + config.bits_for_index)


static char *trace_file = NULL;

typedef enum {
	MODE_ICACHE,
	MODE_DCACHE
} mode_e;

typedef enum {
	ACCESS_STORE = 0,
	ACCESS_LOAD = 1,
	ACCESS_IFETCH
} access_type_e;

typedef enum {
	POLICY_PLRU,              ///< 伪最近最少使用 (Pseudo-Least Recently Used) 替换策略。
	POLICY_FIFO,              ///< 先进先出 (First-In, First-Out) 替换策略。
	POLICY_RANDOM             ///< 随机替换策略。
} replacement_policy_e;

typedef struct {
	mode_e mode;

	int total_size;				// cache总大小
	int block_size;				// cache块大小, 单位：字节
	int block_num;				// cache块数量
	int associativity;			// 相联度
	replacement_policy_e replacement_policy;	// 替换策略

	int set_num;
	int bits_for_offset;
	int bits_for_index;
	int bits_for_tag;
} cache_config_t;

#pragma pack(push, 1)
typedef struct {
	uint64_t addr;
	uint32_t len;
	uint32_t op;
} mtrace_entry_t;
#pragma pack(pop)

typedef struct cache_line {
	uint32_t valid;
	uint32_t dirty;		// 脏位，icache用不着
	uint64_t tag;		// 使用64位，防止是64位地址
} cache_line_t;

typedef struct cache_set {
	cache_line_t *cache_line;
	uint64_t plru_bits;		// 树结构位，用于寻找替死鬼块，对于N路组相联，需要N-1位表示其树形结构
	uint64_t fifo_pointer;	// 指向替死鬼块
} cache_set_t;

typedef struct {
	uint64_t access;
	uint64_t hit;
} counter_t;

typedef struct {
	counter_t total;
	counter_t ifetch;
	counter_t load;
	counter_t store;
	uint64_t dirty_writeback;
} cache_stats_t;

static cache_config_t config;
static cache_set_t *cache;
static cache_stats_t stats;

// 检查是否为2的次幂
uint32_t is_pow_2(uint32_t n) {
	return ((n > 0) && ((n & (n - 1)) == 0));
}

void display_usage(char *prog_name) {
	fprintf(stderr, "用法: %s -m <icache / dcache> -s <cache总大小> -b <块大小> -a <相联度> -r <替换策略> -f <追踪文件名>\n", prog_name);
	fprintf(stderr, "  参数说明:\n");
	fprintf(stderr, "    -m <模式>: CacheSim模式, 可选值: 'icache', 'dcache'.\n");
	fprintf(stderr, "    -s <大小>: Cache总大小 (单位: 字节, 必须是2的幂).\n");
	fprintf(stderr, "    -b <大小>: Cache块大小 (单位: 字节, 必须是2的幂).\n");
	fprintf(stderr, "    -a <路数>: 相联度 (多少路组相联, 必须是2的幂).\n");
	fprintf(stderr, "               值为 1 表示直接映射 (Direct Mapped).\n");
	fprintf(stderr, "               若 块数量 == 相联度, 则为全相联 (Fully Associative).\n");
	fprintf(stderr, "    -r <替换策略>: 替换策略。可选值: 'FIFO', 'PLRU', 'RANDOM'.\n");
	fprintf(stderr, "    -f <trace文件>: trace 文件路径。icache 使用 ITRACE.bin，dcache 使用 MTRACE.bin。\n");
	fprintf(stderr, "               ITRACE.bin 每条记录为一个 addr_t PC；MTRACE.bin 每条记录为 addr/len/op。\n");
	fprintf(stderr, "    -h        : 显示此帮助信息并退出。\n");
	fprintf(stderr, "  示例:\n");
	fprintf(stderr, "    %s -m icache -s 64 -b 32 -a 1 -r PLRU -f /path/to/ITRACE.bin\n", prog_name);
	fprintf(stderr, "    %s -m dcache -s 512 -b 32 -a 1 -r PLRU -f /path/to/MTRACE.bin\n", prog_name);
}

// 检查cache配置参数是否合适，不支持非2的次幂的参数配置
// 如果cache的组数和相联度是2的次幂，说明cache的总块数一定是2的次幂
void check_config(char *prog_name) {
	if (config.associativity == 0 || config.total_size == 0 || config.block_size == 0) {
		display_usage(prog_name);
		Assert(0, "Missing initialization parameter(s).");
	}

	if (trace_file == NULL) {
		display_usage(prog_name);
		Assert(0, "Missing trace file.");
	}

	if (!is_pow_2(config.total_size)) {
		Assert(0, "Cache szie must be power of 2 and cache size can not be zero.");
	}

	if (!is_pow_2(config.block_size)) {
		Assert(0, "Block size must be power of 2 and block size can not be zero.");
	}

	if (!is_pow_2(config.associativity)) {
		Assert(0, "Associativity must be power of 2 and associativity can not be zero.");
	}
}

// 解析命令行的命令
void parse_arguments(int argc, char **argv) {
	int opt;
	int option_index = 0;
	static const struct option long_options[] = {
		{"mode",			required_argument, 	NULL, 'm'},
		{"size",			required_argument, 	NULL, 's'},
		{"block_size",		required_argument, 	NULL, 'b'},
		{"assoc",			required_argument, 	NULL, 'a'},
		{"replace",			required_argument, 	NULL, 'r'},
		{"file",			required_argument, 	NULL, 'f'},
		{"help",			no_argument, 		NULL, 'h'},
		{0, 0, 0, 0}
	};

	while ((opt = getopt_long(argc, argv, "m:s:b:a:r:f:h", long_options, &option_index)) != -1) {
		switch (opt) {
			case 'm':
				if (strcmp(optarg, "icache") == 0) {
					config.mode = MODE_ICACHE;
				} else if (strcmp(optarg, "dcache") == 0) {
					config.mode = MODE_DCACHE;
				} else {
					Assert(0, "Invalid cache mode.");
				}
				break;
			case 's':
				config.total_size = atoi(optarg);
				break;
			case 'b':
				config.block_size = atoi(optarg);
				break;
			case 'a':
				config.associativity = atoi(optarg);
				break;
			case 'r':
				if (strcmp(optarg, "FIFO") == 0) {
					config.replacement_policy = POLICY_FIFO;
				} else if (strcmp(optarg, "PLRU") == 0) {
					config.replacement_policy = POLICY_PLRU;
				} else if (strcmp(optarg, "RANDOM") == 0) {
					config.replacement_policy = POLICY_RANDOM;
				} else {
					Assert(0, "Invalid replacement policy.");
				}
				break;
			case 'f':
				trace_file = optarg;
				break;
			case 'h':
				display_usage(argv[0]);
				exit(0);
			default:
				display_usage(argv[0]);
				Assert(0, "Unknown argument(s)!");
				break;
		}
	}
}


void init_cache(char *prog_name) {
	check_config(prog_name);

	config.block_num = config.total_size / config.block_size;
	config.set_num = config.block_num / config.associativity;		// 组数量
	Assert(config.set_num > 0, "Invalid cache geometry.");

	config.bits_for_offset = LOG2(config.block_size);
	config.bits_for_index = LOG2(config.set_num);
	config.bits_for_tag = ADDR_WIDTH - config.bits_for_offset - config.bits_for_index;

	cache = (cache_set_t *)malloc(config.set_num * sizeof(cache_set_t));
	Assert(cache, "Fail to alloc memory for cache.");

	// 分配内存
	for (uint32_t i = 0; i < config.set_num; i++) {
		cache[i].cache_line = (cache_line_t *)calloc(config.associativity, sizeof(cache_line_t));		// 初始化为0

		if (!cache[i].cache_line) {
			perror("Fail to alloc memory for cache line.");

			for (uint32_t j = 0; j < i; j++) {
				free(cache[j].cache_line);
				cache[j].cache_line = NULL;		// 避免悬挂指针，安全考虑
			}

			free(cache);
			cache = NULL;
			exit(-1);
		}

		cache[i].fifo_pointer = 0;
		cache[i].plru_bits = 0;
	}

	// 如果采用随机替换算法，初始化一个随机种子
	// 随机种子使用当前时间
	if (config.replacement_policy == POLICY_RANDOM) {
		srand(time(NULL));
	}

	// 打印配置信息
	printf("--- Cache 配置初始化完成 ---\n");
	printf("总大小:         %d 字节\n", config.total_size);
	printf("块大小:         %d 字节\n", config.block_size);
	printf("总行数:         %d\n", config.block_num);
	printf("相联度:         %d 路\n", config.associativity);
	printf("总组数:         %d\n", config.set_num);
	printf("替换策略:       %s\n", config.replacement_policy == POLICY_FIFO ? "FIFO" :
	                                   (config.replacement_policy == POLICY_PLRU ? "PLRU" : "Random"));
	printf("块内偏移位数:   %d\n", config.bits_for_offset);
	printf("组索引位数:     %d\n", config.bits_for_index);
	printf("标签位数:       %d\n", config.bits_for_tag);
	printf("---------------------------\n");
}

// 根据hit_way将沿途的bit都设置为远离hit way
void update_plru_victim_way(cache_set_t *current_cache_set, uint32_t hit_way) {
	if (config.associativity == 1) {	// 直接映射，无需更新状态
		return;
	}

	uint32_t tree_level = LOG2(config.associativity);

	uint32_t current_node_index = 0;		// 记录当前节点的索引

	for (uint32_t i = 0; i < tree_level; i++) {
		uint32_t shift = tree_level - 1 - i;
		uint32_t direction = (hit_way >> shift) & 1;	// 获取hit_way最高位

		if (direction) {
			current_cache_set->plru_bits &= ~(1ULL << current_node_index);
		} else {
			current_cache_set->plru_bits |= (1ULL << current_node_index);
		}

		current_node_index = current_node_index * 2 + 1 + direction;		// 更新当前节点的索引
	}
}

// 从根节点找victim_way 沿途的bit都要远离victim way
uint64_t find_and_update_plru_victim_way(cache_set_t *current_cache_set) {
	if (config.associativity == 1) {	// 直接映射，直接返回0
		return 0;
	}

	uint32_t tree_level = LOG2(config.associativity);	// 树的高度

	uint64_t victim_way = 0;

	uint32_t current_node_index = 0;

	for (uint32_t i = 0; i < tree_level; i++) {
		uint32_t bit = (current_cache_set->plru_bits >> current_node_index) & 1;	// 根据plru_bits找到当前的节点

		if (bit) {
			current_cache_set->plru_bits &= ~(1ULL << current_node_index);
		} else {
			current_cache_set->plru_bits |= (1ULL << current_node_index);
		}

		current_node_index = current_node_index * 2 + 1 + bit;

		victim_way = (victim_way << 1) | bit;	// 计算victim_way，二叉树的特性
	}

	return victim_way;
}

uint64_t find_and_update_fifo_victim_way(cache_set_t *current_cache_set) {
	uint64_t ret = current_cache_set->fifo_pointer;
	current_cache_set->fifo_pointer = (current_cache_set->fifo_pointer + 1) % config.associativity;
	return ret;
}

uint64_t find_random_victim_way() {
	return rand() % config.associativity;
}

void access_cache(addr_t addr, access_type_e type) {
	counter_t *counter = NULL;
	switch (type) {
		case ACCESS_IFETCH:
			counter = &stats.ifetch;
			break;
		case ACCESS_LOAD:
			counter = &stats.load;
			break;
		case ACCESS_STORE:
			counter = &stats.store;
			break;
		default:
			Assert(0, "Invalid memory access type.");
			return;
	}

	uint64_t index 	= GET_INDEX(addr);
	uint64_t tag	= GET_TAG(addr);

	cache_set_t *current_cache_set = &cache[index];

	int hit_way = -1;

	for (uint32_t i = 0; i < config.associativity; i++) {
		if (tag == current_cache_set->cache_line[i].tag && current_cache_set->cache_line[i].valid) {
			// 命中
			hit_way = i;
			break;
		}
	}

	stats.total.access++;
	counter->access++;

	if (hit_way != -1) {	// cache 命中
		stats.total.hit++;
		counter->hit++;
		
		// store 需要将对应cacheline置为脏
		if (type == ACCESS_STORE) {
			current_cache_set->cache_line[hit_way].dirty = 1;
		}

		// 如果是LRU，需要更新其牺牲者状态，FIFO和RANDOM无需处理
		if (config.replacement_policy == POLICY_PLRU) {
			update_plru_victim_way(current_cache_set, hit_way);
		}
	} else {	// cache 缺失
		int victim_way = -1;	// 牺牲者编号

		switch (config.replacement_policy) {
			case POLICY_PLRU:
				victim_way = find_and_update_plru_victim_way(current_cache_set);
				break;
			case POLICY_FIFO:
				victim_way = find_and_update_fifo_victim_way(current_cache_set);
				break;
			case POLICY_RANDOM:
				victim_way = find_random_victim_way();
				break;
			default:
				break;
		}

		Assert(victim_way >= 0 && victim_way < config.associativity, "Error victim way.");

		if (current_cache_set->cache_line[victim_way].valid && current_cache_set->cache_line[victim_way].dirty) {
			stats.dirty_writeback++;
		}

		current_cache_set->cache_line[victim_way].tag = tag;
		current_cache_set->cache_line[victim_way].valid = 1;
		current_cache_set->cache_line[victim_way].dirty = (type == ACCESS_STORE);
	}
}

// 读出trace值，以此模拟
void sim_icache() {
	FILE *fp = fopen(trace_file, "rb");
	if (!fp) {
		Assert(0, "Open trace file failed.");
	}

	printf("Begin icache simulation...\n");

	addr_t addr;
	uint64_t access_count = 0;

	while (fread(&addr, sizeof(addr_t), 1, fp) == 1) {
		access_cache(addr, ACCESS_IFETCH);
		access_count++;

		if (access_count % 1000000 == 0) {
			printf("已处理 %lu 个地址...\n", access_count);
		}
	}

	if (ferror(fp)) {
		fclose(fp);
		Assert(0, "Error(s) occurred while reading the trace file.");
	}

	fclose(fp);
	printf("追踪文件处理完毕。共处理 %lu 个地址。\n", access_count);
}

void sim_dcache() {
	FILE *fp = fopen(trace_file, "rb");
	if (!fp) {
		Assert(0, "Open trace file failed.");
	}

	printf("Begin dcache simulation...\n");

	mtrace_entry_t mtrace_entry;
	uint64_t access_count = 0;
	uint32_t is_entered_main = 0;

	while (fread(&mtrace_entry, sizeof(mtrace_entry), 1, fp) == 1) {
		if (mtrace_entry.addr == MTRACE_MAIN_MAGIC &&
		    mtrace_entry.len == MTRACE_MAIN_MAGIC &&
		    mtrace_entry.op == MTRACE_MAIN_MAGIC) {
			is_entered_main = 1;
			continue;
		}

		if (!is_entered_main) {
			continue;
		}

		access_cache(mtrace_entry.addr, (access_type_e)mtrace_entry.op);

		access_count++;

		if (access_count % 1000000 == 0) {
			printf("已处理 %lu 个地址...\n", access_count);
		}
	}

	if (ferror(fp)) {
		fclose(fp);
		Assert(0, "Error(s) occurred while reading the trace file.");
	}

	fclose(fp);
	printf("追踪文件处理完毕。共处理 %lu 次访存。\n", access_count);
}


void sim_cache() {
	if (config.mode == MODE_ICACHE) {
		sim_icache();
		return;
	}
	
	sim_dcache();
}


// 释放为cache申请的内存
void cleanup_memory() {
	if (cache) {
		for (uint32_t i = 0; i < config.set_num; i++) {
			if (cache[i].cache_line) {
				free(cache[i].cache_line);
				cache[i].cache_line = NULL;
			}
		}
		free(cache);
		cache = NULL;
	}
}

void print_counter(const char *name, counter_t counter) {
	printf("%s访问次数: %lu\n", name, counter.access);
	printf("%s命中次数: %lu\n", name, counter.hit);
	printf("%s缺失次数: %lu\n", name, counter.access - counter.hit);
	if (counter.access > 0) {
		printf("%s命中率:   %.4f%%\n", name, (double)counter.hit / counter.access * 100.0);
	} else {
		printf("%s命中率:   N/A (无访问记录)\n", name);
	}
}

void display_statistics() {
	printf("\n--- 模拟结果统计 ---\n");
	print_counter("总计   ", stats.total);

	if (config.mode == MODE_ICACHE) {
		puts("");
		print_counter("IFETCH ", stats.ifetch);
	} else {
		puts("");
		print_counter("LOAD   ", stats.load);
		puts("");
		print_counter("STORE  ", stats.store);
		printf("\n脏块写回次数:        %lu\n", stats.dirty_writeback);
	}
	printf("----------------------\n");
}

int main(int argc, char **argv) {
	parse_arguments(argc, argv);

	init_cache(argv[0]);

	sim_cache();

	cleanup_memory();

	display_statistics();

	return 0;
}
