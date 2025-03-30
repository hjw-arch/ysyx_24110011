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


void bootloader(void) {
    
}

void _trm_init() {
	bootloader();
	int ret = main(mainargs);
	halt(ret);
}
