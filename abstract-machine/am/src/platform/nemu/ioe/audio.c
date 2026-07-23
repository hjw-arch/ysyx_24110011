#include <am.h>
#include <nemu.h>
#include <stdio.h>
#include <string.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

void __am_audio_init() {

}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
    cfg->present = true;
    cfg->bufsize = inl(AUDIO_SBUF_SIZE_ADDR);
}

// int freq, channels, samples
void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
    outl(AUDIO_FREQ_ADDR, ctrl->freq);
    outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
    outl(AUDIO_SAMPLES_ADDR, ctrl->samples);

    outl(AUDIO_INIT_ADDR, 1);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
    stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
    static uint32_t index = 0;
    uint32_t len = ctl->buf.end - ctl->buf.start;
    uint32_t bufsize = inl(AUDIO_SBUF_SIZE_ADDR);
    while (bufsize - inl(AUDIO_COUNT_ADDR) < len);
    uint32_t remaindSize = bufsize - index;   // 查看距离缓冲区结束地址还有多大空间

    if (remaindSize < len) {    // 如果剩余的空间不足以存下len字节的音频数据
        memcpy((void *)(AUDIO_SBUF_ADDR + index), ctl->buf.start, remaindSize); // 先将剩下的缓冲区填满
        index = 0;  // 转移到开头，将还没被填入缓冲区的数据填入缓冲区的开头，构成环形缓冲区
        memcpy((void *)(AUDIO_SBUF_ADDR + index), ctl->buf.start + remaindSize, len - remaindSize);
        index += len - remaindSize;
    } else {    // 如果剩余空间足够存下len字节的数据，直接填充
        memcpy((void *)(AUDIO_SBUF_ADDR + index), ctl->buf.start, len);
        index += len;   // 填充后更新位置index
    }
    
    outl(AUDIO_COUNT_ADDR, inl(AUDIO_COUNT_ADDR) + len);    // 更新可供提取的音频字节数量
}
