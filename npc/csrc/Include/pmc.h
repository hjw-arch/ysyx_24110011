#ifndef PMC_H
#define PMC_H

#include <stdbool.h>
#include <stdint.h>

typedef struct {
	uint32_t pc;
	bool     wbu_valid;
	uint32_t wbu_pc;

	bool ifu_req_valid;
	bool ifu_req_ready;
	bool ifu_resp_valid;
	bool ifu_resp_ready;
	bool ifu_flush;

	bool icache_req_hit;
	bool icache_req_miss;
	bool icache_miss_busy;
	bool icache_drop_refill;
	bool icache_invalidate;

	bool lsu_mem_req_fire;
	bool lsu_input_is_load;
	bool lsu_input_is_store;
	bool lsu_wait_resp;

	bool hazard_valid;
	bool rs1_block_ex;
	bool rs2_block_ex;
	bool rs1_block_ls;
	bool rs2_block_ls;
	bool ex_is_load;
	bool ex_is_csr;
	bool ls_is_csr;
	bool ls_can_wb;
	bool idu_valid;
	uint8_t fwd_rs1_sel;
	uint8_t fwd_rs2_sel;
	bool rf_rs1_bypass;
	bool rf_rs2_bypass;
} pmc_cycle_sample_t;

typedef struct {
	uint32_t pc;
	uint32_t target;
	uint32_t inst;
	bool kill_if;
	bool kill_id;
	bool kill_ex;
	bool icache_miss_busy;
} pmc_lsu_redirect_sample_t;

typedef struct {
	uint32_t pc;
	uint32_t target;
	uint32_t inst;
	bool kill_if;
	bool kill_id;
	bool kill_ex;
	bool kill_ls;
	bool icache_miss_busy;
} pmc_wbu_redirect_sample_t;

void PerformanceCounter_display();
void PerformanceCounter_record_cycle(const pmc_cycle_sample_t *sample);
void PerformanceCounter_record_lsu_redirect(const pmc_lsu_redirect_sample_t *sample);
void PerformanceCounter_record_wbu_redirect(const pmc_wbu_redirect_sample_t *sample);
void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles);

#endif
