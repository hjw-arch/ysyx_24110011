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
#include <memory/paddr.h>

#define SCREEN_W (MUXDEF(CONFIG_VGA_SIZE_800x600, 800, 400))
#define SCREEN_H (MUXDEF(CONFIG_VGA_SIZE_800x600, 600, 300))

static uint32_t screen_width() {
    return MUXDEF(CONFIG_TARGET_AM, io_read(AM_GPU_CONFIG).width, SCREEN_W);
}

static uint32_t screen_height() {
    return MUXDEF(CONFIG_TARGET_AM, io_read(AM_GPU_CONFIG).height, SCREEN_H);
}

static uint32_t screen_size() {
    return screen_width() * screen_height() * sizeof(uint32_t);
}

static void *vmem = NULL;
static uint32_t *vgactl_port_base = NULL;

enum { VGACTL_SCREEN, VGACTL_SYNC, VGACTL_BLIT, VGACTL_NR };

static void vga_io_handler(uint32_t offset, int len, bool is_write) {
    if (!is_write || offset != VGACTL_BLIT * sizeof(uint32_t)) return;

    uint32_t cmd_addr = vgactl_port_base[VGACTL_BLIT];
    assert(in_pmem(cmd_addr) && in_pmem(cmd_addr + 4 * sizeof(uint32_t) - 1));
    uint32_t *cmd = (uint32_t *)guest_to_host(cmd_addr);
    uint32_t x = cmd[1] & 0xffff;
    uint32_t y = cmd[1] >> 16;
    uint32_t w = cmd[2] & 0xffff;
    uint32_t h = cmd[2] >> 16;
    uint32_t src_addr = cmd[0];

    assert(x + w <= screen_width() && y + h <= screen_height());
    if (w && h) {
        assert(in_pmem(src_addr) && in_pmem(src_addr + w * h * sizeof(uint32_t) - 1));
        uint32_t *src = (uint32_t *)guest_to_host(src_addr);
        uint32_t *dst = (uint32_t *)vmem + y * screen_width() + x;
        for (uint32_t row = 0; row < h; row++) {
            memcpy(dst + row * screen_width(), src + row * w, w * sizeof(uint32_t));
        }
    }
    vgactl_port_base[VGACTL_SYNC] = cmd[3];
}

#ifdef CONFIG_VGA_SHOW_SCREEN
#ifndef CONFIG_TARGET_AM
#include <SDL2/SDL.h>

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;
static SDL_Window *window = NULL;

static void init_screen() {
    char title[128];
    sprintf(title, "%s-NEMU", str(__GUEST_ISA__));
    SDL_Init(SDL_INIT_VIDEO);
    SDL_CreateWindowAndRenderer(
        SCREEN_W * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
        SCREEN_H * (MUXDEF(CONFIG_VGA_SIZE_400x300, 2, 1)),
        0, &window, &renderer);
    SDL_SetWindowTitle(window, title);
    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888,
                                SDL_TEXTUREACCESS_STATIC, SCREEN_W, SCREEN_H);
    SDL_RenderPresent(renderer);
}

static inline void update_screen() {
    SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);
}
#else
static void init_screen() {}

static inline void update_screen() {
    io_write(AM_GPU_FBDRAW, 0, 0, vmem, screen_width(), screen_height(), true);
}
#endif
#endif

void vga_update_screen() {
    // TODO: call `update_screen()` when the sync register is non-zero,
    // then zero out the sync register
    if (vgactl_port_base[VGACTL_SYNC]) {
        update_screen();
        vgactl_port_base[VGACTL_SYNC] = 0;
    }
}

void init_vga() {
    vgactl_port_base = (uint32_t *)new_space(VGACTL_NR * sizeof(uint32_t));
    vgactl_port_base[VGACTL_SCREEN] = (screen_width() << 16) | screen_height();
#ifdef CONFIG_HAS_PORT_IO
    add_pio_map ("vgactl", CONFIG_VGA_CTL_PORT, vgactl_port_base, VGACTL_NR * sizeof(uint32_t), vga_io_handler);
#else
    add_mmio_map("vgactl", CONFIG_VGA_CTL_MMIO, vgactl_port_base, VGACTL_NR * sizeof(uint32_t), vga_io_handler);
#endif

    vmem = new_space(screen_size());
    add_mmio_map("vmem", CONFIG_FB_ADDR, vmem, screen_size(), NULL);
    IFDEF(CONFIG_VGA_SHOW_SCREEN, init_screen());
    IFDEF(CONFIG_VGA_SHOW_SCREEN, memset(vmem, 0, screen_size()));
}


void destory_vga() {
    if (texture != NULL) {
        SDL_DestroyTexture(texture);
        texture = NULL;
    }
    if (renderer != NULL) {
        SDL_DestroyRenderer(renderer);
        renderer = NULL;
    }
    if (window != NULL) {
        SDL_DestroyWindow(window);
        window = NULL;
    }
    SDL_QuitSubSystem(SDL_INIT_VIDEO);
}
