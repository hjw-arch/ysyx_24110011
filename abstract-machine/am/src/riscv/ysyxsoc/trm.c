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
#define UART_TX		(UART_BASE + 0x00)
#define UART_RX		(UART_BASE + 0x00)
#define UART_IER	(UART_BASE + 0x01)
#define UART_IIR	(UART_BASE + 0x02)
#define UART_FCR	(UART_BASE + 0x02)
#define UART_LCR	(UART_BASE + 0x03)
#define UART_MC		(UART_BASE + 0x04)
#define	UART_LSR	(UART_BASE + 0x05)
#define UART_MS		(UART_BASE + 0x06)

#define UART_LSB	(UART_BASE + 0x00)
#define UART_MSB	(UART_BASE + 0x01)

#define UART_FIFO_EMPTY_MASK	0x20

void uart_init() {
	*(volatile uint8_t *)UART_LCR = 0x83;	// 0b10000011
	*(volatile uint8_t *)UART_MSB = 0x00;
	*(volatile uint8_t *)UART_LSB = 0x01;
	*(volatile uint8_t *)UART_LCR = 0x03;
}

void putch(char ch) {
	while((*(volatile uint8_t *)UART_LSR & UART_FIFO_EMPTY_MASK) == 0);	// 等待
	outb(UART_TX, ch);
}

void halt(int code) {
	asm volatile("ebreak");
	while (1);
}

void _trm_init() {
	uart_init();
	int ret = main(mainargs);
	halt(ret);
}
