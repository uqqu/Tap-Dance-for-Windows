#include "keyboard_hook.h"
#include "keybuffer.h"
#include "structures.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern RootDict     *g_root_dict;
extern WorkingTable *g_global_table;
extern Waiting      *g_waiting;
extern Triple       *g_last_triple;
extern int           g_current_mod;
extern int           g_non_sys_mod_cnt;
extern int           g_timer_ms;
extern int           g_current_layout;
extern UINT_PTR      g_send_timer;
extern UINT_PTR      g_reset_timer;
extern UINT_PTR      g_action_timer;

/**
 * Get layout code for the foreground window.
 */
static int get_active_layout_code(void) {
    HWND fg = GetForegroundWindow();
    if (!fg) return 0;
    DWORD thread_id = GetWindowThreadProcessId(fg, NULL);
    HKL hkl = GetKeyboardLayout(thread_id);
    return (int)(INT_PTR)hkl;
}

/**
 * Deferred send: called by timer to flush last triple.
 */
static VOID CALLBACK deferred_send_handler(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime) {
    if (g_last_triple) {
        send_value(g_last_triple);
        g_last_triple = NULL;
    }
    if (g_current_mod == 0 && g_root_dict && g_root_dict->count > 0) {
        g_global_table = g_root_dict->entries[0].table;
    }
    KillTimer(NULL, idEvent);
    g_send_timer = 0;
}

/**
 * Base timer handler for tap-dance reset.
 */
static VOID CALLBACK reset_base_handler(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime) {
    g_last_triple = NULL;
    KillTimer(NULL, idEvent);
    g_reset_timer = 0;
}

/**
 * Action timer handler for delayed sequences.
 */
static VOID CALLBACK action_timer_handler(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime) {
    if (g_waiting && g_waiting->t1) {
        handle_triple(g_waiting->t1);
    }
    free(g_waiting);
    g_waiting = NULL;
    KillTimer(NULL, idEvent);
    g_action_timer = 0;
}

void handle_triple(Triple *tr) {
    if (!tr) return;
    if (tr->nested && tr->nested->count > 0) {
        g_last_triple = tr;
        g_global_table = tr->nested;
        if (g_reset_timer) {
            KillTimer(NULL, g_reset_timer);
            g_reset_timer = 0;
        }
        if (g_send_timer) KillTimer(NULL, g_send_timer);
        g_send_timer = SetTimer(NULL, 0, g_timer_ms, deferred_send_handler);
    } else {
        send_value(tr);
        g_last_triple = NULL;
        if (g_current_mod == 0 && g_root_dict && g_root_dict->count > 0) {
            g_global_table = g_root_dict->entries[0].table;
        }
    }
}

int key_down_handler(int scancode) {
    if (is_pressed(g_key_buffer, scancode) || is_pressed(g_mod_buffer, scancode))
        return 1;

    if (g_waiting) {
        handle_triple(g_waiting->t0);
        free(g_waiting);
        g_waiting = NULL;
    }

    int layout = get_active_layout_code();
    if (layout != g_current_layout) {
        deferred_send_handler(NULL, 0, 0, 0);
        g_current_layout = layout;
        for (size_t i = 0; i < g_root_dict->count; i++) {
            if (g_root_dict->entries[i].key == layout) {
                g_global_table = g_root_dict->entries[i].table;
                break;
            }
        }
    }

    WorkingEntry *entry = find_entry(g_global_table, scancode);
    if (entry && entry->mod_mapping && find_triple(entry->mod_mapping, 1)
        && find_triple(entry->mod_mapping, 1)->anchor == 4) {
        set_pressed(g_mod_buffer, scancode);
        if (!in_allowed(scancode)) { 
            g_last_triple = find_triple(entry->mod_mapping, g_current_mod);
            g_non_sys_mod_cnt++;
        } else {
            g_last_triple = NULL;
        }
        g_current_mod |= 1 << atoi(find_triple(entry->mod_mapping, 1)->text);
        if (g_reset_timer) KillTimer(NULL, g_reset_timer);
        g_reset_timer = SetTimer(NULL, 0, g_timer_ms, reset_base_handler);
        return 1;
    }

    if (g_action_timer) {
        KillTimer(NULL, g_action_timer);
        g_action_timer = 0;
    }

    if (!entry || !entry->mod_mapping || !find_triple(entry->mod_mapping, g_current_mod)) {
        deferred_send_handler(NULL, 0, 0, 0);
        if (g_non_sys_mod_cnt) return 1;
        g_global_table = g_root_dict->entries[0].table;
        entry = find_entry(g_global_table, scancode);
        if (!entry || !entry->mod_mapping || !find_triple(entry->mod_mapping, g_current_mod))
            return 0;
    }

    set_pressed(g_key_buffer, scancode);
    ScancodeMapping *map = entry->mod_mapping;
    Triple *t0 = find_triple(map, g_current_mod);
    Triple *t1 = find_triple(map, g_current_mod + 1);
    g_last_triple = NULL;

    if (t1->anchor == 0) {
        clear_pressed(g_key_buffer, scancode);
        handle_triple(t0);
    } else if (t1->anchor == 5) {
        if (t0 && ((t0->text && t0->text[0] != '\0') || (t0->nested && t0->nested->count > 0))) {
            g_last_triple = t0;
        } else {
            g_last_triple = calloc(1, sizeof(*g_last_triple));
            g_last_triple->anchor = 2;
            char buf[16];
            snprintf(buf, sizeof(buf), "%d", scancode);
            g_last_triple->text = strdup(buf);
            g_last_triple->nested = NULL;
        }
        char *hex = intbuf_to_hex(g_key_buffer, BUFFER_SIZE);
        if (g_global_table && g_global_table->chord_mapping) {
            HexPair *pair = NULL;
            for (size_t i = 0; i < g_global_table->chord_mapping->count; i++) {
                if (strcmp(g_global_table->chord_mapping->pairs[i].key, hex) == 0) {
                    pair = &g_global_table->chord_mapping->pairs[i];
                    break;
                }
            }
            if (pair && pair->mapping && g_current_mod < (int)pair->mapping->count
                && pair->mapping->mapping[g_current_mod]) {
                handle_triple(pair->mapping->mapping[g_current_mod]);
            }
        }
        free(hex);
        if (g_reset_timer) KillTimer(NULL, g_reset_timer);
        g_reset_timer = SetTimer(NULL, 0, g_timer_ms, reset_base_handler);
    } else {
        free(g_waiting);
        g_waiting = calloc(1, sizeof(*g_waiting));
        g_waiting->t0 = t0;
        g_waiting->t1 = t1;
        g_action_timer = SetTimer(NULL, 0, g_timer_ms, action_timer_handler);
    }
    return 1;
}

void key_up_handler(int scancode) {
    if (g_waiting) {
        handle_triple(g_waiting->t0);
        free(g_waiting);
        g_waiting = NULL;
    }
    if (g_last_triple) {
        handle_triple(g_last_triple);
        if (g_reset_timer) {
            KillTimer(NULL, g_reset_timer);
            g_reset_timer = 0;
        }
    }
    if (is_pressed(g_mod_buffer, scancode)) {
        g_current_mod &= ~(1 << atoi(
            find_triple(find_entry(g_global_table, scancode)->mod_mapping, 1)->text));
        clear_pressed(g_mod_buffer, scancode);
        if (!in_allowed(scancode)) g_non_sys_mod_cnt--;
    } else {
        clear_pressed(g_key_buffer, scancode);
    }
}

LRESULT CALLBACK low_level_keyboard_proc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode < 0) return CallNextHookEx(NULL, nCode, wParam, lParam);
    KBDLLHOOKSTRUCT *kbd = (KBDLLHOOKSTRUCT *)lParam;
    if (kbd->flags & LLKHF_INJECTED) return CallNextHookEx(NULL, nCode, wParam, lParam);
    int scancode = kbd->scanCode;
    if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
        if (key_down_handler(scancode) && !in_allowed(scancode)) return 1;
    } else if ((wParam == WM_KEYUP || wParam == WM_SYSKEYUP) && scancode <= 0x00FF) {
        key_up_handler(scancode);
    }
    return CallNextHookEx(NULL, nCode, wParam, lParam);
}