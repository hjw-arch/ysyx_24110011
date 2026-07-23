/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <common.h>
#include <device/map.h>
#include <SDL2/SDL.h>

enum {
  reg_freq,
  reg_channels,
  reg_samples,
  reg_sbuf_size,
  reg_init,
  reg_count,
  nr_reg
};

static uint8_t *sbuf = NULL;
static uint32_t *audio_base = NULL;
static uint8_t *sbuf_end = NULL;
static uint8_t *audio_pos = NULL;

SDL_AudioSpec spec;

static void audio_callback(void *userdata, uint8_t *stream, int len) {
    uint32_t len_to_copy;       // 需要复制的字节

    if (audio_base[reg_count] == 0) {
        SDL_memset(stream, spec.silence, len);
        return;
    }

    // 如果剩余的音频数据小于len，那么只需要复制剩余的音频数据给SDL即可
    len_to_copy = audio_base[reg_count] < len ? audio_base[reg_count] : len;

    // 查看当前的读指针距离缓冲区结束位置还有多大空间
    uint32_t remainderSize = sbuf_end - audio_pos;

    // 如果剩余的空间不足够提取len_to_copy个字节，则从剩余的空间中先提取数据
    // 然后将读指针指向缓冲区的开头，再将剩下的没有提取的大小提取到SDL
    if (remainderSize < len_to_copy) {
        SDL_memcpy(stream, audio_pos, remainderSize);
        audio_pos = sbuf;
        SDL_memcpy(stream + remainderSize, audio_pos, len_to_copy - remainderSize);
        audio_pos += len_to_copy - remainderSize;
    } else {    // 剩余空间足够的话，直接复制，然后更新读指针的位置
        SDL_memcpy(stream, audio_pos, len_to_copy);
        audio_pos += len_to_copy;
    }
    // 如果给到SDL的字节小于len，将后面缺少的空间填0
    if (len_to_copy < len) SDL_memset(stream + len_to_copy, spec.silence, len - len_to_copy);

    // 更新剩余的音频字节
    audio_base[reg_count] -= len_to_copy;
}

static void audio_io_handler(uint32_t offset, int len, bool is_write) {
    if (!is_write) return;

    if (offset == reg_freq * 4) spec.freq = audio_base[reg_freq];
    if (offset == reg_channels * 4) spec.channels = audio_base[reg_channels];
    if (offset == reg_samples * 4) spec.samples = audio_base[reg_samples];

    if (audio_base[reg_init]) {
        audio_pos = sbuf;
        sbuf_end = sbuf + CONFIG_SB_SIZE;
        SDL_InitSubSystem(SDL_INIT_AUDIO);
        spec.callback = audio_callback;
        spec.format = AUDIO_S16SYS;
        spec.silence = 0;
        SDL_OpenAudio(&spec, 0);
        SDL_PauseAudio(0);

        audio_base[reg_init] = 0;
    }
}

void init_audio() {
    uint32_t space_size = sizeof(uint32_t) * nr_reg;
    audio_base = (uint32_t *)new_space(space_size);
    SDL_memset(audio_base, 0, space_size);
    audio_base[reg_sbuf_size] = CONFIG_SB_SIZE;
#ifdef CONFIG_HAS_PORT_IO
    add_pio_map ("audio", CONFIG_AUDIO_CTL_PORT, audio_base, space_size, audio_io_handler);
#else
    add_mmio_map("audio", CONFIG_AUDIO_CTL_MMIO, audio_base, space_size, audio_io_handler);
#endif

    sbuf = (uint8_t *)new_space(CONFIG_SB_SIZE);
    add_mmio_map("audio-sbuf", CONFIG_SB_ADDR, sbuf, CONFIG_SB_SIZE, NULL);
}

void destory_audio() {
    SDL_CloseAudio();
    SDL_QuitSubSystem(SDL_INIT_AUDIO);
}
