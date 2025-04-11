// #include <am.h>
// #include <npc.h>

// #define KEYDOWN_MASK 0x8000

// void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
//     kbd->keycode = inl(KBD_ADDR);
//     kbd->keydown = (kbd->keycode & KEYDOWN_MASK) >> 15;
//     kbd->keycode = kbd->keycode & (~KEYDOWN_MASK);
// }
