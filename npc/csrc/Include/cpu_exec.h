#ifndef CPU_EXEC_H
#define CPU_EXEC_H

#include <stdint.h>
#include "ram.h"
#include "config.h"

typedef struct _cpu
{
    word_t registerFile[32];
    word_t pc;
}cpu_t;

extern cpu_t cpu;   // CPU Info

typedef enum {
    NPC_STOP,
    NPC_RUNNING,
    NPC_END,
    NPC_ABORT,
    NPC_QUIT,
} npc_exec_state_t;

typedef struct {
    npc_exec_state_t state;
    uint32_t halt_pc;
    uint32_t halt_ret;
} npc_state_t;

extern npc_state_t npc_state;

void npc_set_state(npc_exec_state_t state, uint32_t halt_pc, uint32_t halt_ret);
bool npc_is_exit_status_bad();

void cpu_exec(uint32_t n);


#endif
