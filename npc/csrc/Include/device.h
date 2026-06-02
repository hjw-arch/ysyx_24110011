#ifndef DEVICE_H
#define DEVICE_H

#include <config.h>

#ifdef CONFIG_DEVICE

#include <stdint.h>
#include <sys/time.h>
#include "ram.h"

#define CONFIG_HAS_SERIAL       1
#define CONFIG_HAS_TIMER        1
#define CONFIG_HAS_VGA          1
#define CONFIG_HAS_KEYBOARD     1
#define CONFIG_HAS_AUDIO        1



#define TIMER_HZ 60
#define CONFIG_VGA_SIZE_400x300 1
#define CONFIG_VGA_SHOW_SCREEN 1

#define CONFIG_SERIAL_MMIO      0xa00003f8
#define CONFIG_RTC_MMIO         0xa0000048
#define CONFIG_I8042_DATA_MMIO  0xa0000080      // 与nemu不同
#define CONFIG_FB_ADDR          0xa1000000
#define CONFIG_VGA_CTL_MMIO     0xa0000100
#define CONFIG_AUDIO_CTL_MMIO   0xa0000200
#define CONFIG_SB_ADDR          0xa1200000

#define CONFIG_SB_SIZE 0x200000

typedef void(*io_callback_t)(uint32_t, int, uint32_t);
uint8_t* new_space(int size);

typedef struct {
  const char *name;
  // we treat ioaddr_t as paddr_t here
  paddr_t low;
  paddr_t high;
  void *space;
  io_callback_t callback;
} IOMap;

static inline uint32_t map_inside(IOMap *map, paddr_t addr) {
  return (addr >= map->low && addr <= map->high);
}

static inline int find_mapid_by_addr(IOMap *maps, int size, paddr_t addr) {
  int i;
  for (i = 0; i < size; i ++) {
    if (map_inside(maps + i, addr)) {
      return i;
    }
  }
  return -1;
}

uint64_t get_time();

void init_map();
word_t map_read(paddr_t addr, int len, IOMap *map);
void map_write(paddr_t addr, int wmask, word_t data, IOMap *map);

word_t mmio_read(paddr_t addr, int len);
void mmio_write(paddr_t addr, int wmask, word_t data);

void add_mmio_map(const char *name, paddr_t addr, void *space, uint32_t len, io_callback_t callback);

void init_vga();
void vga_update_screen();

void init_timer();
void init_serial();
void init_i8042();
void send_key(uint8_t scancode, uint32_t is_keydown);

void init_audio();

void init_device();
void device_update();

#endif

#endif
