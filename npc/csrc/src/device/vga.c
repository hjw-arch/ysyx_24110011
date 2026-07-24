#include <config.h>
#if defined(CONFIG_DEVICE) && defined(CONFIG_HAS_VGA)

#include "../Include/device.h"

#define SCREEN_W (MUXDEF(CONFIG_VGA_SIZE_800x600, 800, 400))
#define SCREEN_H (MUXDEF(CONFIG_VGA_SIZE_800x600, 600, 300))

static uint32_t screen_size()
{
    return SCREEN_W * SCREEN_H * sizeof(uint32_t);
}

static void *vmem = NULL;
static uint32_t *vgactl_port_base = NULL;

enum { VGACTL_SCREEN, VGACTL_SYNC, VGACTL_BLIT, VGACTL_NR };

static void vga_io_handler(uint32_t offset, int len, uint32_t is_write)
{
    if (!is_write || offset != VGACTL_BLIT * sizeof(uint32_t)) return;

    uint32_t cmd_addr = vgactl_port_base[VGACTL_BLIT];
    assert(cmd_addr >= RAM_START_ADDR && cmd_addr <= RAM_END_ADDR - 4 * sizeof(uint32_t) + 1);
    uint32_t *cmd = (uint32_t *)guest_to_host(cmd_addr);
    uint32_t x = cmd[1] & 0xffff;
    uint32_t y = cmd[1] >> 16;
    uint32_t w = cmd[2] & 0xffff;
    uint32_t h = cmd[2] >> 16;
    uint32_t src_addr = cmd[0];

    assert(x + w <= SCREEN_W && y + h <= SCREEN_H);
    if (w && h) {
        assert(src_addr >= RAM_START_ADDR && src_addr <= RAM_END_ADDR &&
               w * h * sizeof(uint32_t) <= RAM_END_ADDR - src_addr + 1);
        uint32_t *src = (uint32_t *)guest_to_host(src_addr);
        uint32_t *dst = (uint32_t *)vmem + y * SCREEN_W + x;
        for (uint32_t row = 0; row < h; row++) {
            memcpy(dst + row * SCREEN_W, src + row * w, w * sizeof(uint32_t));
        }
    }
    vgactl_port_base[VGACTL_SYNC] = cmd[3];
}

#ifdef CONFIG_VGA_SHOW_SCREEN
#include <SDL2/SDL.h>

static SDL_Renderer *renderer = NULL;
static SDL_Texture *texture = NULL;

static void init_screen()
{
    SDL_Window *window = NULL;
    char title[128];
    sprintf(title, "%s-NPC", "riscv32e");
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

static inline void update_screen()
{
    SDL_UpdateTexture(texture, NULL, vmem, SCREEN_W * sizeof(uint32_t));
    SDL_RenderClear(renderer);
    SDL_RenderCopy(renderer, texture, NULL, NULL);
    SDL_RenderPresent(renderer);
}

#endif

void vga_update_screen()
{
    if (vgactl_port_base[VGACTL_SYNC])
    {
        IFDEF(CONFIG_VGA_SHOW_SCREEN, update_screen());
        vgactl_port_base[VGACTL_SYNC] = 0;
    }
}

void init_vga()
{
    vgactl_port_base = (uint32_t *)new_space(VGACTL_NR * sizeof(uint32_t));
    vgactl_port_base[VGACTL_SCREEN] = (SCREEN_W << 16) | SCREEN_H;

    add_mmio_map("vgactl", VGA_CTL_MMIO, vgactl_port_base, VGACTL_NR * sizeof(uint32_t), vga_io_handler);

    vmem = new_space(screen_size());
    add_mmio_map("vmem", FB_ADDR, vmem, screen_size(), NULL);
    IFDEF(CONFIG_VGA_SHOW_SCREEN, init_screen());
    IFDEF(CONFIG_VGA_SHOW_SCREEN, memset(vmem, 0, screen_size()));
}

#endif
