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

#define UART_BASE 	0x10000000
#define UART_TX		*(volatile uint8_t *)(UART_BASE + 0x00)
#define UART_RX		*(volatile uint8_t *)(UART_BASE + 0x00)
#define UART_IER	*(volatile uint8_t *)(UART_BASE + 0x01)
#define UART_IIR	*(volatile uint8_t *)(UART_BASE + 0x02)
#define UART_FCR	*(volatile uint8_t *)(UART_BASE + 0x02)
#define UART_LCR	*(volatile uint8_t *)(UART_BASE + 0x03)
#define UART_MC		*(volatile uint8_t *)(UART_BASE + 0x04)
#define	UART_LSR	*(volatile uint8_t *)(UART_BASE + 0x05)
#define UART_MS		*(volatile uint8_t *)(UART_BASE + 0x06)

#define UART_LSB	*(volatile uint8_t *)(UART_BASE + 0x00)
#define UART_MSB	*(volatile uint8_t *)(UART_BASE + 0x01)

#define UART_FIFO_EMPTY_MASK	1 << 5
#define UART_DATA_READY			1 << 0

void uart_init() {
	UART_LCR = 0x83;	// 0b10000011
	// UART_MSB = 0x00;
	UART_LSB = 0x01;
	UART_LCR = 0x03;
}

void print_id() {
	uint32_t mvendorid, marchid;
	asm volatile("csrr %0, mvendorid" : "=r"(mvendorid));
	asm volatile("csrr %0, marchid" : "=r"(marchid));
	printf("%c%c%c%c_%d\n", (char)(mvendorid >> 24), (char)(mvendorid >> 16), (char)(mvendorid >> 8), (char)(mvendorid), marchid);
}

void putch(char ch) {
	while((UART_LSR & UART_FIFO_EMPTY_MASK) == 0);	// 等待
	UART_TX = ch;
}

void halt(int code) {
	asm volatile("ebreak");
	while (1);
}

void _trm_init() {
	uart_init();
	print_id();
	int ret = main(mainargs);
	halt(ret);
}
