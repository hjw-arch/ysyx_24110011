#include <am.h>
#include <npc.h>
#include <stdio.h>

#define TIMER_LOW32		*(volatile unsigned *)0x02000000
#define TIMER_HIGH32	*(volatile unsigned *)0x02000004

void __am_timer_init() {
    return;
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
    uptime->us = (((uint64_t)TIMER_HIGH32 << 32) | (uint64_t)TIMER_LOW32);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
    rtc->year   = 2025;
    rtc->month  = 4;
    rtc->day    = 22;
    rtc->hour   = 13;
    rtc->minute = 0;
    rtc->second = 0;
}

