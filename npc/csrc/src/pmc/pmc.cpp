#include "sdb.h"
#include "common.h"
#include "cpu_exec.h"
#include "log.h"
#include "common.h"
#include "device.h"
#include "VysyxSoCFull___024root.h"
#include "VysyxSoCFull.h"
#include "VysyxSoCFull__Dpi.h"


#define BIT_MASK(bits)			((1ull << bits) - 1)
#define GET_BITS(a, hi, lo)		((a & BIT_MASK(hi + 1)) >> lo)

#define TYPE_INST_CAL(inst)		GET_BITS(inst, 6, 2) == 4 || GET_BITS(inst, 6, 2) == 5 || GET_BITS(inst, 6, 2) == 0xD || GET_BITS(inst, 6, 2) == 4 || GET_BITS(inst, 6, 2) == 0xC
#define TYPE_INST_JMP(inst)		GET_BITS(inst, 6, 2) == 0x1B || GET_BITS(inst, 6, 2) == 0x19 || GET_BITS(inst, 6, 2) == 0x18
#define TYPE_INST_LS(inst)		GET_BITS(inst, 6, 2) == 0 || GET_BITS(inst, 6, 2) == 8
#define TYPE_INST_CSR(inst)		GET_BITS(inst, 6, 2) == 0x1C

// 标志位
bool finish_bootloader = false;


// IFU
uint64_t ifu_fetch_inst_flash = 0;
uint64_t ifu_fetch_inst_sdram = 0;

uint64_t ifu_fetch_inst_cycles_flash = 0;
uint64_t ifu_fetch_inst_cycles_sdram = 0;

uint64_t inst_type_cal_cycles_flash = 0;
uint64_t inst_type_cal_cycles_sdram = 0;

uint64_t inst_type_ls_cycles_flash = 0;
uint64_t inst_type_ls_cycles_sdram = 0;

uint64_t inst_type_jmp_cycles_flash = 0;
uint64_t inst_type_jmp_cycles_sdram = 0;

uint64_t inst_type_csr_cycles_flash = 0;
uint64_t inst_type_csr_cycles_sdram = 0;

uint64_t inst_type_unknown_cycles_flash = 0;
uint64_t inst_type_unknown_cycles_sdram = 0;


// LSU
uint64_t lsu_load_data_flash = 0;
uint64_t lsu_load_data_sdram = 0;

uint64_t lsu_store_data_flash = 0;
uint64_t lsu_store_data_sdram = 0;

uint64_t lsu_load_data_cycles_flash = 0;
uint64_t lsu_load_data_cycles_sdram = 0;

uint64_t lsu_store_data_cycles_flash = 0;
uint64_t lsu_store_data_cycles_sdram = 0;

// EXU
uint64_t exu_finish_cal_flash = 0;
uint64_t exu_finish_cal_sdram = 0;

// IDU
uint64_t idu_identify_cal_flash = 0;
uint64_t idu_identify_ls_flash  = 0;
uint64_t idu_identify_jmp_flash = 0;
uint64_t idu_identify_csr_flash = 0;
uint64_t idu_identify_unknown_flash = 0;

uint64_t idu_identify_cal_sdram = 0;
uint64_t idu_identify_ls_sdram  = 0;
uint64_t idu_identify_jmp_sdram = 0;
uint64_t idu_identify_csr_sdram = 0;
uint64_t idu_identify_unknown_sdram = 0;

void is_finish_bootloader(int pc) {
	if (pc >= 0xa0000000) finish_bootloader = true;
}

void PerformanceCounter_ifu_fetch() {
	if (finish_bootloader) {
		ifu_fetch_inst_sdram++;
	} else {
		ifu_fetch_inst_flash++;
	}
}

static int temp_cnt_ifu_fetch_cycles = 0;
void PerformanceCounter_ifu_fetch_cycles(int start, int finish) {
	if(start) temp_cnt_ifu_fetch_cycles = 0;
	temp_cnt_ifu_fetch_cycles++;
	if (finish_bootloader) {
		if (finish) ifu_fetch_inst_cycles_sdram += temp_cnt_ifu_fetch_cycles;
	} else {
		if (finish) ifu_fetch_inst_cycles_flash += temp_cnt_ifu_fetch_cycles;
	}
}


// 对流水线处理器这种方式不适用
static int temp_cnt_inst_type_cycles = 0;
void PerformanceCounter_inst_type_total_cycles(int start, int inst) {
	if (start) {
		if (finish_bootloader) {
			if (TYPE_INST_CAL(inst)) {
				inst_type_cal_cycles_sdram += temp_cnt_inst_type_cycles;
			} else if (TYPE_INST_LS(inst)) {
				inst_type_jmp_cycles_sdram += temp_cnt_inst_type_cycles;
			} else if (TYPE_INST_JMP(inst)) {
				inst_type_jmp_cycles_sdram += temp_cnt_inst_type_cycles;
			} else if (TYPE_INST_CSR(inst)) {
				inst_type_csr_cycles_sdram += temp_cnt_inst_type_cycles;
			} else {
				inst_type_unknown_cycles_sdram += temp_cnt_inst_type_cycles;
			}
		} else {
			if (TYPE_INST_CAL(inst)) {
				inst_type_cal_cycles_flash += temp_cnt_inst_type_cycles;
			} else if (TYPE_INST_LS(inst)) {
				inst_type_jmp_cycles_flash += temp_cnt_inst_type_cycles;
			} else if (TYPE_INST_JMP(inst)) {
				inst_type_jmp_cycles_flash += temp_cnt_inst_type_cycles;
			} else if (TYPE_INST_CSR(inst)) {
				inst_type_csr_cycles_flash += temp_cnt_inst_type_cycles;
			} else {
				inst_type_unknown_cycles_flash += temp_cnt_inst_type_cycles;
			}
		}
		temp_cnt_inst_type_cycles = 0;
	}
	temp_cnt_inst_type_cycles++;
}


void PerformanceCounter_lsu_load() {
	if (finish_bootloader) {
		lsu_load_data_sdram++;
	} else {
		lsu_load_data_flash++;
	}
	
}

static int temp_cnt_lsu_load_cycles = 0;
void PerformanceCounter_lsu_load_cycles(int start, int finish) {
	if(start) temp_cnt_lsu_load_cycles = 0;
	temp_cnt_lsu_load_cycles++;

	if (finish) {
		if (finish_bootloader) {
			lsu_load_data_cycles_sdram += temp_cnt_lsu_load_cycles;
		} else {
			lsu_load_data_cycles_flash += temp_cnt_lsu_load_cycles;
		}
	}
}


void PerformanceCounter_lsu_store() {
	if (finish_bootloader) {
		lsu_store_data_sdram++;
	} else {
		lsu_store_data_flash++;
	}
}

static int temp_cnt_lsu_store_cycles = 0;
void PerformanceCounter_lsu_store_cycles(int start, int finish) {
	if(start) temp_cnt_lsu_store_cycles = 0;
	temp_cnt_lsu_store_cycles++;

	if (finish) {
		if (finish_bootloader) {
			lsu_store_data_cycles_sdram += temp_cnt_lsu_store_cycles;
		} else {
			lsu_store_data_cycles_flash += temp_cnt_lsu_store_cycles;
		}
	}
}

void PerformanceCounter_exu_finish_cal() {
	if (finish_bootloader) {
		exu_finish_cal_sdram++;
	} else {
		exu_finish_cal_flash++;
	}
}


void PerformanceCounter_idu_identify_inst(int inst) {
	if (finish_bootloader) {
		if (TYPE_INST_CAL(inst)) {
			idu_identify_cal_sdram++;
			return;
		} else if (TYPE_INST_JMP(inst)) {
			idu_identify_jmp_sdram++;
			return;
		} else if (TYPE_INST_LS(inst)) {
			idu_identify_ls_sdram++;
			return;
		} else if (TYPE_INST_CSR(inst)) {
			idu_identify_csr_sdram++;
			return;
		} else {
			idu_identify_unknown_sdram++;
			return;
		}
	} else {
		if (TYPE_INST_CAL(inst)) {
			idu_identify_cal_flash++;
			return;
		} else if (TYPE_INST_JMP(inst)) {
			idu_identify_jmp_flash++;
			return;
		} else if (TYPE_INST_LS(inst)) {
			idu_identify_ls_flash++;
			return;
		} else if (TYPE_INST_CSR(inst)) {
			idu_identify_csr_flash++;
			return;
		} else {
			idu_identify_unknown_flash++;
			return;
		}
	}
}


void PerformanceCounter_display() {
    printf(ANSI_FG_YELLOW"===== CPU Performance Counter Statistics =====\n"ANSI_NONE);

    // IFU Statistics
    printf(ANSI_FG_CYAN"\n[IFU - Instruction Fetch Unit]\n"ANSI_NONE);
    printf("Bootloader (Flash):\n");
    printf("  Instruction Fetch Count:        %ld\n", ifu_fetch_inst_flash);
    printf("  Instruction Fetch Cycles:       %ld\n", ifu_fetch_inst_cycles_flash);
    printf("Normal (SDRAM):\n");
    printf("  Instruction Fetch Count:        %ld\n", ifu_fetch_inst_sdram);
    printf("  Instruction Fetch Cycles:       %ld\n", ifu_fetch_inst_cycles_sdram);

    // IDU Statistics
    printf(ANSI_FG_CYAN"\n[IDU - Instruction Decode Unit]\n"ANSI_NONE);
    printf("Bootloader (Flash):\n");
    printf("  CAL Instructions:               %ld\n", idu_identify_cal_flash);
    printf("  CAL Instruction Cycles:         %ld\n", inst_type_cal_cycles_flash);
    printf("  LS Instructions:                %ld\n", idu_identify_ls_flash);
    printf("  LS Instruction Cycles:          %ld\n", inst_type_ls_cycles_flash);
    printf("  JMP Instructions:               %ld\n", idu_identify_jmp_flash);
    printf("  JMP Instruction Cycles:         %ld\n", inst_type_jmp_cycles_flash);
    printf("  CSR Instructions:               %ld\n", idu_identify_csr_flash);
    printf("  CSR Instruction Cycles:         %ld\n", inst_type_csr_cycles_flash);
    printf("  Unknown Instructions:           %ld\n", idu_identify_unknown_flash);
    printf("  Unknown Instruction Cycles:     %ld\n", inst_type_unknown_cycles_flash);
    printf("Normal (SDRAM):\n");
    printf("  CAL Instructions:               %ld\n", idu_identify_cal_sdram);
    printf("  CAL Instruction Cycles:         %ld\n", inst_type_cal_cycles_sdram);
    printf("  LS Instructions:                %ld\n", idu_identify_ls_sdram);
    printf("  LS Instruction Cycles:          %ld\n", inst_type_ls_cycles_sdram);
    printf("  JMP Instructions:               %ld\n", idu_identify_jmp_sdram);
    printf("  JMP Instruction Cycles:         %ld\n", inst_type_jmp_cycles_sdram);
    printf("  CSR Instructions:               %ld\n", idu_identify_csr_sdram);
    printf("  CSR Instruction Cycles:         %ld\n", inst_type_csr_cycles_sdram);
    printf("  Unknown Instructions:           %ld\n", idu_identify_unknown_sdram);
    printf("  Unknown Instruction Cycles:     %ld\n", inst_type_unknown_cycles_sdram);

    // LSU Statistics
    printf(ANSI_FG_CYAN"\n[LSU - Load/Store Unit]\n"ANSI_NONE);
    printf("Bootloader (Flash):\n");
    printf("  Load Operations:                %ld\n", lsu_load_data_flash);
    printf("  Load Cycles:                    %ld\n", lsu_load_data_cycles_flash);
    printf("  Store Operations:               %ld\n", lsu_store_data_flash);
    printf("  Store Cycles:                   %ld\n", lsu_store_data_cycles_flash);
    printf("Normal (SDRAM):\n");
    printf("  Load Operations:                %ld\n", lsu_load_data_sdram);
    printf("  Load Cycles:                    %ld\n", lsu_load_data_cycles_sdram);
    printf("  Store Operations:               %ld\n", lsu_store_data_sdram);
    printf("  Store Cycles:                   %ld\n", lsu_store_data_cycles_sdram);

    // EXU Statistics
    printf(ANSI_FG_CYAN"\n[EXU - Execution Unit]\n"ANSI_NONE);
    printf("Bootloader (Flash):\n");
    printf("  CAL Instructions Executed:      %ld\n", exu_finish_cal_flash);
    printf("Normal (SDRAM):\n");
    printf("  CAL Instructions Executed:      %ld\n", exu_finish_cal_sdram);

    printf(ANSI_FG_YELLOW"\n===== End of Statistics =====\n"ANSI_NONE);
}