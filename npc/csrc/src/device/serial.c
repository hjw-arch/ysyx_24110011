#ifdef CONFIG_DEVICE

#include "../Include/device.h"
#include <stdio.h>

static uint8_t *serial_base = NULL;
static void serial_io_handler(uint32_t offset, int len, uint32_t is_write) {
    if (!is_write) return;
    // putchar(serial_base[0]);
    printf("%c", serial_base[0]);
    fflush(stdout);
}

void init_serial()
{
    serial_base = new_space(8);
    add_mmio_map("serial", CONFIG_SERIAL_MMIO, serial_base, 4, serial_io_handler);
}


#endif
