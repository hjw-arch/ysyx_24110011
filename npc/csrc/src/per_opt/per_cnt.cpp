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

uint64_t ifu_fetch_inst = 0;
uint64_t lsu_fetch_data = 0;
uint64_t lsu_store_data = 0;
uint64_t exu_finish_cal = 0;

uint64_t idu_identify_inst__cal = 0;
uint64_t idu_identify_inst__ls = 0;
uint64_t idu_identify_inst__jmp = 0;
uint64_t idu_identify_inst__csr = 0;
uint64_t idu_identify_inst__unknown = 0;

void PerformanceCounter_ifu_fetch() {
	ifu_fetch_inst++;
}


void PerformanceCounter_lsu_fetch() {
	lsu_fetch_data++;
}


void PerformanceCounter_lsu_store() {
	lsu_store_data++;
}

void PerformanceCounter_exu_finish_cal() {
	exu_finish_cal++;
}


void PerformanceCounter_idu_identify_inst(int inst) {
	if (TYPE_INST_CAL(inst)) {
		idu_identify_inst__cal++;
		return;
	} else if (TYPE_INST_JMP(inst)) {
		idu_identify_inst__ls++;
		return;
	} else if (TYPE_INST_LS(inst)) {
		idu_identify_inst__jmp++;
		return;
	} else if (TYPE_INST_CSR(inst)) {
		idu_identify_inst__csr++;
		return;
	} else {
		idu_identify_inst__unknown++;
		return;
	}
}


void PerformanceCounter_display() {
	printf(ANSI_FG_BLUE"PerformanceCounter:\n\n"ANSI_NONE);
	printf(ANSI_FG_BLUE"ifu_fetch_inst = %ld\n"ANSI_NONE, ifu_fetch_inst);
	printf(ANSI_FG_BLUE"lsu_fetch_data = %ld\n"ANSI_NONE, lsu_fetch_data);
	printf(ANSI_FG_BLUE"lsu_store_data = %ld\n"ANSI_NONE, lsu_store_data);
	printf(ANSI_FG_BLUE"exu_finish_cal = %ld\n"ANSI_NONE, exu_finish_cal);

	puts("");

	printf(ANSI_FG_BLUE"idu_identify_inst__cal = %ld\n"ANSI_NONE, idu_identify_inst__cal);
	printf(ANSI_FG_BLUE"idu_identify_inst__ls = %ld\n"ANSI_NONE, idu_identify_inst__ls);
	printf(ANSI_FG_BLUE"idu_identify_inst__jmp = %ld\n"ANSI_NONE, idu_identify_inst__jmp);
	printf(ANSI_FG_BLUE"idu_identify_inst__csr = %ld\n"ANSI_NONE, idu_identify_inst__csr);
	printf(ANSI_FG_BLUE"idu_identify_inst__unknown = %ld\n"ANSI_NONE, idu_identify_inst__unknown);
}
