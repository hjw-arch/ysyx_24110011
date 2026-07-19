/***************************************************************************************
 * Copyright (c) 2014-2022 Zihao Yu, Nanjing University
 *
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <stdint.h>
#include "../include/memory/vaddr.h"
#include "../include/memory/paddr.h"
#include "sdb.h"

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char *rl_gets() {
    static char *line_read = NULL;

    if (line_read) {
        free(line_read);
        line_read = NULL;
    }

    line_read = readline("(nemu) ");

    if (line_read && *line_read) {
        add_history(line_read);
    }

    return line_read;
}

#define BUFFER_SIZE     16

#if defined(CONFIG_ITRACE) || defined(CONFIG_MTRACE) || defined(CONFIG_BTRACE)

void init_trace_file(FILE **trace_file_fp, const char *trace_file) {
    if (*trace_file_fp) {
        return;
    }

    *trace_file_fp = fopen(trace_file, "wb");
    Assert(*trace_file_fp, "Open trace file '%s' failed.", trace_file);
}

void close_trace_file(FILE **trace_file_fp, const char *trace_file) {
    if (!*trace_file_fp) {
        return;
    }

    if (fclose(*trace_file_fp) == EOF) {
        Assert(0, "Close trace file '%s' failed.", trace_file);
    }

    *trace_file_fp = NULL;
}

#endif

#if defined(CONFIG_FTRACE) || defined(CONFIG_MTRACE2FILE) || defined(CONFIG_BTRACE)

/*
 * ELF32 文件和 ftrace 需要的部分：
 *
 *   +-------------------------------+
 *   | Elf32_Ehdr                    |  ELF 文件头
 *   |   e_ident                     |    魔数、32/64 位、小端/大端等
 *   |   e_type                      |    文件类型，AM 程序通常是 ET_EXEC
 *   |   e_shoff                     |    section header table 在文件内的偏移
 *   |   e_shnum                     |    section header 数量
 *   |   e_shstrndx                  |    section 名字字符串表(.shstrtab)下标
 *   +-------------------------------+
 *   | ...                           |
 *   +-------------------------------+
 *   | Elf32_Shdr[e_shnum]           |  section header table
 *   |   .text/.data/.symtab/.strtab |    每个 section 一个 Elf32_Shdr
 *   +-------------------------------+
 *
 * ftrace 只需要两类 section：
 *
 *   .symtab：符号表，由多个 Elf32_Sym 组成。每个符号记录地址、大小、类型等。
 *   .strtab：符号名字符串表。Elf32_Sym.st_name 不是字符串，而是 .strtab 内偏移。
 *
 * 重要关系：
 *   .symtab section header 的 sh_link 字段，指向它配套的 .strtab。
 *
 * 因此正确流程是：
 *   1. 读取并检查 ELF header；
 *   2. 扫描 section header table，找到 SHT_SYMTAB；
 *   3. 根据 symtab.sh_link 找到对应的 SHT_STRTAB；
 *   4. 读取 .strtab，再遍历 .symtab；
 *   5. 只保存 STT_FUNC 函数符号，供 ftrace 根据 PC 查函数名。
 */

#include <elf.h>
extern char *elf_file;

typedef struct _symtab{
    char name[64];
    uint32_t start_addr;
    uint32_t end_addr;
} symtab;

static symtab symtabs[1024];
static uint32_t symtab_count = 0;

void decode_elf() {
    if (elf_file == NULL) {
        Log("No elf file is given, ftrace function is not allowed to use.");
        return;
    }

    FILE *fp = fopen(elf_file, "rb");
    Assert(fp, "Can not open '%s'", elf_file);

    Elf32_Ehdr ehdr;
    int ret = fread(&ehdr, sizeof(Elf32_Ehdr), 1, fp);
    assert(ret == 1);

    if (ehdr.e_ident[EI_MAG0] != ELFMAG0 || ehdr.e_ident[EI_MAG1] != ELFMAG1 ||
        ehdr.e_ident[EI_MAG2] != ELFMAG2 || ehdr.e_ident[EI_MAG3] != ELFMAG3) {
        Assert(0, "Invalid ELF file.");
    }

    if (ehdr.e_ident[EI_CLASS] != ELFCLASS32) {
        Assert(0, "Invalid ELF class, only 'ELF32' is supported now.");
    }

    if (ehdr.e_type != ET_EXEC) {
        Assert(0, "Invalid ELF type, only 'ET_EXEC' is supported now.");
    }

    Elf32_Shdr shdr;
    Elf32_Shdr symtab_shdr = {};
    Elf32_Shdr strtab_shdr = {};
    bool found_symtab = false;

    // 第一遍只找 .symtab。不要直接拿“第一个字符串表”，ELF 中可能同时存在
    // .shstrtab(section 名字表)和 .strtab(符号名字表)。
    fseek(fp, (long)ehdr.e_shoff, SEEK_SET);
    for (int i = 0; i < ehdr.e_shnum; i++) {
        ret = fread(&shdr, sizeof(Elf32_Shdr), 1, fp);
        assert(ret == 1);

        if (shdr.sh_type == SHT_SYMTAB) {
            symtab_shdr = shdr;
            found_symtab = true;
            break;
        }
    }

    Assert(found_symtab, "Can not find ELF symbol table.");
    Assert(symtab_shdr.sh_link < ehdr.e_shnum, "Invalid ELF symbol string table index.");

    // .symtab.sh_link 指向对应的字符串表 section，里面保存函数名等符号名。
    fseek(fp, (long)(ehdr.e_shoff + symtab_shdr.sh_link * sizeof(Elf32_Shdr)), SEEK_SET);
    ret = fread(&strtab_shdr, sizeof(Elf32_Shdr), 1, fp);
    assert(ret == 1);
    Assert(strtab_shdr.sh_type == SHT_STRTAB, "Invalid ELF symbol string table.");

    char *str_buffer = (char *)malloc(strtab_shdr.sh_size);
    Assert(str_buffer, "Malloc failed, can not decode ELF string table.");

    fseek(fp, (long)strtab_shdr.sh_offset, SEEK_SET);
    ret = fread(str_buffer, strtab_shdr.sh_size, 1, fp);
    assert(ret == 1);

    // 遍历符号表。只把函数符号存入 symtabs[]，其它变量/section/file 符号都跳过。
    fseek(fp, (long)symtab_shdr.sh_offset, SEEK_SET);
    uint32_t sym_num = symtab_shdr.sh_size / sizeof(Elf32_Sym);

    for (uint32_t i = 0; i < sym_num; i++) {
        Elf32_Sym sym;
        ret = fread(&sym, sizeof(Elf32_Sym), 1, fp);
        assert(ret == 1);

        if (ELF32_ST_TYPE(sym.st_info) != STT_FUNC) continue;
        if (sym.st_name >= strtab_shdr.sh_size) continue;
        if (symtab_count >= sizeof(symtabs) / sizeof(symtabs[0])) break;

        symtabs[symtab_count].start_addr = sym.st_value;
        symtabs[symtab_count].end_addr = sym.st_value + sym.st_size;
        snprintf(symtabs[symtab_count].name, sizeof(symtabs[symtab_count].name), "%s", str_buffer + sym.st_name);
        symtab_count++;
    }

    free(str_buffer);
    fclose(fp);
}

#if defined(CONFIG_MTRACE2FILE) || defined(CONFIG_BTRACE)

static uint32_t entry_main_flag = 0;
static vaddr_t main_addr;

static void get_main_addr() {
    for (uint32_t i = 0; i < symtab_count; i++) {
        if (strcmp(symtabs[i].name, "main") == 0) {
            main_addr = symtabs[i].start_addr;
            return;
        }
    }
    Assert(0, "Error, Failed to find symbol 'main'.");
}

void set_entry_main_flag() {
    if (entry_main_flag) return;

    if (cpu.pc == main_addr) {
        entry_main_flag = 1;
    }

}

#endif

#endif



#ifdef CONFIG_ITRACE
#ifdef CONFIG_ITRACE2FILE

static FILE *itrace_output_file_fp = NULL;
static char *itrace_file = "/home/hjw-arch/ysyx-workbench/ITRACE.bin";
static uint64_t normal_mode_total_inst_num = 0;


static void itrace2file(vaddr_t addr) {
    if (!itrace_output_file_fp) {
        init_trace_file(&itrace_output_file_fp, itrace_file);
    }

	if (addr < CONFIG_ITRACE_START_ADDR || addr > CONFIG_ITRACE_END_ADDR) return;

	normal_mode_total_inst_num++;
    size_t items_written = fwrite(&addr, sizeof(vaddr_t), 1, itrace_output_file_fp);
    if (items_written != 1) {
        fprintf(stderr, "Serious error: Failed to write the address to the trace file!\n");
        if (ferror(itrace_output_file_fp)) {
            perror("           文件写入错误详情");
        }
        close_trace_file(&itrace_output_file_fp, itrace_file);
    }
}

#endif

// ringbuffer
typedef struct _itrace_entry_t {
    vaddr_t addr;
    uint32_t inst;
} itrace_entry_t;
static itrace_entry_t iringbuf[BUFFER_SIZE];
static uint32_t iringbuf_index = 0;

void itrace_write(vaddr_t addr, uint32_t inst) {
    iringbuf[iringbuf_index].addr = addr;
    iringbuf[iringbuf_index].inst = inst;
    iringbuf_index = (iringbuf_index + 1) % BUFFER_SIZE;
	IFDEF(CONFIG_ITRACE2FILE, itrace2file(addr));
}

void itrace_display() {
    uint32_t start_index = iringbuf_index;
    uint32_t end_index = iringbuf_index == 0 ? BUFFER_SIZE - 1 : iringbuf_index - 1;
    uint32_t index = start_index;
    puts("\n");
    while(1) {
        if (index > BUFFER_SIZE - 1) index = 0;
        if (iringbuf[index].addr == 0) {
            if(index == end_index) break;
            index++;
            continue;
        }

        printf("0x%08x: ", iringbuf[index].addr);

        printf("%02x ", (iringbuf[index].inst & 0xff000000) >> 24);
        printf("%02x ", (iringbuf[index].inst & 0x00ff0000) >> 16);
        printf("%02x ", (iringbuf[index].inst & 0x0000ff00) >> 8);
        printf("%02x       ",  (uint8_t)iringbuf[index].inst);

#ifndef CONFIG_ISA_loongarch32r
        char disasm_buf[64];
        void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
        disassemble(disasm_buf, 64, iringbuf[index].addr, (uint8_t *)&iringbuf[index].inst, 4);
        printf("%s\n", disasm_buf);
#else
        p[0] = '\0'; // the upstream llvm does not support loongarch32r
#endif
        
        if(index == end_index) break;
        index++;
    }
    puts("\n");
}

#endif

#ifdef CONFIG_MTRACE

// ringbuffer
typedef struct _mtrace_entry_t {
    vaddr_t pc;
    vaddr_t addr;
    uint32_t len;
    word_t content;
    uint32_t is_load;
} mtrace_entry_t;

static mtrace_entry_t mringbuf[BUFFER_SIZE];
static uint32_t mringbuf_index = 0;

#ifdef CONFIG_MTRACE2FILE
static FILE *mtrace_output_file_fp = NULL;
static char *mtrace_file = "/home/hjw-arch/ysyx-workbench/MTRACE.bin";

// 使用 1 字节对齐，确保二进制文件中没有 padding，方便 Python 按固定偏移解析
#pragma pack(push, 1)
typedef struct {
    uint64_t addr;  // 访存物理/虚拟地址
    uint32_t len;   // 访存长度
    uint32_t op;    // 0: store, 1: load
} mtrace_record_t;
#pragma pack(pop)

void mtrace_write(vaddr_t addr, uint32_t len, uint32_t op) {
    // op: 
    //  1: load
    //  0: store

    // 懒加载
    if (!mtrace_output_file_fp) {
        init_trace_file(&mtrace_output_file_fp, mtrace_file);
    }

    static uint32_t last_main_flag = 0;
    if (last_main_flag == 0 && entry_main_flag == 1) {
        last_main_flag = 1;
        mtrace_record_t magic_main_record = {
            .addr = (uint64_t)0x4d41494eu,
            .len  = (uint32_t)0x4d41494eu,
            .op   = (uint32_t)0x4d41494eu
        };

        size_t items_written = fwrite(&magic_main_record, sizeof(magic_main_record), 1, mtrace_output_file_fp);
        if (items_written != 1) {
            fprintf(stderr, "Serious error: Failed to write to the mtrace file!\n");
            if (ferror(mtrace_output_file_fp)) {
                perror("           文件写入错误详情");
            }
        }
    }

    // 统一转换为固定宽度类型，消除 RV32/RV64 差异
    mtrace_record_t record = {
        .addr = (uint64_t)addr,
        .len  = (uint32_t)len,
        .op   = (uint32_t)op
    };

    size_t items_written = fwrite(&record, sizeof(record), 1, mtrace_output_file_fp);

    if (items_written != 1) {
        fprintf(stderr, "Serious error: Failed to write to the mtrace file!\n");
        if (ferror(mtrace_output_file_fp)) {
            perror("           文件写入错误详情");
        }
        
        close_trace_file(&mtrace_output_file_fp, mtrace_file);
    }
}

#endif


static void mtrace_record(vaddr_t addr, uint32_t len, word_t content, uint32_t is_load) {
    if (addr < CONFIG_MTRACE_START_ADDR || addr > CONFIG_MTRACE_END_ADDR) return;
    mringbuf[mringbuf_index] = (mtrace_entry_t){cpu.pc, addr, len, content, is_load};
    mringbuf_index = (mringbuf_index + 1) % BUFFER_SIZE;
    IFDEF(CONFIG_MTRACE2FILE, mtrace_write(addr, len, is_load));
}

void mtrace_load(vaddr_t addr, uint32_t len, word_t content) {
    mtrace_record(addr, len, content, 1);
}

void mtrace_store(vaddr_t addr, uint32_t len, word_t content) {
    mtrace_record(addr, len, content, 0);
}

void mtrace_display() {
    uint32_t start_index = mringbuf_index;
    uint32_t end_index = mringbuf_index == 0 ? BUFFER_SIZE - 1 : mringbuf_index - 1;
    uint32_t index = start_index;
    puts("\nMemory trace:\n");
    while(1) {
        if (index > BUFFER_SIZE - 1) index = 0;

        if (mringbuf[index].pc == 0) {          // 空的或者没满
            if(index == end_index) break;
            index++;
            continue;
        }

        printf("PC: 0x%08x | Addr: 0x%08x | Length: %02d | context: 0x%08x | type: %s\n", mringbuf[index].pc, mringbuf[index].addr, mringbuf[index].len, mringbuf[index].content, 
        mringbuf[index].is_load ? "load" : "store");

        if(index == end_index) break;
        index++;
    }
    puts("\n");
}

#endif


//  ftrace
#ifdef CONFIG_FTRACE

typedef struct _ftrace{
    uint32_t pc_now;
    uint32_t action;
    uint32_t pc_target;
}ftrace;

static ftrace fring_ftrace[64];
static uint32_t fring_index = 0;
static uint32_t fring_count = 0;

static const symtab *find_func(vaddr_t addr) {
    for (uint32_t i = 0; i < symtab_count; i++) {
        if (symtabs[i].start_addr <= addr && addr < symtabs[i].end_addr) {
            return &symtabs[i];
        }
    }
    return NULL;
}

void record_ftrace(uint32_t pc_now, uint32_t action, uint32_t pc_target) {
    if (elf_file == NULL) return;
    if (action == FTRACE_TAIL) {
        const symtab *from = find_func(pc_now);
        const symtab *to = find_func(pc_target);
        if (to == NULL || to == from) return;
    }
    fring_ftrace[fring_index] = (ftrace){pc_now, action, pc_target};
    fring_index = (fring_index + 1) % ARRLEN(fring_ftrace);
    if (fring_count < (uint32_t)ARRLEN(fring_ftrace)) fring_count++;
}

void display_ftrace() {
    if (elf_file == NULL) return;
    uint32_t index = (fring_index + ARRLEN(fring_ftrace) - fring_count) % ARRLEN(fring_ftrace);
    int indent = 0;

    for (uint32_t n = 0; n < fring_count; n++) {
        const ftrace *entry = &fring_ftrace[index];
        const symtab *func = find_func(entry->action == FTRACE_RET ? entry->pc_now : entry->pc_target);
        const char *func_name = func ? func->name : "???";

        if (entry->action == FTRACE_CALL) {
            printf("0x%08x: %*scall [%s@0x%08x]\n", entry->pc_now, indent, "", func_name, entry->pc_target);
            indent += 2;
        } else if (entry->action == FTRACE_RET) {
            if (indent >= 2) indent -= 2;
            printf("0x%08x: %*sret  [%s]\n", entry->pc_now, indent, "", func_name);
        } else {
            printf("0x%08x: %*stail [%s@0x%08x]\n", entry->pc_now, indent, "", func_name, entry->pc_target);
        }

        index = (index + 1) % ARRLEN(fring_ftrace);
    }
}

#endif

#ifdef CONFIG_DTRACE

typedef struct dtrace
{
    const char *name;
    vaddr_t addr;
    bool isWrite;
} dtrace;

static dtrace dtrace_buf[BUFFER_SIZE];
static uint32_t dtrace_index = 0;

#include "../include/device/map.h"
void record_dtrace(const char *name, bool isWrite) {
    dtrace_buf[dtrace_index++] = (dtrace){.name = name, .addr = cpu.pc, .isWrite = isWrite};
    dtrace_index = dtrace_index % BUFFER_SIZE;
}

void display_dtrace() {
    uint32_t start_index = dtrace_index;
    uint32_t end_index = dtrace_index == 0 ? BUFFER_SIZE - 1 : dtrace_index - 1;
    uint32_t index = start_index;

    puts("\nDevice Trace:");

    puts("Action\t\tAT\t\tDevice Name");

    while (1)
    {
        if (dtrace_buf[index].addr == 0) {
            if (index == end_index) {
                break;
            }
            index++;
            index = index % BUFFER_SIZE;
            continue;
        }

        if (dtrace_buf[index].isWrite) printf("Wirte");
        else printf("Read");
        printf("\t\t");

        printf("0x%08x\t", dtrace_buf[index].addr);

        printf("%s\n", dtrace_buf[index].name);

        if (index == end_index) {
            break;
        }

        index++;
        index = index % BUFFER_SIZE;
    }
}

#endif

#ifdef CONFIG_ETRACE

typedef struct etrace
{
    vaddr_t pc;
    uint32_t cause;
    uint32_t tvec;
} etrace;

static etrace etrace_buf[BUFFER_SIZE];
static uint32_t etrace_index = 0;

void record_etrace(vaddr_t pc, uint32_t cause, uint32_t tvec) {
    etrace_buf[etrace_index] = (etrace){.pc = pc, .cause = cause, .tvec = tvec};
    etrace_index = (etrace_index + 1) % BUFFER_SIZE;
}


void display_etrace() {
    uint32_t start_index = etrace_index;
    uint32_t end_trace = etrace_index == 0 ? BUFFER_SIZE - 1 : etrace_index - 1;
    uint32_t index = start_index;
    puts("Expection Trace:");
    puts("AT\t\treason\t\tTrap vector\t");
    while (1) {
        if (etrace_buf[index].pc == 0) {
            if (index == end_trace) break;
            index = (index + 1) % BUFFER_SIZE;
            continue;
        }
        printf("0x%08x\t%d\t\t0x%08x\n", etrace_buf[index].pc, etrace_buf[index].cause, etrace_buf[index].tvec);
        if (index == end_trace) break;
        index = (index + 1) % BUFFER_SIZE;
    }
}


#endif


#ifdef CONFIG_BTRACE
static uint64_t btrace_record_count = 0;

#pragma pack(push, 1)
typedef struct _btrace_record_t {
    uint64_t pc;
    uint64_t snpc;
    uint64_t dnpc;
    uint32_t inst;
} btrace_record_t;
#pragma pack(pop)

static FILE *btrace_output_file_fp = NULL;
static char *btrace_file = "/home/hjw-arch/ysyx-workbench/BTRACE.bin";

static void btrace_write(vaddr_t pc, vaddr_t snpc, vaddr_t dnpc, uint32_t inst) {
    // 懒加载
    if (!btrace_output_file_fp) {
        init_trace_file(&btrace_output_file_fp, btrace_file);
    }

    // 统一转换为固定宽度类型，消除 RV32/RV64 差异
    btrace_record_t record = {
        .pc = pc,
        .snpc = snpc,
        .dnpc = dnpc,
        .inst = inst
    };

    size_t items_written = fwrite(&record, sizeof(record), 1, btrace_output_file_fp);

    if (items_written != 1) {
        fprintf(stderr, "Serious error: Failed to write to the btrace file!\n");
        if (ferror(btrace_output_file_fp)) {
            perror("           文件写入错误详情");
        }
        
        close_trace_file(&btrace_output_file_fp, btrace_file);
    }
}

// 简单判断
static bool is_branch_inst(uint32_t inst) {
    uint32_t opcode = inst & 0x7f;
    return opcode == 0x63 || opcode == 0x6f || opcode == 0x67;
}

void btrace_record(vaddr_t pc, vaddr_t snpc, vaddr_t dnpc, uint32_t inst) {
    if (!entry_main_flag) return;

    if (!is_branch_inst(inst)) return;

    if (btrace_record_count >= CONFIG_BTRACE_MAX_RECORDS) return;

    btrace_write(pc, snpc, dnpc, inst);
    btrace_record_count++;
}

#endif

void trace_finish() {
    IFDEF(CONFIG_ITRACE2FILE, close_trace_file(&itrace_output_file_fp, itrace_file));
    IFDEF(CONFIG_MTRACE2FILE, close_trace_file(&mtrace_output_file_fp, mtrace_file));
    IFDEF(CONFIG_BTRACE, close_trace_file(&btrace_output_file_fp, btrace_file));
}

static int cmd_c(char *args) {
    cpu_exec(-1);
    return 0;
}

static int cmd_q(char *args) {
    trace_finish();
    nemu_state.state = NEMU_QUIT;
    return -1;
}

// 实现单步运行
static int cmd_si(char *args) {
    char *num_p = strtok(args, " ");
    int num = (num_p == NULL) ? 1 : atoi(num_p);
    if (num > (0x7fffffff) || num < 0) {
        printf("The \"N\" is out of range, N ranges from 0 to 2,147,483,647\n");
        return 0;
    }

    for (int i = 0; i < num; ++i) {
        cpu_exec(1);
    }

    return 0;
}

// 实现打印寄存器/监视点
static int cmd_info(char *args) {
    char *next_arg = strtok(args, " ");
    if (next_arg == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    if (*next_arg == 'r') {
        isa_reg_display();
        return 0;
    }

    if (*next_arg == 'w') {
#ifdef CONFIG_WATCHPOINT
        diaplay_wp();
#endif
        return 0;
    }

    else {
        printf("Error parameter\n");
        return 0;
    }
    
    return 0;
}

// 实现内存扫描
static int cmd_x(char *args) {
    char *N = strtok(args, " ");
    if (N == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    char *EXPR = strtok(NULL, " ");
    if (EXPR == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    int expr_result;
    sscanf(EXPR + 2, "%x", &expr_result);

    if (expr_result > PMEM_RIGHT || expr_result < PMEM_LEFT) {
        printf("Start address is out of range of memory size!\n");
        return 0;
    }

    for (int i = 0; i < atoi(N); i++) {
        printf("0x%08x:  0x%08x\n", expr_result, vaddr_read(expr_result, 4));
        expr_result += 4;
        if (expr_result > PMEM_RIGHT)
            return 0;
    }

    printf("\n");
    return 0;
}

static int cmd_w(char *args) {
#ifdef CONFIG_WATCHPOINT
    if (args == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    new_wp(args);
#else
    printf("Function \"Watchpoint\" is not enabled\n");
#endif
    return 0;
}

static int cmd_d(char *args) {
#ifdef CONFIG_WATCHPOINT
    if (args == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    int i = atoi(args);

    if (i < 0 || i > 32) {
        printf("%s is out of range from 0 to 32\n", args);
        printf(ANSI_FG_RED "^\n" ANSI_NONE);
        return 0;
    }

    free_wp(i);
#else
    printf("Function \"Watchpoint\" is not enabled\n");
#endif

    return 0;
}

char buf[100010];

static int cmd_test_expr(char *args) {

    FILE *fp = fopen("/home/hjw-arch/input.txt", "r");
    if (fp == NULL) {
        printf("Can not open the file\n");
        return 0;
    }

    int count = 0;

    while (fgets(buf, sizeof(buf), fp) != NULL) {

        char *result_str = strtok(buf, " ");
        uint32_t result = (uint32_t)atoll(result_str);
        char *expr_str = strtok(NULL, "\n");
        bool is_success = true;
        uint32_t result_test = expr(expr_str, &is_success);


        // if (result_test == result) {
        //     printf("test right\n");
        // }
        // else {
        //     printf("test error!\n");
        //     count++;
        //     printf("result:%s ", result_str);
        //     printf("result of true: %u", result);
        //     printf("  result of sdb: %u", result_test);
        //     printf("\n\nexpr:\n%s\n\n\n\n\n\n\n\n", expr_str);
        //     FILE *fp = fopen("/home/hjw-arch/output.txt", "a");
        //     if (fp == NULL) {
        //         assert(0);
        //     }
        //     fprintf(fp, "test_result: %u, sdb_result: %u\nexpr:\n%s\n\n", result, result_test, expr_str);
        //     fclose(fp);
        // }

        if (is_success)
        {
            if (result_test == result)
            {
                printf("test right\n");
            }
            else
            {
                printf("test error!\n");
                count++;
                printf("result:%s ", result_str);
                printf("result of turn: %u", result);
                printf("  result of sdb: %u", result_test);
                printf("\n\nexpr:\n%s\n\n\n\n\n\n\n\n", expr_str);
            }
        }
        else
        {
            printf("Bad expr or ZeroDivError\n");
            printf("result:%s ", result_str);
            printf("result of turn: %u", result);
            printf("  result of sdb: %u", result_test);
            printf("\n\nexpr:\n%s\n\n\n\n\n\n\n\n", expr_str);
            count++;
        }
    }

    printf("error times: %d\n", count);
    

    fclose(fp);

    return 0;
}

static int cmd_p(char *args) {
    if (args == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    uint32_t print_format = 0;
    char *expr_str = args;
    if ((*args == 'd' || *args == 'x' || *args == 'D' || *args == 'X')) {
        print_format = *args;
        strtok(NULL, " ");
        expr_str = strtok(NULL, "");
        if (expr_str == NULL) {
            printf("Missing parameter\n");
            return 0;
        }
    }

    bool is_success = true;
    uint32_t result = expr(expr_str, &is_success);

    if (is_success) {
        (print_format == 'x' || print_format == 'X') ? printf("0x%x\n", result) : printf("%d\n", result);
    }
    else {
        printf("Bad expression\n");
    }

    return 0;
}

static bool cmd_no_args(char *args) {
    if (args != NULL) {
        printf("Unknown command '%s'\n", args);
        return false;
    }

    return true;
}

static int cmd_ftrace(char *args) {
    if (!cmd_no_args(args)) return 0;
    IFDEF(CONFIG_FTRACE, display_ftrace());
    return 0;
}

static int cmd_itrace(char *args) {
    if (!cmd_no_args(args)) return 0;
    IFDEF(CONFIG_ITRACE, itrace_display());
    return 0;
}

static int cmd_mtrace(char *args) {
    if (!cmd_no_args(args)) return 0;
    IFDEF(CONFIG_MTRACE, mtrace_display());
    return 0;
}

static int cmd_dtrace(char *args) {
    if (!cmd_no_args(args)) return 0;
    IFDEF(CONFIG_DTRACE, display_dtrace());
    return 0;
}

static int cmd_etrace(char *args) {
    if (!cmd_no_args(args)) return 0;
    IFDEF(CONFIG_ETRACE, display_etrace());
    return 0;
}

static int cmd_help(char *args);

static struct {
    const char *name;
    const char *description;
    int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit NEMU", cmd_q},
    {"si", "si [N] | Let the program step through N instructions, the default N is 1", cmd_si},
    {"info", "info r/w | Print registers/watchpoints status", cmd_info},
    {"x", "x N EXPR | Evaluate the expression EXPR and use the result as the starting memory, output N consecutive 4 bytes in hexadecimal form", cmd_x},
    {"p", "p [d/x] EXPR | Evaluate the expression EXPR", cmd_p},
    {"w", "w EXPR | When the value of the expression EXPR changes, program execution is stopped", cmd_w},
    {"d", "d NO | Delete a watchpoint with serial number N", cmd_d},
    {"itrace", "View instruction trace", cmd_itrace},
    {"ftrace", "View function trace", cmd_ftrace},
    {"mtrace", "View memory trace", cmd_mtrace},
    {"dtrace", "View device trace", cmd_dtrace},
    {"etrace", "View exception trace", cmd_etrace},
    {"test_expr", "test expr", cmd_test_expr},
    /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
    /* extract the first argument */
    char *arg = strtok(NULL, " ");
    int i;

    if (arg == NULL) {
        /* no argument given */
        for (i = 0; i < NR_CMD; i++)
        {
            printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        }
    } else {
        for (i = 0; i < NR_CMD; i++) {
            if (strcmp(arg, cmd_table[i].name) == 0) {
                printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
                return 0;
            }
        }
        printf("Unknown command '%s'\n", arg);
    }
    return 0;
}

void sdb_set_batch_mode() {
    is_batch_mode = true;
}

void sdb_mainloop() {
    if (is_batch_mode) {
        cmd_c(NULL);
        trace_finish();
        return;
    }

    for (char *str; (str = rl_gets()) != NULL;) {
        char *str_end = str + strlen(str);

        /* extract the first token as the command */
        char *cmd = strtok(str, " ");
        if (cmd == NULL) {
            continue;
        }

        /* treat the remaining string as the arguments,
         * which may need further parsing
         */
        char *args = cmd + strlen(cmd) + 1;
        if (args >= str_end) {
            args = NULL;
        }

#ifdef CONFIG_DEVICE
        extern void sdl_clear_event_queue();
        sdl_clear_event_queue();
#endif

        int i;
        for (i = 0; i < NR_CMD; i++) {
            if (strcmp(cmd, cmd_table[i].name) == 0) {
                if (cmd_table[i].handler(args) < 0) {
                    return;
                }
                break;
            }
        }

        if (i == NR_CMD) {
            printf("Unknown command '%s'\n", cmd);
        }
    }

    trace_finish();
}

void init_sdb()
{
    /* Compile the regular expressions. */
    init_regex();

    /* Initialize the watchpoint pool. */
    init_wp_pool();

    /* decode elf file. */
#if defined(CONFIG_FTRACE) || defined(CONFIG_MTRACE2FILE) || defined(CONFIG_BTRACE)
    decode_elf();

#if defined(CONFIG_MTRACE2FILE) || defined(CONFIG_BTRACE)
      get_main_addr();
#endif

#endif
}
