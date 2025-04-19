#include <am.h>
#include <npc.h>

#define KEYDOWN_MASK 0x8000
#define KEYBOARD *(volatile unsigned char *)0x10011000;

// PS/2键盘扫描码集2到宏定义的映射数组
// 索引是Set 2按下扫描码（make code），值是对应的AM_KEY_*宏定义
// 抬起码为0xF0后跟按下码，需在应用层处理
// 扩展键（E0前缀）使用第二字节作为索引
const unsigned char scancode_to_keymap[256] = {
    [0x76] = AM_KEY_ESCAPE,       // 0x76: Escape
    [0x05] = AM_KEY_F1,           // 0x05: F1
    [0x06] = AM_KEY_F2,           // 0x06: F2
    [0x04] = AM_KEY_F3,           // 0x04: F3
    [0x0C] = AM_KEY_F4,           // 0x0C: F4
    [0x03] = AM_KEY_F5,           // 0x03: F5
    [0x0B] = AM_KEY_F6,           // 0x0B: F6
    [0x83] = AM_KEY_F7,           // 0x83: F7
    [0x0A] = AM_KEY_F8,           // 0x0A: F8
    [0x01] = AM_KEY_F9,           // 0x01: F9
    [0x09] = AM_KEY_F10,          // 0x09: F10
    [0x78] = AM_KEY_F11,          // 0x78: F11
    [0x07] = AM_KEY_F12,          // 0x07: F12
    [0x0E] = AM_KEY_GRAVE,        // 0x0E: Grave (`/~)
    [0x16] = AM_KEY_1,            // 0x16: 1
    [0x1E] = AM_KEY_2,            // 0x1E: 2
    [0x26] = AM_KEY_3,            // 0x26: 3
    [0x25] = AM_KEY_4,            // 0x25: 4
    [0x2E] = AM_KEY_5,            // 0x2E: 5
    [0x36] = AM_KEY_6,            // 0x36: 6
    [0x3D] = AM_KEY_7,            // 0x3D: 7
    [0x3E] = AM_KEY_8,            // 0x3E: 8
    [0x46] = AM_KEY_9,            // 0x46: 9
    [0x45] = AM_KEY_0,            // 0x45: 0
    [0x4E] = AM_KEY_MINUS,        // 0x4E: Minus (-/_)
    [0x55] = AM_KEY_EQUALS,       // 0x55: Equals (=/+)
    [0x66] = AM_KEY_BACKSPACE,    // 0x66: Backspace
    [0x0D] = AM_KEY_TAB,          // 0x0D: Tab
    [0x15] = AM_KEY_Q,            // 0x15: Q
    [0x1D] = AM_KEY_W,            // 0x1D: W
    [0x24] = AM_KEY_E,            // 0x24: E
    [0x2D] = AM_KEY_R,            // 0x2D: R
    [0x2C] = AM_KEY_T,            // 0x2C: T
    [0x35] = AM_KEY_Y,            // 0x35: Y
    [0x3C] = AM_KEY_U,            // 0x3C: U
    [0x43] = AM_KEY_I,            // 0x43: I
    [0x44] = AM_KEY_O,            // 0x44: O
    [0x4D] = AM_KEY_P,            // 0x4D: P
    [0x54] = AM_KEY_LEFTBRACKET,  // 0x54: Left Bracket ([/{)
    [0x5B] = AM_KEY_RIGHTBRACKET, // 0x5B: Right Bracket (]/})
    [0x5D] = AM_KEY_BACKSLASH,    // 0x5D: Backslash (\)
    [0x58] = AM_KEY_CAPSLOCK,     // 0x58: Caps Lock
    [0x1C] = AM_KEY_A,            // 0x1C: A
    [0x1B] = AM_KEY_S,            // 0x1B: S
    [0x23] = AM_KEY_D,            // 0x23: D
    [0x2B] = AM_KEY_F,            // 0x2B: F
    [0x34] = AM_KEY_G,            // 0x34: G
    [0x33] = AM_KEY_H,            // 0x33: H
    [0x3B] = AM_KEY_J,            // 0x3B: J
    [0x42] = AM_KEY_K,            // 0x42: K
    [0x4B] = AM_KEY_L,            // 0x4B: L
    [0x4C] = AM_KEY_SEMICOLON,    // 0x4C: Semicolon (;/:)
    [0x52] = AM_KEY_APOSTROPHE,   // 0x52: Apostrophe ('/")
    [0x5A] = AM_KEY_RETURN,       // 0x5A: Enter
    [0x12] = AM_KEY_LSHIFT,       // 0x12: Left Shift
    [0x1A] = AM_KEY_Z,            // 0x1A: Z
    [0x22] = AM_KEY_X,            // 0x22: X
    [0x21] = AM_KEY_C,            // 0x21: C
    [0x2A] = AM_KEY_V,            // 0x2A: V
    [0x32] = AM_KEY_B,            // 0x32: B
    [0x31] = AM_KEY_N,            // 0x31: N
    [0x3A] = AM_KEY_M,            // 0x3A: M
    [0x41] = AM_KEY_COMMA,        // 0x41: Comma (,/<)
    [0x49] = AM_KEY_PERIOD,       // 0x49: Period (./>)
    [0x4A] = AM_KEY_SLASH,        // 0x4A: Slash (?/)
    [0x59] = AM_KEY_RSHIFT,       // 0x59: Right Shift
    [0x14] = AM_KEY_LCTRL,        // 0x14: Left Ctrl
    [0x5F] = AM_KEY_APPLICATION,  // 0xE0 0x2F: Application (Menu key, E0 prefix)
    [0x11] = AM_KEY_LALT,         // 0x11: Left Alt
    [0x29] = AM_KEY_SPACE,        // 0x29: Space
    // [0xE0 + 0x11] = AM_KEY_RALT,         // 0xE0 0x11: Right Alt
    // [0xE0 + 0x14] = AM_KEY_RCTRL,        // 0xE0 0x14: Right Ctrl
    // [0xE0 + 0x75] = AM_KEY_UP,           // 0xE0 0x75: Up Arrow
    // [0xE0 + 0x72] = AM_KEY_DOWN,         // 0xE0 0x72: Down Arrow
    // [0xE0 + 0x6B] = AM_KEY_LEFT,         // 0xE0 0x6B: Left Arrow
    // [0xE0 + 0x74] = AM_KEY_RIGHT,        // 0xE0 0x74: Right Arrow
    // [0xE0 + 0x70] = AM_KEY_INSERT,       // 0xE0 0x70: Insert
    // [0xE0 + 0x71] = AM_KEY_DELETE,       // 0xE0 0x71: Delete
    // [0xE0 + 0x6C] = AM_KEY_HOME,         // 0xE0 0x6C: Home
    // [0xE0 + 0x69] = AM_KEY_END,          // 0xE0 0x69: End
    // [0xE0 + 0x7D] = AM_KEY_PAGEUP,       // 0xE0 0x7D: Page Up
    // [0xE0 + 0x7A] = AM_KEY_PAGEDOWN      // 0xE0 0x7A: Page Down
};

#include "stdio.h"

static bool E0_prefix = false;
static bool F0_prefix = false;
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
	uint8_t keycode = KEYBOARD;

	kbd->keycode = 0;
	kbd->keydown = false;

	if (keycode == 0) {
		return;
	}

	if (keycode == 0xF0) {
		F0_prefix = true;
		return;
	}

	if (keycode == 0xE0) {
		E0_prefix = true;
		F0_prefix = false;
		return;
	}

	kbd->keycode = scancode_to_keymap[keycode];
	kbd->keydown = !F0_prefix;

	if (E0_prefix)
	{
		// 处理 E0 序列的第二个字节
		switch (keycode)
		{
		case 0x11: // E0 11 -> Right Alt
			kbd->keycode = AM_KEY_RALT;
			break;
		case 0x14: // E0 14 -> Right Ctrl
			kbd->keycode = AM_KEY_RCTRL;
			break;
		// 你要求的其他 E0 键:
		case 0x75: // E0 75 -> Up Arrow
			kbd->keycode = AM_KEY_UP;
			break;
		case 0x72: // E0 72 -> Down Arrow
			kbd->keycode = AM_KEY_DOWN;
			break;
		case 0x6B: // E0 6B -> Left Arrow
			kbd->keycode = AM_KEY_LEFT;
			break;
		case 0x74: // E0 74 -> Right Arrow
			kbd->keycode = AM_KEY_RIGHT;
			break;
		case 0x70: // E0 70 -> Insert
			kbd->keycode = AM_KEY_INSERT;
			break;
		case 0x71: // E0 71 -> Delete
			kbd->keycode = AM_KEY_DELETE;
			break;
		case 0x6C: // E0 6C -> Home
			kbd->keycode = AM_KEY_HOME;
			break;
		case 0x69: // E0 69 -> End
			kbd->keycode = AM_KEY_END;
			break;
		case 0x7D: // E0 7D -> Page Up
			kbd->keycode = AM_KEY_PAGEUP;
			break;
		case 0x7A: // E0 7A -> Page Down
			kbd->keycode = AM_KEY_PAGEDOWN;
			break;
		default:
			kbd->keycode = scancode_to_keymap[keycode]; // 忽略未明确处理的 E0 序列
			break;
		}
		E0_prefix = false;
		return;
	}

	if (F0_prefix) {
		F0_prefix = false;
	}
	
	return;
}
