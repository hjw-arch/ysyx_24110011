#include <am.h>
#include <npc.h>
// #include <stdio.h>


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

void __am_uart_rx(AM_UART_RX_T *rx) {
	if (UART_LSR & UART_DATA_READY) {
		rx->data = UART_RX;
	} else {
		rx->data = 0xFF;
	}
}

