#ifdef CONFIG_DEVICE

#include "../Include/device.h"
#include "log.h"

#define NR_MAP 16

static IOMap maps[NR_MAP] = {};
static int nr_map = 0;

static uint32_t in_pmem(paddr_t addr) {
  return addr - RAM_START_ADDR < RAM_SIZE;
}

static IOMap *fetch_mmio_map(paddr_t addr)
{
    int mapid = find_mapid_by_addr(maps, nr_map, addr);
    return (mapid == -1 ? NULL : &maps[mapid]);
}

/* device interface */
void add_mmio_map(const char *name, paddr_t addr, void *space, uint32_t len, io_callback_t callback)
{
    assert(nr_map < NR_MAP);
    paddr_t left = addr, right = addr + len - 1;
    if (in_pmem(left) || in_pmem(right))
    {
        assert(0);
    }

    for (int i = 0; i < nr_map; i++)
    {
        if (left <= maps[i].high && right >= maps[i].low)
        {
            assert(0);
        }
    }

    maps[nr_map] = (IOMap){.name = name, .low = addr, .high = addr + len - 1, .space = space, .callback = callback};

    nr_map++;
}

/* bus interface */
word_t mmio_read(paddr_t addr, int len)
{
    return map_read(addr, len, fetch_mmio_map(addr));
}

void mmio_write(paddr_t addr, int len, word_t data)
{
    map_write(addr, len, data, fetch_mmio_map(addr));
}

#endif
