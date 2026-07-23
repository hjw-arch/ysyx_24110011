#include "../Include/sdb.h"
#include "../Include/log.h"

#include <elf.h>
#include <stdio.h>
#include <stdlib.h>

enum {
	ITRACE_CAPACITY = 16,
	MTRACE_CAPACITY = 32,
	DTRACE_CAPACITY = 32,
	FTRACE_CAPACITY = 64,
	FTRACE_SYMBOL_CAPACITY = 1024,
	FTRACE_NAME_SIZE = 64,
};

typedef struct {
	word_t pc;
	uint32_t inst;
} itrace_entry_t;

static itrace_entry_t itrace_ring[ITRACE_CAPACITY] = {};
static uint32_t itrace_write_index = 0;
static uint32_t itrace_count = 0;

void iringbuf_load(word_t pc, uint32_t inst) {
	itrace_ring[itrace_write_index] = {pc, inst};
	itrace_write_index = (itrace_write_index + 1) % ITRACE_CAPACITY;
	if (itrace_count < ITRACE_CAPACITY) {
		itrace_count++;
	}
}

void iringbuf_display() {
	puts("\nInstruction ring log:");
	uint32_t index = (itrace_write_index + ITRACE_CAPACITY - itrace_count) % ITRACE_CAPACITY;

	for (uint32_t n = 0; n < itrace_count; n++) {
		const itrace_entry_t *entry = &itrace_ring[index];
		char disasm_buf[64];
		disassemble(disasm_buf, sizeof(disasm_buf), entry->pc, (uint8_t *)&entry->inst, 4);
		
		printf("0x%08x: %02x %02x %02x %02x       %s\n", (uint32_t)entry->pc,
			(entry->inst >> 24) & 0xff, (entry->inst >> 16) & 0xff,
			(entry->inst >> 8) & 0xff, entry->inst & 0xff, disasm_buf);

		index = (index + 1) % ITRACE_CAPACITY;
	}
	puts("");
}

typedef struct {
	uint32_t pc;
	uint32_t addr;
	uint32_t data;
	uint8_t len;
	bool is_load;
} mtrace_entry_t;

static mtrace_entry_t mtrace_ring[MTRACE_CAPACITY] = {};
static uint32_t mtrace_write_index = 0;
static uint32_t mtrace_count = 0;

void mtrace_record(uint32_t pc, uint8_t is_load, uint32_t addr, uint8_t len, uint32_t data) {
	if (len != 1 && len != 2 && len != 4) {
		return;
	}

	uint32_t mask = len == 4 ? UINT32_MAX : (1u << (len * 8)) - 1;
	mtrace_ring[mtrace_write_index] = {pc, addr, data & mask, len, is_load != 0};
	mtrace_write_index = (mtrace_write_index + 1) % MTRACE_CAPACITY;

	if (mtrace_count < MTRACE_CAPACITY) {
		mtrace_count++;
	}
}

void display_mtrace() {
	puts("\nMemory trace:");
	uint32_t index = (mtrace_write_index + MTRACE_CAPACITY - mtrace_count) % MTRACE_CAPACITY;

	for (uint32_t n = 0; n < mtrace_count; n++) {
		const mtrace_entry_t *entry = &mtrace_ring[index];
		printf("0x%08x: %-5s addr=0x%08x, len=%u, data=0x%08x\n",
			entry->pc, entry->is_load ? "load" : "store", entry->addr,
			entry->len, entry->data);
		index = (index + 1) % MTRACE_CAPACITY;
	}
	puts("");
}

typedef struct {
	const char *name;
	uint32_t addr;
	uint32_t data;
	uint8_t access;
	bool is_write;
} dtrace_entry_t;

static dtrace_entry_t dtrace_ring[DTRACE_CAPACITY] = {};
static uint32_t dtrace_write_index = 0;
static uint32_t dtrace_count = 0;

void record_dtrace(const char *name, uint32_t addr, uint8_t access, uint32_t data, bool is_write) {
	dtrace_ring[dtrace_write_index] = {name, addr, data, access, is_write};
	dtrace_write_index = (dtrace_write_index + 1) % DTRACE_CAPACITY;
	if (dtrace_count < DTRACE_CAPACITY) {
		dtrace_count++;
	}
}

void display_dtrace() {
	puts("\nDevice trace:");
	uint32_t index = (dtrace_write_index + DTRACE_CAPACITY - dtrace_count) % DTRACE_CAPACITY;

	for (uint32_t n = 0; n < dtrace_count; n++) {
		const dtrace_entry_t *entry = &dtrace_ring[index];
		if (entry->is_write) {
			printf("write %-8s addr=0x%08x, mask=0x%x, data=0x%08x\n",
				entry->name, entry->addr, (unsigned)entry->access, entry->data);
		} else {
			printf("read  %-8s addr=0x%08x, len=%u, data=0x%08x\n",
				entry->name, entry->addr, (unsigned)entry->access, entry->data);
		}
		index = (index + 1) % DTRACE_CAPACITY;
	}
	puts("");
}

#ifdef CONFIG_FTRACE

enum {
	FTRACE_NONE,
	FTRACE_CALL,
	FTRACE_RET,
	FTRACE_TAIL,
};

typedef struct _symtab {
	char name[FTRACE_NAME_SIZE];
	uint32_t start_addr;
	uint32_t end_addr;
} symtab;

static symtab symtabs[FTRACE_SYMBOL_CAPACITY];
static uint32_t symtab_count = 0;

typedef struct _ftrace {
	uint32_t pc_now;
	uint32_t action;
	uint32_t pc_target;
} ftrace;

static ftrace fring_ftrace[FTRACE_CAPACITY] = {};
static uint32_t fring_index = 0;
static uint32_t fring_count = 0;
static ftrace pending_ftrace = {};
static bool ftrace_pending = false;

extern char *elf_file;

static const symtab *find_func(uint32_t addr) {
	for (uint32_t i = 0; i < symtab_count; i++) {
		const symtab *symbol = &symtabs[i];
		if (symbol->start_addr <= addr && addr < symbol->end_addr) {
			return symbol;
		}
	}
	return NULL;
}

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

	fseek(fp, (long)ehdr.e_shoff, SEEK_SET);
	for (uint32_t i = 0; i < ehdr.e_shnum; i++) {
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

	fseek(fp, (long)(ehdr.e_shoff + symtab_shdr.sh_link * sizeof(shdr)), SEEK_SET);
	ret = fread(&strtab_shdr, sizeof(Elf32_Shdr), 1, fp);
	assert(ret == 1);
	Assert(strtab_shdr.sh_type == SHT_STRTAB, "Invalid ELF symbol string table.");

	char *strtab = (char *)malloc(strtab_shdr.sh_size);
	Assert(strtab, "Malloc failed, can not decode ELF string table.");
	fseek(fp, (long)strtab_shdr.sh_offset, SEEK_SET);
	ret = fread(strtab, strtab_shdr.sh_size, 1, fp);
	assert(ret == 1);

	fseek(fp, (long)symtab_shdr.sh_offset, SEEK_SET);
	uint32_t symbol_num = symtab_shdr.sh_size / sizeof(Elf32_Sym);
	for (uint32_t i = 0; i < symbol_num; i++) {
		Elf32_Sym symbol;
		ret = fread(&symbol, sizeof(Elf32_Sym), 1, fp);
		assert(ret == 1);

		if (ELF32_ST_TYPE(symbol.st_info) != STT_FUNC) continue;
		if (symbol.st_name >= strtab_shdr.sh_size) continue;
		if (symtab_count == FTRACE_SYMBOL_CAPACITY) {
			break;
		}

		symtab *entry = &symtabs[symtab_count++];
		entry->start_addr = symbol.st_value;
		entry->end_addr = symbol.st_value + symbol.st_size;
		snprintf(entry->name, sizeof(entry->name), "%s", strtab + symbol.st_name);
	}

	free(strtab);
	fclose(fp);
	Log("FTrace: loaded %u function symbol(s) from %s", symtab_count, elf_file);
}


// | 指令形式 | 判断 |
// |---|---|
// | `jal x1, target` | CALL |
// | `jal x5, target` | CALL |
// | `jal x0, target`，跳到其他函数 | TAIL |
// | `jal x0, target`，跳到当前函数内部 | 忽略 |
// | `jalr x1, imm(rs1)` | CALL |
// | `jalr x5, imm(rs1)` | CALL |
// | `jalr x0, 0(x1)` | RET |
// | `jalr x0, 0(x5)` | RET |
// | `jalr x0, imm(rs1)`，不符合 RET | TAIL |
// | 其他 `jalr` | 不记录 |

static bool is_link_reg(uint32_t reg) {
	return reg == 1 || reg == 5;
}

static int classify_ftrace_action(uint32_t inst) {
	uint32_t opcode = inst & 0x7f;
	uint32_t rd = (inst >> 7) & 0x1f;

	if (opcode == 0x6f) {		// jal | call | tail call
		return is_link_reg(rd) ? FTRACE_CALL : (rd == 0 ? FTRACE_TAIL : FTRACE_NONE);
	}

	if (opcode != 0x67 || ((inst >> 12) & 0x7) != 0) {
		return FTRACE_NONE;
	}

	// jalr
	uint32_t rs1 = (inst >> 15) & 0x1f;
	uint32_t imm = inst >> 20;
	if (is_link_reg(rd)) {
		return FTRACE_CALL;
	}
	if (rd == 0 && is_link_reg(rs1) && imm == 0) {
		return FTRACE_RET;
	}
	return rd == 0 ? FTRACE_TAIL : FTRACE_NONE;
}

static void append_ftrace(uint32_t target) {
	pending_ftrace.pc_target = target;
	if (pending_ftrace.action == FTRACE_TAIL) {
		const symtab *from = find_func(pending_ftrace.pc_now);
		const symtab *to = find_func(target);
		if (to == NULL || to == from) {
			return;
		}
	}

	fring_ftrace[fring_index] = pending_ftrace;
	fring_index = (fring_index + 1) % FTRACE_CAPACITY;
	if (fring_count < FTRACE_CAPACITY) {
		fring_count++;
	}
}

void ftrace_record(uint32_t pc, uint32_t inst) {
	if (elf_file == NULL) {
		return;
	}

	if (ftrace_pending) {
		append_ftrace(pc);
		ftrace_pending = false;
	}

	int action = classify_ftrace_action(inst);
	if (action == FTRACE_NONE) {
		return;
	}

	pending_ftrace = {pc, (uint32_t)action, 0};
	ftrace_pending = true;
}

void display_ftrace() {
	if (elf_file == NULL) {
		return;
	}

	uint32_t index = (fring_index + FTRACE_CAPACITY - fring_count) % FTRACE_CAPACITY;
	int indent = 0;
	for (uint32_t n = 0; n < fring_count; n++) {
		const ftrace *entry = &fring_ftrace[index];
		const symtab *func = find_func(entry->action == FTRACE_RET ? entry->pc_now : entry->pc_target);
		const char *name = func ? func->name : "???";

		if (entry->action == FTRACE_CALL) {
			printf("0x%08x: %*scall [%s@0x%08x]\n", entry->pc_now, indent, "", name, entry->pc_target);
			indent += 2;
		} else if (entry->action == FTRACE_RET) {
			if (indent >= 2) {
				indent -= 2;
			}
			printf("0x%08x: %*sret  [%s]\n", entry->pc_now, indent, "", name);
		} else {
			printf("0x%08x: %*stail [%s@0x%08x]\n", entry->pc_now, indent, "", name, entry->pc_target);
		}
		index = (index + 1) % FTRACE_CAPACITY;
	}
}

#endif
