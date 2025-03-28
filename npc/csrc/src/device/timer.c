#ifdef CONFIG_DEVICE

#include "../Include/device.h"
#include <sys/time.h>

static uint32_t *rtc_port_base = NULL;


static void rtc_io_handler(uint32_t offset, int len, uint32_t is_write) {
    // assert(offset == 0 || offset == 4);
    if (!is_write && offset == 4) {
        uint64_t us = get_time();
        rtc_port_base[0] = (uint32_t)us;
        rtc_port_base[1] = us >> 32;
    }

    if(offset > 4 && !is_write) {

        time_t t = time(NULL);

        if (t == (time_t)(-1)) {
            perror("Failed to get current time");
            return;
        }

        struct tm *tm_info = localtime(&t);

        rtc_port_base[2] = tm_info->tm_year + 1900;
        rtc_port_base[3] = tm_info->tm_mon + 1;
        rtc_port_base[4] = tm_info->tm_mday;
        rtc_port_base[5] = tm_info->tm_hour;
        rtc_port_base[6] = tm_info->tm_min;
        rtc_port_base[7] = tm_info->tm_sec;
    } 
}


void init_timer() {
  rtc_port_base = (uint32_t *)new_space(32);
  add_mmio_map("rtc", CONFIG_RTC_MMIO, rtc_port_base, 32, rtc_io_handler);
}


#endif
