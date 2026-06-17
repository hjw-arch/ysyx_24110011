#include "../Include/sdb.h"
#include "../Include/log.h"
#include "../Include/macro.h"
#include <stdio.h>
#include "stdint.h"

#ifdef SOC

#include "VysyxSoCFull___024root.h"

#else

#include "Vysyx___024root.h"

#endif

// ringbuffer
typedef struct _ringbuf {
    MUXDEF(CONFIG_RV64, uint64_t addr[16], uint32_t addr[16]);
    uint32_t inst[16];
}ringbuf;

static ringbuf iringbuf;
static uint32_t iringbuf_index = 0;

void iringbuf_load(MUXDEF(CONFIG_RV64, uint64_t addr, uint32_t addr), uint32_t inst) {
    if (iringbuf_index > 15) iringbuf_index = 0;
    iringbuf.addr[iringbuf_index] = addr;
    iringbuf.inst[iringbuf_index++] = inst;
}

void iringbuf_display() {
    uint32_t start_index = iringbuf_index;
    uint32_t end_index = iringbuf_index - 1;
    uint32_t index = start_index;
    puts("\n");
    puts("Instruction ring log:");
    while(1) {
        if (index > 15) index = 0;
        if (iringbuf.addr[index] == 0) {
            index++;
            continue;
        }


        printf("0x%08x: ", iringbuf.addr[index]);

        printf("%02x ", (iringbuf.inst[index] & 0xff000000) >> 24);
        printf("%02x ", (iringbuf.inst[index] & 0x00ff0000) >> 16);
        printf("%02x ", (iringbuf.inst[index] & 0x0000ff00) >> 8);
        printf("%02x       ",  (uint8_t)iringbuf.inst[index]);

        char disasm_buf[64];
        void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
        disassemble(disasm_buf, 64, iringbuf.addr[index], (uint8_t *)&iringbuf.inst[index], 4);
        printf("%s\n", disasm_buf);
        
        if(index == end_index) break;
        index++;
    }
    puts("\n");
}

#include "cpu_exec.h"
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


#ifdef CONFIG_FTRACE
#include <elf.h>
extern char *elf_file;

typedef struct _symtab{
    char name[32];
    uint32_t start_addr;
    uint32_t end_addr;
}symtab;

static symtab symtabs[128];
static uint32_t symtab_count = 0;

void decode_elf() {
    if (elf_file == NULL) {
        Log("No elf file is given, ftrace function is not allowed to use.");
        return;
    }

    FILE *fp = fopen(elf_file, "rb");
    Assert(fp, "Can not open '%s'", elf_file);

    Log("Get elf file:%s, ftrace enabled", elf_file);

    rewind(fp);

    Elf32_Ehdr ehdr;

    int ret = fread(&ehdr, sizeof (Elf32_Ehdr), 1, fp);
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
        ret = fread(&shdr, sizeof (Elf32_Shdr), 1, fp);
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
    uint32_t end_index = fring_index - 1;
    uint32_t index = start_index;
    while(1) {
        if (index >= 64) index = 0;

        if (fring_ftrace[index].pc_now == 0) {
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

        if (index == end_index) break;

        index++;
    }
}

#endif
