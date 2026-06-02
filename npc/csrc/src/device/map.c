#include <config.h>
#ifdef CONFIG_DEVICE

#include "../Include/device.h"
#include "../Include/ram.h"
#include "../Include/log.h"

#define IO_SPACE_MAX (6 * 1024 * 1024)

static uint8_t *io_space = NULL;
static uint8_t *p_space = NULL;

uint8_t* new_space(int size) {
  uint8_t *p = p_space;
  // page aligned;
  size = (size + (PAGE_SIZE - 1)) & ~PAGE_MASK;
  p_space += size;
  assert(p_space - io_space < IO_SPACE_MAX);
  return p;
}

static void invoke_callback(io_callback_t c, paddr_t offset, int len, uint32_t is_write) {
    if (c != NULL) {
        c(offset, len, is_write);
    }
}

void init_map() {
    io_space = (uint8_t *)malloc(IO_SPACE_MAX);
    assert(io_space);
    p_space = io_space;
}

word_t map_read(paddr_t addr, int len, IOMap *map) {
    assert(len >= 1 && len <= 8);
    if (map == NULL) {
        return 0;
    }
    paddr_t offset = addr - map->low;
    invoke_callback(map->callback, offset, len, 0);
    uint8_t *space = (uint8_t *)map->space;
    word_t ret = *(uint32_t *)(space + offset);
    IFDEF(CONFIG_DTRACE, record_dtrace(map->name, 0));
    return ret;
}

// 写通道传进来的是 AXI WSTRB 字节掩码，不是访问字节数。
void map_write(paddr_t addr, int wmask, word_t data, IOMap *map) {
    assert(map != NULL);
    assert(wmask != 0 && (wmask & ~0xf) == 0);

    uint8_t *space = (uint8_t *)map->space;
    paddr_t aligned_addr = addr & ~0x3u;

    for (int i = 0; i < 4; i++) {
        if (wmask & (1 << i)) {
            paddr_t byte_addr = aligned_addr + i;
            assert(map_inside(map, byte_addr));
            space[byte_addr - map->low] = (data >> (i * 8)) & 0xff;
        }
    }

    paddr_t offset = addr - map->low;
    invoke_callback(map->callback, offset, wmask, 1);
    IFDEF(CONFIG_DTRACE, record_dtrace(map->name, 1));
}

#endif
