#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
    const char *p = s;
    while (*p != '\0') {
        p++;
    }
    return (size_t)(p - s);
}

char *strcpy(char *dst, const char *src) {
    char *ret = dst;

    while ((*dst++ = *src++) != '\0') {}

    return ret;
}

char *strncpy(char *dst, const char *src, size_t n) {
    char *ret = dst;

    while (n != 0 && *src != '\0') {
        *dst++ = *src++;
        n--;
    }

    while (n != 0) {
        *dst++ = '\0';
        n--;
    }

    return ret;
}

char *strcat(char *dst, const char *src) {
    char *ret = dst;

    while (*dst != '\0') {
        dst++;
    }

    while ((*dst++ = *src++) != '\0') {}

    return ret;
}

int strcmp(const char *s1, const char *s2) {
    const unsigned char *a = (const unsigned char *)s1;
    const unsigned char *b = (const unsigned char *)s2;

    while (*a == *b) {
        if (*a == '\0') {
            return 0;
        }

        a++;
        b++;
  }

  return (int)*a - (int)*b;
}

int strncmp(const char *s1, const char *s2, size_t n) {
    const unsigned char *a = (const unsigned char *)s1;
    const unsigned char *b = (const unsigned char *)s2;

    while (n != 0) {
        if (*a != *b) {
            return (int)*a - (int)*b;
        }
        
        if (*a == '\0') {
            return 0;
        }
    
        a++;
        b++;
        n--;
    }

  return 0;
}

void *memset(void *s, int c, size_t n) {
    unsigned char *p = s;

    while (n != 0) {
        *p++ = (unsigned char)c;
        n--;
    }

    return s;
}

void *memmove(void *dst, const void *src, size_t n) {
    uint8_t *d = dst, *s = (uint8_t *)src;
    if (d < s) {
        for (size_t i = 0; i < n; ++i) d[i] = s[i];
    } else {
        while (n != 0) {
            n--;
            d[n] = s[n];
        }
    }

    return dst;
}

void *memcpy(void *dst, const void *src, size_t n) {
    unsigned char *d = dst;
    const unsigned char *s = src;

    while (n != 0) {
        *d++ = *s++;
        n--;
    }

    return dst;
}

int memcmp(const void *s1, const void *s2, size_t n) {
    const unsigned char *a = s1;
    const unsigned char *b = s2;

    while (n != 0) {
        if (*a != *b) {
            return (int)*a - (int)*b;
        }
        
        a++;
        b++;
        n--;
    }

    return 0;
}

#endif
