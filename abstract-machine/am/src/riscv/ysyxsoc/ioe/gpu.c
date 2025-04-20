#include <am.h>
#include <npc.h>
#include <stdio.h>

#define VGA 0x21000000

volatile void __am_gpu_init() {
    // int i;
    // int w = io_read(AM_GPU_CONFIG).width;
    // int h = io_read(AM_GPU_CONFIG).height;
    // for (i = 0; i < w * h; i++) fb[i] = i;
    // io_write(AM_GPU_FBDRAW, 0, 0, buf, 10, 15, 0);
    // io_write(AM_GPU_FBDRAW, 0, 0, 0, 0, 0, 1);
	return;
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
    *cfg = (AM_GPU_CONFIG_T){
        .present = true, .has_accel = false,
        .width = 640, .height = 480,
        .vmemsz = 640*480*4
    };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
    int width = io_read(AM_GPU_CONFIG).width;
    for (uint32_t i = ctl->y; i < ctl->y + ctl->h; i++) {
        for (uint32_t j = ctl->x; j < ctl->x + ctl->w; j++) {
            outl(VGA + (i * width * 4 + j * 4), ((uint32_t *)ctl->pixels)[(i - ctl->y) * ctl->w + (j - ctl->x)]);
        }
    }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
    status->ready = true;
}
