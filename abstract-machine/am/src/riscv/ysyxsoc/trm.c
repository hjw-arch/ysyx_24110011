#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <riscv.h>

extern char _heap_start, _heap_end;
int main(const char *args);

Area heap = RANGE(&_heap_start, &_heap_end);

#ifndef MAINARGS
#define MAINARGS ""
#endif

static const char mainargs[] = MAINARGS;

#define SERIAL_PORT 0x10000000
void putch(char ch) {
	outb(SERIAL_PORT, ch);
}

void halt(int code) {
	asm volatile("ebreak");
	while (1);
}

// extern uint8_t _data_vma_start[];
// extern uint8_t _data_lma_start[];
// extern uint32_t _data_size;

// extern uint8_t _bss_start[];
// extern uint32_t _bss_size;

// void bootloader(void) {
// 	uint8_t *src = _data_lma_start;
//     uint8_t *dst = _data_vma_start;
//     for (uint32_t i = 0; i < _data_size; i++) {
//         dst[i] = src[i];
//     }
    
//     // 清零.bss段
//     dst = _bss_start;
//     for (uint32_t i = 0; i < _bss_size; i++) {
//         dst[i] = 0;
//     }
// }

void _trm_init() {
	// bootloader();
	int ret = main(mainargs);
	halt(ret);
}
