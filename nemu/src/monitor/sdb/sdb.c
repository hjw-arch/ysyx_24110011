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

#ifdef CONFIG_ITRACE

#ifdef CONFIG_ITRACE2FILE

static FILE *itrace_output_file_fp = NULL;
static char *itrace_file = "/home/hjw-arch/ysyx-workbench/ITRACE.bin";

void open_itrace_file() {
    if (itrace_output_file_fp) {
        return;
    }

    itrace_output_file_fp = fopen(itrace_file, "wb");
    Assert(itrace_output_file_fp, "Open itrace file failed.");
}

void close_itrace_file() {
    if (itrace_output_file_fp) {
        if (fclose(itrace_output_file_fp) == EOF) {
            Assert(0, "Close itrace output file failed.");
        }

        itrace_output_file_fp = NULL;
    }
}

void write2itrace(vaddr_t addr) {
    if (itrace_output_file_fp) {
        size_t items_written = fwrite(&addr, sizeof(vaddr_t), 1, itrace_output_file_fp);
        if (items_written != 1) {
            // 错误处理：可以打印错误，或者设置一个标志位，或者终止模拟
            // 为简单起见，这里只打印错误。在实际模拟器中可能需要更健壮的处理。
            fprintf(stderr, "Serious error: Failed to write the address to the trace file!\n");
            if (ferror(itrace_output_file_fp)) {
                perror("           文件写入错误详情");
            }
            // 考虑是否要关闭文件并停止追踪，或者忽略这个错误继续？
            fclose(itrace_output_file_fp);
            itrace_output_file_fp = NULL; // 避免后续尝试写入
        }
    }
}

#endif

#define BUFFER_SIZE     16
// ringbuffer
typedef struct _ringbuf
{
    MUXDEF(CONFIG_RV64, uint64_t addr, uint32_t addr);
    uint32_t inst;
}ringbuf;
static ringbuf iringbuf[BUFFER_SIZE];
static uint32_t iringbuf_index = 0;

void iringbuf_load(MUXDEF(CONFIG_RV64, uint64_t addr, uint32_t addr), uint32_t inst) {
    iringbuf[iringbuf_index].addr = addr;
    iringbuf[iringbuf_index++].inst = inst;
    if (iringbuf_index > BUFFER_SIZE - 1) iringbuf_index = 0;
	IFDEF(CONFIG_ITRACE2FILE, open_itrace_file());
	IFDEF(CONFIG_ITRACE2FILE, write2itrace(addr));
}

void iringbuf_display() {
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

	IFDEF(CONFIG_ITRACE2FILE, close_itrace_file())
}

#endif

#ifdef CONFIG_MTRACE
void mtrace_read(uint32_t addr, uint32_t len, uint32_t content, uint32_t is_record_fetch_pc) {
    if (addr < CONFIG_MTRACE_START_ADDR || addr > CONFIG_MTRACE_END_ADDR) return;
    if (!is_record_fetch_pc && cpu.pc == addr) return;
    printf("Guest machine read memory at pc = 0x%08x, addr = 0x%08x, %d byte%s content = 0x%08x\n", cpu.pc, addr, len, len > 1 ? "s," : ", ", content);
}

void mtrace_write(uint32_t addr, uint32_t len, uint32_t content, uint32_t is_record_fetch_pc) {
    if (addr < CONFIG_MTRACE_START_ADDR || addr > CONFIG_MTRACE_END_ADDR) return;
    printf("Guest machine write memory at pc = 0x%08x, addr = 0x%08x, %d byte%s content = 0x%08x\n", cpu.pc, addr, len, len > 1 ? "s," : ", ", content);
}
#endif

//  ftrace
#ifdef CONFIG_FTRACE
#include <elf.h>
extern char *elf_file;

typedef struct _symtab{
    char name[64];
    uint32_t start_addr;
    uint32_t end_addr;
}symtab;

static symtab symtabs[1024];
static uint32_t symtab_count = 0;

void decode_elf() {
    if (elf_file == NULL) {
        Log("No elf file is given, ftrace function is not allowed to use.");
        return;
    }

    FILE *fp = fopen(elf_file, "rb");
    Assert(fp, "Can not open '%s'", elf_file);

    rewind(fp);

    Elf32_Ehdr ehdr;

    int ret = fread(&ehdr, sizeof(Elf32_Ehdr), 1, fp);
    assert(ret == 1);

    if (ehdr.e_ident[EI_MAG0] != ELFMAG0 || ehdr.e_ident[EI_MAG1] != ELFMAG1 || ehdr.e_ident[EI_MAG2] != ELFMAG2 || ehdr.e_ident[EI_MAG3] != ELFMAG3) {
        Assert(0, "Invalid ELF file.");
    }

    if (ehdr.e_ident[EI_CLASS] != ELFCLASS32) {
        Assert(0, "Invalid ELF class, only 'ELF32' is supported now.");
    }

    if (ehdr.e_ident[ET_NUM] != ET_REL) {
        Assert(0, "Invalid ELF type, only 'ET_REL' is supported now.");
    }

    Elf32_Sym sym;
    Elf32_Shdr shdr;
    char *str_buffer = NULL;

    fseek(fp, (long)ehdr.e_shoff, SEEK_SET);

    for (int i = 0; i < ehdr.e_shnum; i++) {
        if (i == ehdr.e_shstrndx) continue;
        ret = fread(&shdr, sizeof(Elf32_Shdr), 1, fp);
        assert(ret == 1);
        if (shdr.sh_type == SHT_STRTAB) {
            str_buffer = (char *)malloc(shdr.sh_size);
            if (str_buffer == NULL) {
                Assert(0, "Malloc failed, can not use 'mtrace' function.\n");
                return;
            }
            fseek(fp, (long)shdr.sh_offset, SEEK_SET);
            ret = fread(str_buffer, shdr.sh_size, 1, fp);
            assert(ret == 1);
            break;
        }
    }

    fseek(fp, (long)ehdr.e_shoff, SEEK_SET);

    for (int i = 0; i < ehdr.e_shnum; i++) {
        if (i == ehdr.e_shstrndx) continue;
        ret = fread(&shdr, sizeof (Elf32_Shdr), 1, fp);
        assert(ret == 1);
        if (shdr.sh_type == SHT_SYMTAB) {
            fseek(fp, (long)shdr.sh_offset, SEEK_SET);
            for (int j = 0; j < shdr.sh_size / sizeof (Elf32_Sym); j++) {
                ret = fread(&sym, sizeof (Elf32_Sym), 1, fp);
                assert(ret == 1);
                if(ELF32_ST_TYPE(sym.st_info) == STT_FUNC) {
                    symtabs[symtab_count].start_addr = sym.st_value;
                    symtabs[symtab_count].end_addr = sym.st_value + sym.st_size;
                    strcpy(symtabs[symtab_count].name, (char *)(str_buffer + sym.st_name));
                    symtab_count++;
                }
            }
            break;
        }
    }

    free(str_buffer);
    fclose(fp);
}

typedef struct _ftrace{
    uint32_t pc_now;
    uint32_t action;        // 0: call;  1: ret
    uint32_t pc_target;
}ftrace;

static ftrace fring_ftrace[64];
static uint32_t fring_index = 0;

void record_ftrace(uint32_t pc_now, uint32_t action, uint32_t pc_target) {
    if (elf_file == NULL) return;
    if (!action) {
        uint32_t flag = 0;
        for (int j = 0; j < symtab_count; j++) {
            if (symtabs[j].start_addr == pc_target) {
                flag = 1;
                break;
            }
        }
        if (!flag) return;
    }
    if (fring_index >= 64) fring_index = 0;
    fring_ftrace[fring_index].pc_now = pc_now;
    fring_ftrace[fring_index].action = action;
    fring_ftrace[fring_index++].pc_target = pc_target;
}

void display_ftrace() {
    if (elf_file == NULL) return;
    uint32_t blank_num = 0;
    uint32_t start_index = fring_index;
    uint32_t end_index = fring_index == 0 ? 63 : fring_index - 1;
    uint32_t index = start_index;
    while(1) {
        if (index >= 64) index = 0;

        if (fring_ftrace[index].pc_now == 0) {
            if (index == end_index) break;
            index++;
            continue;
        }

        char *func_name;
        for (int j = 0; j < symtab_count; j++) {
            if (symtabs[j].start_addr <= fring_ftrace[index].pc_target && symtabs[j].end_addr > fring_ftrace[index].pc_target) {
                func_name = (char *)&symtabs[j].name;
                break;
            }
        }

        if (!fring_ftrace[index].action) {
            printf("0x%08x: %*s%s [%s@0x%08x]\n", fring_ftrace[index].pc_now, blank_num, "", "call", func_name, fring_ftrace[index].pc_target);
            blank_num += 2;
        }
        else {
            blank_num -= 2;
            if (blank_num < 0) blank_num = 0;
            printf("0x%08x: %*s%s [%s@0x%08x]\n", fring_ftrace[index].pc_now, blank_num, "", "ret", func_name, fring_ftrace[index].pc_target);
        }

        

        index++;
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

static int cmd_c(char *args) {
    cpu_exec(-1);
    return 0;
}

static int cmd_q(char *args) {
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

static int cmd_ftrace(char *args) {
    if (args != NULL) {
        printf("Unknown command '%s'\n", args);
        return 0;
    }

    IFDEF(CONFIG_FTRACE, display_ftrace());

    return 0;
}

static int cmd_dtrace(char *args) {
    if (args != NULL) {
        printf("Unknown command '%s'\n", args);
        return 0;
    }

    IFDEF(CONFIG_DTRACE, display_dtrace());

    return 0;
}

static int cmd_etrace(char *args) {
    if (args != NULL) {
        printf("Unknown command '%s'\n", args);
        return 0;
    }

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
    {"ftrace", "View function trace", cmd_ftrace},
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
}

void init_sdb()
{
    /* Compile the regular expressions. */
    init_regex();

    /* Initialize the watchpoint pool. */
    init_wp_pool();

    /* decode elf file. */
    IFDEF(CONFIG_FTRACE, decode_elf());
}
