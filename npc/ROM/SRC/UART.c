#define UART_BASE	0x10000000L
#define	UART_TX		0x0

void _start() {
	*(volatile char*)(UART_BASE + UART_TX) = 'A';
	*(volatile char*)(UART_BASE + UART_TX) = 'B';
	*(volatile char*)(UART_BASE + UART_TX) = 'C';
	*(volatile char*)(UART_BASE + UART_TX) = 'D';
	// *(volatile char*)(UART_BASE + UART_TX) = '\n';
	while(1);
}
