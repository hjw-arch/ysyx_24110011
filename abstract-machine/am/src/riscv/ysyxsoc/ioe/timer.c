// #include <am.h>
// #include <npc.h>
// #include <stdio.h>
// void __am_timer_init() {
//     outl(RTC_ADDR, 0);
//     outl(RTC_ADDR + 4, 0);
// }

// void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
//     uptime->us = ((uint64_t)inl(RTC_ADDR + 4) << 32) | (uint64_t)inl(RTC_ADDR);
// }

// void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
//     rtc->year   = inl(RTC_ADDR + 8);
//     rtc->month  = inl(RTC_ADDR + 12);
//     rtc->day    = inl(RTC_ADDR + 16);
//     rtc->hour   = inl(RTC_ADDR + 20);
//     rtc->minute = inl(RTC_ADDR + 24);
//     rtc->second = inl(RTC_ADDR + 28);
// }

