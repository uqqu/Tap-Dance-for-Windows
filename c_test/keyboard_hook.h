#ifndef KEYBOARD_HOOK_H
#define KEYBOARD_HOOK_H

#include <windows.h>
#include "structures.h"

int  key_down_handler(int scancode);
void key_up_handler(int scancode);
LRESULT CALLBACK low_level_keyboard_proc(int nCode, WPARAM wParam, LPARAM lParam);

/* Action functions */
void send_value(Triple *tr);
void handle_triple(Triple *tr);

#endif /* KEYBOARD_HOOK_H */