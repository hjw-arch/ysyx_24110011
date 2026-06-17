#ifndef PMC_H
#define PMC_H

#include <stdbool.h>
#include <stdint.h>

void PerformanceCounter_display();
void PerformanceCounter_export_json();
void PerformanceCounter_record_cycle();
void PerformanceCounter_record_lsu_redirect();
void PerformanceCounter_record_wbu_redirect();
void PerformanceCounter_record_commit(uint32_t pc, uint32_t inst, uint64_t retire_cycles);

#endif
