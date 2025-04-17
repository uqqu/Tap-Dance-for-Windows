#include "keyboard_hook.h"
#include "keybuffer.h"
#include "json_parser.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Global state */
RootDict     *g_root_dict      = NULL;
WorkingTable *g_global_table   = NULL;
Waiting      *g_waiting        = NULL;
Triple       *g_last_triple    = NULL;
UINT_PTR      g_action_timer   = 0;
UINT_PTR      g_reset_timer    = 0;
UINT_PTR      g_send_timer     = 0;
int           g_current_mod    = 0;
int           g_non_sys_mod_cnt = 0;
int           g_timer_ms       = 120;
int           g_current_layout = 0;


static void send_text_as_unicode(const char *utf8) {
    int wlen = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
    if (wlen <= 0) return;
    wchar_t *w = malloc(wlen * sizeof(wchar_t));
    if (!w) return;
    MultiByteToWideChar(CP_UTF8, 0, utf8, -1, w, wlen);
    size_t len = wlen - 1;
    INPUT *inp = calloc(2 * len, sizeof(INPUT));
    if (!inp) { free(w); return; }
    for (size_t i = 0; i < len; i++) {
        inp[2*i].type = INPUT_KEYBOARD;
        inp[2*i].ki.wScan = w[i];
        inp[2*i].ki.dwFlags = KEYEVENTF_UNICODE;
        inp[2*i+1].type = INPUT_KEYBOARD;
        inp[2*i+1].ki.wScan = w[i];
        inp[2*i+1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    }
    SendInput((UINT)(2 * len), inp, sizeof(INPUT));
    free(inp);
    free(w);
}

static WORD vk_for_modifier(char c) {
    switch(c) {
    case '^': return VK_CONTROL;
    case '+': return VK_SHIFT;
    case '!': return VK_MENU;
    case '#': return VK_LWIN;
    default:  return 0;
    }
}

static void send_scancode_combo(const char *s) {
    WORD mods[4];
    int  mod_cnt = 0;
    while (*s && strchr("^+!#", *s)) {
        WORD vk = vk_for_modifier(*s++);
        if (vk && mod_cnt < 4) {
            mods[mod_cnt++] = vk;
        }
    }

    int raw = -1;
    if (*s == '{' && tolower(s[1]) == 's' && tolower(s[2]) == 'c') {
        raw = atoi(s + 3);
    } else {
        raw = atoi(s);
    }
    if (raw <= 0)
        return;

    BOOL extended = (raw & 0x100) != 0;
    WORD sc = (WORD)(raw & 0xFF);

    // mod down
    for (int i = 0; i < mod_cnt; i++) {
        INPUT ip = { .type = INPUT_KEYBOARD };
        ip.ki.wVk = mods[i];
        ip.ki.dwFlags = 0;
        SendInput(1, &ip, sizeof(ip));
    }

    DWORD flags = KEYEVENTF_SCANCODE | (extended ? KEYEVENTF_EXTENDEDKEY : 0);

    // sc down
    {
        INPUT ip = { .type = INPUT_KEYBOARD };
        ip.ki.wScan = sc;
        ip.ki.dwFlags = flags;
        SendInput(1, &ip, sizeof(ip));
    }
    // sc up
    {
        INPUT ip = { .type = INPUT_KEYBOARD };
        ip.ki.wScan = sc;
        ip.ki.dwFlags = flags | KEYEVENTF_KEYUP;
        SendInput(1, &ip, sizeof(ip));
    }

    // mod up
    for (int i = mod_cnt - 1; i >= 0; i--) {
        INPUT ip = { .type = INPUT_KEYBOARD };
        ip.ki.wVk = mods[i];
        ip.ki.dwFlags = KEYEVENTF_KEYUP;
        SendInput(1, &ip, sizeof(ip));
    }
}

void send_value(Triple *tr) {
    if (!tr || !tr->text || tr->text[0] == '\0') return;
    if (tr->anchor == 1) {
        send_text_as_unicode(tr->text);
    } else if (tr->anchor == 2) {
        send_scancode_combo(tr->text);
    }
}

int main(void) {
    init_scancode_mask();
    g_current_layout = (int)(INT_PTR)GetKeyboardLayout(0);
    g_root_dict = load_root_dict("c_test.json");
    if (!g_root_dict) {
        fprintf(stderr, "Failed to load JSON dictionary\n");
        return EXIT_FAILURE;
    }
    for (size_t i = 0; i < g_root_dict->count; i++) {
        if (g_root_dict->entries[i].key == g_current_layout) {
            g_global_table = g_root_dict->entries[i].table;
            break;
        }
    }
    HHOOK hook = SetWindowsHookEx(WH_KEYBOARD_LL, low_level_keyboard_proc, NULL, 0);
    if (!hook) {
        fprintf(stderr, "Hook installation failed\n");
        return EXIT_FAILURE;
    }
    printf("Keyboard hook installed. Press keys...\n");
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    UnhookWindowsHookEx(hook);
    return EXIT_SUCCESS;
}
