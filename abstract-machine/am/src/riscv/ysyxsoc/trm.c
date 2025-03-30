#include <am.h>
#include <klib-macros.h>
#include <klib-macros.h>
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

void bootloader() {
	extern char _data_vma_start, _data_lma_start, _bss_start;
	extern char _data_size, _bss_size;
	uint8_t* data_vma_start = &_data_vma_start;
	uint8_t* data_lma_start = &_data_lma_start;
	uint8_t* bss_start = &_bss_start;
	uint32_t data_size = &_data_size;
	uint32_t bss_size = &_bss_size;

	for (int i = 0; i < data_size; i++) {
		data_vma_start[i] = data_lma_start[i];
	}

	for (int i = 0; i < bss_size; i++) {
		bss_start[i] = 0;
	}
}

void _trm_init() {

	int ret = main(mainargs);
	halt(ret);
}
