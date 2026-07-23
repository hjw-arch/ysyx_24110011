#include <am.h>
#include <nemu.h>
#include <stdio.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)
#define BLIT_ADDR (VGACTL_ADDR + 8)

void __am_gpu_init() {
    // int i;
    // int w = io_read(AM_GPU_CONFIG).width;
    // int h = io_read(AM_GPU_CONFIG).height;
    // uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
    // for (i = 0; i < w * h; i++) fb[i] = i;
    // outl(SYNC_ADDR, 1);
    // io_write(AM_GPU_FBDRAW, 0, 0, buf, 10, 15, 0);
    // io_write(AM_GPU_FBDRAW, 0, 0, 0, 0, 0, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
    uint32_t width_higth = inl(VGACTL_ADDR);
    *cfg = (AM_GPU_CONFIG_T){
        .present = true, .has_accel = false,
        .width = width_higth >> 16, .height = width_higth & 0x0000ffff,
        .vmemsz = (width_higth >> 16) * (width_higth & 0x0000ffff) * 4
    };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
#if GPU_BLIT
    uint32_t cmd[] = {
        (uintptr_t)ctl->pixels,
        (uint32_t)ctl->x | (uint32_t)ctl->y << 16,
        (uint32_t)ctl->w | (uint32_t)ctl->h << 16,
        ctl->sync
    };
    asm volatile("" ::: "memory");
    outl(BLIT_ADDR, (uintptr_t)cmd);
#else
    int width = io_read(AM_GPU_CONFIG).width;
    for (uint32_t i = ctl->y; i < ctl->y + ctl->h; i++) {
        for (uint32_t j = ctl->x; j < ctl->x + ctl->w; j++) {
            outl(FB_ADDR + (i * width * 4 + j * 4), ((uint32_t *)ctl->pixels)[(i - ctl->y) * ctl->w + (j - ctl->x)]);
        }
    }
    if (ctl->sync) {
        outl(SYNC_ADDR, 1);
    }
#endif
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
    status->ready = true;
}
