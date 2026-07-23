#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)
static unsigned long int next = 1;

int rand(void) {
    // RAND_MAX assumed to be 32767
    next = next * 1103515245 + 12345;
    return (unsigned int)(next/65536) % 32768;
}

void srand(unsigned int seed) {
    next = seed;
}

int abs(int x) {
    return (x < 0 ? -x : x);
}

int atoi(const char* nptr) {
    int x = 0;
    while (*nptr == ' ') { nptr ++; }
    while (*nptr >= '0' && *nptr <= '9') {
        x = x * 10 + *nptr - '0';
        nptr ++;
    }
    return x;
}

static uintptr_t pos;

void *malloc(size_t size) {
    const size_t align = _Alignof(max_align_t);
    uintptr_t end = (uintptr_t)heap.end;

    if (pos == 0) pos = ROUNDUP(heap.start, align);
    if (size == 0 || pos > end || size > end - pos) return NULL;

    uintptr_t next = ROUNDUP(pos + size, align);
    if (next < pos || next > end) return NULL;

    void *ret = (void *)pos;
    pos = next;
    return ret;
}

void free(void *ptr) {
    (void)ptr;
}

#endif
