﻿#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "config.ahk"
#Include "buffer.ahk"
#Include "serializing.ahk"
#Include "utils.ahk"
#Include "gui.ahk"
#Include "user_functions.ahk"

last_val := false
current_presses := Buffer(64, 0)  ; bitbuffer
current_presses_mods := Buffer(64, 0)
current_mod := 0


TimerSendCurrent() {
    global glob, last_val

    if last_val {
        SendKbd(last_val)
    }

    if !current_mod {
        glob := KEYS[CURRENT_LANG]
    }
    last_val := false
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
        SendKbd(arr)
        if !current_mod {
            glob := KEYS[CURRENT_LANG]
        }
        last_val := false
    }
}


OnKeyDown(sc, extra_mod:=0) {
    global glob, last_val, current_mod, CURRENT_LANG
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

    if extra_mod {
        current_mod |= extra_mod
    }

    lang := GetCurrentLayout()
    if lang != CURRENT_LANG {
        TimerSendCurrent()
        CURRENT_LANG := lang
        glob := KEYS[CURRENT_LANG]
    }

    if glob.Has(sc) && glob[sc].Has(1) && glob[sc][1][1] == 4 {  ; modifier on basehold
        last_val := glob[sc].Has(current_mod) ? glob[sc][current_mod] : false
        SetBit(sc, current_presses_mods)
        current_mod |= 1 << glob[sc][1][2]
        SetTimer(TimerResetBase, -MS)
        return
    }

    ; save current press for further CheckBit and chord checking
    SetBit(sc, current_presses)

    SetTimer(TimerSendCurrent, 0)

    ; continue the chain of transitions, if the previous unsent push had a table of transitions
    if waiting {
        last_val := waiting
        glob := waiting[3]
        waiting := false
    }

    if last_val && current_mod {  ; ?
        last_val := false
    }

    ; if the scancode is missing in the current transition table
    if !glob.Has(sc) {
        ; force the sending of the last_val
        TimerSendCurrent()

        ; ignore press if it with active modifier
        if current_mod {
            return
        }

        ; in other case back to root table and continue processing
        glob := KEYS[CURRENT_LANG]

        ; if sc is missing even in the root table, send default value and break processing
        if !glob.Has(sc) {
            SendKbd([2, sc])
            ClearBit(sc, current_presses)
            return
        }
    }

    ;same for modifiers level
    if !glob[sc].Has(current_mod) {
        TimerSendCurrent()
        if current_mod {
            return
        }
        glob := KEYS[CURRENT_LANG]
        if !glob[sc].Has(current_mod) {
            SendKbd([2, sc])
            ClearBit(sc, current_presses)
            return
        }
    }

    ; main path
    key_base := glob[sc][current_mod]
    key_hold := glob[sc][current_mod + 1]
    last_val := false

    ; cases by holdpress type
    switch key_hold[1] {
        case 0:  ; empty / unset
            ; immediately process base press and reset its press count
            GlobProc(key_base)
            ClearBit(sc, current_presses)

        case 1, 2, 3:  ; any value to sending/processing (with or without transition table)
            ; set base press value to waiting
            waiting := key_base
            ;ClearBit(sc, current_presses)  ; TODO!
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
            last_val := key_base
            b := true
            try {
                temp_current_presses := CopyBuffer(current_presses)
                RemoveBits(temp_current_presses, [current_presses_mods])
                current_hex := BufferToHex(temp_current_presses)
                if glob[-1].Has(current_hex) && glob[-1][current_hex].Has(current_mod) {
                    GlobProc(glob[-1][current_hex][current_mod])
                    ;b := false  ; TODO !!
                }
            } catch {  ; TODO
                msgbox("alarma")
            }

            if b {
                SetTimer(TimerResetBase, -MS)
            } else {
                TimerResetBase()
            }
    }
}


OnKeyUp(sc, extra_mod:=0) {
    global current_mod

    if extra_mod {
        current_mod &= ~extra_mod
    }

    if CheckBit(sc, current_presses_mods) {
        current_mod &= ~(1 << glob[sc][1][2])
        ClearBit(sc, current_presses_mods)
    } else if CheckBit(sc, current_presses) {
        ClearBit(sc, current_presses)
    }

    if last_val {
        GlobProc(last_val)
        SetTimer(TimerResetBase, 0)
    }
}


SendKbd(arr) {
    switch arr[1] {
        case 1:
            SendInput(arr[2])
        case 2:
            SendInput("{" . SC_STR[arr[2]] . "}")  ; TODO
            ;DllCall("keybd_event", "UInt", GetKeyVK(SC_STR[arr[2]]), "UInt", 0, "UInt", 0, "UPtr", 0)
        case 3:
            if !RegExMatch(arr[2], "^(?<name>\w+)(?:\((?<args>.*)\))?$", &m) {
                throw Error("Wrong function value: " . arr[2])
            }

            raw_args := Trim(m["args"])
            %m["name"]%.Call(raw_args == "" ? [] : StrSplit(raw_args, ",", " `t"))
    }
}


#Include "keys.ahk"