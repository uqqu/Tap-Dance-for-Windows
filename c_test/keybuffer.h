#ifndef KEYBUFFER_H
#define KEYBUFFER_H

#include <stddef.h>

#define MAX_SCANCODE   512
#define BITS_PER_WORD  32
#define BUFFER_SIZE    (MAX_SCANCODE / BITS_PER_WORD)

extern unsigned int g_key_buffer[BUFFER_SIZE];
extern unsigned int g_mod_buffer[BUFFER_SIZE];

int  is_pressed(const unsigned int buf[], int sc);
void set_pressed(unsigned int buf[], int sc);
void clear_pressed(unsigned int buf[], int sc);
int  in_allowed(int sc);
char *intbuf_to_hex(const unsigned int *data, size_t count);
void init_scancode_mask(void);

#endif /* KEYBUFFER_H */