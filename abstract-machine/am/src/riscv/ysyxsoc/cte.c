#include <am.h>
#include <riscv/riscv.h>
#include <klib.h>
#include <stdio.h>

static Context *(*user_handler)(Event, Context *) = NULL;

Context *__am_irq_handle(Context *c)
{
    if (user_handler) {
        Event ev = {0};
        switch (c->mcause)
        {
        case 11:
            ev.event = EVENT_YIELD;
            break;
        default:
            ev.event = EVENT_ERROR;
            break;
        }

        c = user_handler(ev, c);
        assert(c != NULL);
    }

    return c;
}

extern void __am_asm_trap(void);

bool cte_init(Context *(*handler)(Event, Context *))
{
    // initialize exception entry
    asm volatile("csrw mtvec, %0" : : "r"(__am_asm_trap));

    // register event handler
    user_handler = handler;

    return true;
}

#define CONTEXT_SIZE  ((NR_REGS + 3) * 4)

Context *kcontext(Area kstack, void (*entry)(void *), void *arg)
{
    uint8_t *end = kstack.end;
    Context *context = (Context *)(end - CONTEXT_SIZE);

    for (int i = 0; i < NR_REGS; i++) {
        context->gpr[i] = 0;
    }

    context->gpr[2] = (uintptr_t)(end - CONTEXT_SIZE); // 栈指针
    context->gpr[10] = (uintptr_t)(arg);

    context->mepc = (uintptr_t)(entry);

    context->mstatus = 0x1800;

    *(uint32_t *)(kstack.start) = (uint32_t)context;

    return context;
}

void yield()
{
#ifdef __riscv_e
    asm volatile("li a5, -1; ecall");
#else
    asm volatile("li a7, -1; ecall");
#endif
}

bool ienabled()
{
    return false;
}

void iset(bool enable)
{
}
