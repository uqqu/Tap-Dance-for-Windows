#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "config.ahk"
#Include "buffer.ahk"
#Include "serializing.ahk"
#Include "utils.ahk"
#Include "gui.ahk"
#Include "user_functions.ahk"

skip_once := false
last_val := false
current_presses := Buffer(BUFFER_SIZE, 0)  ; bitbuffer
current_presses_mods := Buffer(BUFFER_SIZE, 0)
current_mod := 0


TimerSendCurrent() {
    global glob, last_val

    if !current_mod {
        glob := KEYS[CURRENT_LANG]
    }

    if last_val {
        SendKbd(last_val)
    }
}


TimerResetBase() {
    global last_val
    last_val := false
}


GlobProc(arr) {
    global glob, last_val

    if arr[3].Count {  ; if has next_table
        last_val := arr
        glob := arr[3]
        SetTimer(TimerSendCurrent, -MS)
    } else {
        if !current_mod {
            glob := KEYS[CURRENT_LANG]
        }
        SendKbd(arr)
    }
}


OnKeyDown(sc, extra_mod:=0) {
    global glob, last_val, current_mod, skip_once, CURRENT_LANG
    static waiting := false

    ; deny repetition via holding (conflicts with hold catching)
    if CheckBit(sc, current_presses) || CheckBit(sc, current_presses_mods) {
        return
    }

    if !is_gui_closed && WinActive("A") == keyboard_gui.Hwnd {
        SetBit(sc, current_presses)
        HandleKeyPress(sc)
        return
    }

    if SYS_MODIFIERS.Has(sc) {
        return
    }

    if skip_once {
        skip_once := false
        SetBit(sc, current_presses)
        return
    }

    ; continue the chain of transitions, if the previous unsent push had a table of transitions
    if waiting {
        GlobProc(waiting)
        waiting := false
    }

    lang := GetCurrentLayout()
    if lang != CURRENT_LANG {
        TimerSendCurrent()
        CURRENT_LANG := lang
        current_mod := 0
        current_presses_mods.__New(BUFFER_SIZE, 0)
        glob := KEYS[CURRENT_LANG]
    }

    if extra_mod {
        current_mod |= extra_mod
    }

    entry := glob.Get(sc, false)
    if CheckMod(entry, sc) {  ; modifier on basehold
        return
    }

    SetTimer(TimerSendCurrent, 0)

    ; if the scancode or modifier is missing in the current transition table
    if (!entry || !entry.Has(current_mod)) {
        ; force the sending of the last_val
        TimerSendCurrent()

        ; ignore press if it with active modifier
        if current_mod {
            return
        }

        if ObjPtr(glob) != ObjPtr(KEYS[CURRENT_LANG]) {
            ; in other case back to root table and continue processing
            glob := KEYS[CURRENT_LANG]
            entry := glob.Get(sc, false)

            if CheckMod(entry, sc) {
                return
            }
            ; if sc is missing even in the root table, send default value and break processing
            if (!entry || !entry.Has(current_mod)) {
                SendKbd(GetCachedDefault(sc))
                return
            }
        } else {
            SendKbd(GetCachedDefault(sc))
            return
        }
    }


    ; main path
    key_base := entry[current_mod]
    key_hold := entry[current_mod + 1]
    last_val := false

    ; cases by holdpress type
    switch key_hold[1] {
        case 0:  ; empty / unset
            ; immediately process base press and reset its press count
            GlobProc(key_base)

        case 1, 2, 3:  ; any value to sending/processing (with or without transition table)
            SetBit(sc, current_presses)
            ; set base press value to waiting
            waiting := key_base
            if KeyWait(SC_STR[sc], T) {
                if waiting {  ; might change while we wait
                    GlobProc(key_base)
                }
            } else {
                if waiting {
                    GlobProc(key_hold)
                }
            }
            waiting := false

        case 5:  ; chord part
            SetBit(sc, current_presses)
            current_hex := BufferToHex(current_presses)

            if glob[-1].Has(current_hex) && glob[-1][current_hex].Has(current_mod) {
                GlobProc(glob[-1][current_hex][current_mod])
                SetTimer(TimerResetBase, 0)
            } else {
                last_val := (key_base && (key_base[2] != "" || key_base[3].Count))
                    ? key_base : GetCachedDefault(sc)
                SetTimer(TimerResetBase, -MS)
            }
    }
}


OnKeyUp(sc, extra_mod:=0) {
    global glob, current_mod, skip_once

    if extra_mod {
        current_mod &= ~extra_mod
    }

    if CheckBit(sc, current_presses_mods) {
        try {
            current_mod &= ~(1 << glob[sc][1][2])
        } catch {
            current_mod := 0
            current_presses_mods.__New(BUFFER_SIZE, 0)
        }
        if !current_mod {
            glob := KEYS[CURRENT_LANG]
        }
        ClearBit(sc, current_presses_mods)
    } else if CheckBit(sc, current_presses) {
        ClearBit(sc, current_presses)
    } else if SYS_MODIFIERS.Has(sc) && glob.Has(sc) && glob[sc].Has(1) && glob[sc][1][1] == 4 {
        b := 1 << glob[sc][1][2]
        if current_mod & b == b {
            current_mod &= ~b
            skip_once := true  ; deny sending a held key when the modifier is released before it
        }
    }

    if last_val {
        GlobProc(last_val)
        SetTimer(TimerResetBase, 0)
    }
}


SendKbd(arr) {
    global last_val
    last_val := false

    switch arr[1] {
        case 1:
            SendText(arr[2])
        case 2:
            SendInput(arr[2])
        case 3:
            if !RegExMatch(arr[2], "^(?<name>\w+)(?:\((?<args>.*)\))?$", &m) {
                throw Error("Wrong function value: " . arr[2])
            }

            raw_args := Trim(m["args"])
            %m["name"]%.Call(raw_args == "" ? [] : StrSplit(raw_args, ",", " `t"))
    }
}


CheckMod(entry, sc) {
    global last_val, current_mod
    if entry && entry.Has(1) && entry[1][1] == 4 {
        last_val := entry.Has(current_mod) ? entry[current_mod] : GetCachedDefault(sc)
        SetBit(sc, current_presses_mods)
        current_mod |= 1 << entry[1][2]
        SetTimer(TimerResetBase, -MS)
        SetTimer(TimerSendCurrent, 0)
        return true
    }
    return false
}


GetCachedDefault(sc) {
    static cached := Map()

    try {
        return cached[sc]
    } catch {
        cached[sc] := [2, "{Blind}" . SC_STR_BR[sc], Map()]
        return cached[sc]
    }
}


#Include "keys.ahk"