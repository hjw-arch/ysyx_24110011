#include <config.h>
#ifdef CONFIG_DEVICE

#include "../Include/device.h"
#include <stdint.h>
#include <SDL2/SDL.h>
#include "../Include/cpu_exec.h"


extern uint32_t cpu_state;
void device_update()
{
    static uint64_t last = 0;
    uint64_t now = get_time();
    if (now - last < 1000000 / TIMER_HZ)
    {
        return;
    }
    last = now;

    IFDEF(CONFIG_HAS_VGA, vga_update_screen());

    SDL_Event event;
    while (SDL_PollEvent(&event))
    {
        switch (event.type)
        {
        case SDL_QUIT:
            cpu_state = QUIT;
            break;
#ifdef CONFIG_HAS_KEYBOARD
        // If a key was pressed
        case SDL_KEYDOWN:
        case SDL_KEYUP:
        {
            uint8_t k = event.key.keysym.scancode;
            uint32_t is_keydown = (event.key.type == SDL_KEYDOWN);
            send_key(k, is_keydown);
            break;
        }
#endif
        default:
            break;
        }
    }
}

void sdl_clear_event_queue() {
#ifndef CONFIG_TARGET_AM
    SDL_Event event;
    while (SDL_PollEvent(&event));
#endif
}

void init_device() {
    init_map();

    IFDEF(CONFIG_HAS_SERIAL, init_serial());
    IFDEF(CONFIG_HAS_TIMER, init_timer());
    IFDEF(CONFIG_HAS_VGA, init_vga());
    IFDEF(CONFIG_HAS_KEYBOARD, init_i8042());
    IFDEF(CONFIG_HAS_AUDIO, init_audio());
}

#endif
