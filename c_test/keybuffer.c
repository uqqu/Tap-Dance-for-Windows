#include "keybuffer.h"
#include <stdlib.h>
#include <stdio.h>

static unsigned int s_allowed_mask[BUFFER_SIZE];
unsigned int g_key_buffer[BUFFER_SIZE];
unsigned int g_mod_buffer[BUFFER_SIZE];

int is_pressed(const unsigned int buf[], int sc) {
    int idx = sc / BITS_PER_WORD;
    unsigned int m = 1u << (sc % BITS_PER_WORD);
    return (buf[idx] & m) != 0;
}

void set_pressed(unsigned int buf[], int sc) {
    buf[sc / BITS_PER_WORD] |= 1u << (sc % BITS_PER_WORD);
}

void clear_pressed(unsigned int buf[], int sc) {
    buf[sc / BITS_PER_WORD] &= ~(1u << (sc % BITS_PER_WORD));
}

char *buffer_to_hex(const unsigned char *data, size_t len) {
    char *hex = malloc(len * 2 + 1);
    if (!hex) return NULL;
    for (size_t i = 0; i < len; i++) {
        sprintf(hex + i*2, "%02X", data[i]);
    }
    hex[len*2] = '\0';
    return hex;
}

char *intbuf_to_hex(const unsigned int *data, size_t count) {
    return buffer_to_hex((const unsigned char*)data, count * sizeof(unsigned int));
}

void init_scancode_mask(void) {
    int allowed[] = {0x02A, 0x136, 0x036, 0x01D, 0x11D, 0x15B, 0x15C};
    size_t n = sizeof(allowed)/sizeof(allowed[0]);
    for (size_t i = 0; i < n; i++) {
        int sc = allowed[i];
        s_allowed_mask[sc/BITS_PER_WORD] |= 1u << (sc%BITS_PER_WORD);
    }
}

int in_allowed(int sc) {
    if (sc < 0 || sc >= MAX_SCANCODE) return 0;
    return (s_allowed_mask[sc/BITS_PER_WORD] & (1u << (sc%BITS_PER_WORD))) != 0;
}