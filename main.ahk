#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "buffer.ahk"
#Include "serializing.ahk"
#Include "structs.ahk"
#Include "config.ahk"
#Include "gui/gui.ahk"
#Include "user_functions.ahk"

skip_once := false
last_val := false
prev_unode := false
current_presses := Buffer(BUFFER_SIZE, 0)  ; scs buffer
pressed_mod_sc := Map()
pressed_mod_val := Map()
up_actions := Map()
current_mod := 0

#Include "keys.ahk"


TimerSendCurrent() {
    ; delayed send for assignments with child transitions, if there are no new presses
    ;   …or for direct call when a new press is not found in the current table / layout has changed
    global curr_unode, prev_unode

    if !last_val || !last_val[1].fin.is_irrevocable {
        curr_unode := ROOTS[CurrentLayout]
    }
    ; mods/chords store the tap value with additional argument
    if last_val && !last_val[2] {  ; skip mod/chord triggers
        SendKbd(last_val[1].fin.down_type, last_val[1].fin.down_val)
        if prev_unode {  ; back from inoperated node
            curr_unode := prev_unode
            prev_unode := false
        }
    }
}


TimerResetBase() {
    ; mods and chords on hold save their tap value to last_val;
    ; if the mod/chord key was released before activation of TimerResetBase
    ;   …or before last_val was overwritten by other press – send the last_val
    global last_val

    last_val := false
}


TransitionProcessing(checked_unode, sc:=0) {
    ; branching, whether we proceed to waiting for a child press or process the current one;
    ; the sc comes from the calls with empty hold assignments
    global curr_unode, last_val, prev_unode

    ; if there are no child assignments – send current and try to reset unode
    if !checked_unode.active_scancodes.Count && !checked_unode.active_chords.Count {
        SendKbd(checked_unode.fin.down_type, checked_unode.fin.down_val)
        if !checked_unode.fin.is_irrevocable && curr_unode !== ROOTS[CurrentLayout] {
            curr_unode := ROOTS[CurrentLayout]
        } else if sc {  ; only if the curr_unode has not been reseted
            ClearBit(sc, current_presses)  ; allow repeat on hold for the corresponding keys
        }
        return
    }

    ; if there are values in the next node – go to it
    if checked_unode.fin.is_instant {
        ; send immediately if so specified. doesn't cancel transitions
        SendKbd(checked_unode.fin.down_type, checked_unode.fin.down_val)
    } else {  ; store current value for processing, if there will not be a child press
        last_val := [checked_unode, false]
    }
    SetTimer(TimerSendCurrent, -(checked_unode.fin.custom_nk_time || CONF.MS_NK))
    prev_unode := current_mod ? curr_unode : false
    curr_unode := checked_unode

    ; transfer the pressed modifiers, if they have the same values
    TransferModifiers()
}


TransferModifiers() {
    global current_mod, pressed_mod_val, pressed_mod_sc

    new_pressed_mod_sc := Map()
    pressed_mod_val := Map()
    current_mod := 0
    for mod_sc, val in pressed_mod_sc {
        res_md := curr_unode.GetModFin(mod_sc)
        if res_md && res_md.down_val == val {
            new_pressed_mod_sc[mod_sc] := val
            pressed_mod_val[val] := pressed_mod_val.Get(val, 0) + 1
            current_mod |= 1 << val
        }
    }
    pressed_mod_sc := new_pressed_mod_sc
}


OnKeyDown(sc, extra_mod:=0) {
    global last_val, current_mod
    static pending := false

    if CheckReturns(sc) {  ; unprocessing conditions
        return
    }

    if pending {
        ; continue the chain of transitions, if the previous unsent push had a table of transitions
        TransitionProcessing(pending)
        pending := false
    }

    CheckLayout()  ; switch to a new root if the layout has changed

    SetTimer(TimerSendCurrent, 0)  ; stop sendtimer, further we control the sending ourselves

    if extra_mod {  ; separately count modifiers from hotkeys with system keys
        current_mod |= extra_mod
    }

    entries := GetEntries(sc)
    if !entries {
        return  ; treated as mod on basehold or no assignments found (send default)
    }

    last_val := false  ; reset last_val and the corresponding timer
    SetTimer(TimerResetBase, 0)

    SetBit(sc, current_presses)  ; store current press for repetition and chord checks

    ; assignment branching; there is at least one after GetEntries and it is not a modifier on hold
    if !entries.uhold || entries.uhold.fin.down_type == TYPES.Disabled
        && !entries.uhold.active_scancodes.Count && !entries.uhold.active_chords.Count {
        TransitionProcessing(entries.ubase, sc)  ; only tap / empty hold
        if entries.ubase.fin.up_type !== TYPES.Disabled {
            up_actions[sc] := entries.ubase.fin
        }
    } else if entries.uhold.fin.down_type == TYPES.Chord {  ; chord part
        res := curr_unode.Get(BufferToHex(current_presses), current_mod, true)
        if res {
            TransitionProcessing(res)  ; chord match
            return
        }
        ; in other case store tap/default value with sc note (can be sent with KeyUp(sc) only)
        if entries.ubase {
            last_val := [entries.ubase, sc]
            if entries.ubase.fin.up_type !== TYPES.Disabled {
                up_actions[sc] := entries.ubase.fin
            }
            SetTimer(TimerResetBase, -(entries.ubase.fin.custom_nk_time || CONF.MS_NK))
        } else {
            last_val := GetDefaultSim(sc, true)
            SetTimer(TimerResetBase, -CONF.MS_NK)
        }
    } else {  ; tap/hold branching
        pending := entries.ubase || GetDefaultSim(sc)[1]
        b := KeyWait(SC_STR[sc],
            (pending.fin.custom_lp_time ? "T" . pending.fin.custom_lp_time / 1000 : CONF.T))
        if pending {  ; pending may be reset by any other press while we perform KeyWait
            res_unode := b ? pending : entries.uhold
            TransitionProcessing(res_unode)
            if res_unode.fin.up_type !== TYPES.Disabled {
                up_actions[sc] := res_unode.fin
            }
        }
        pending := false
    }
}


CheckReturns(sc) {
    global skip_once

    ; deny repetition via holding (conflicts with hold catching)
    if CheckBit(sc, current_presses) || pressed_mod_sc.Has(sc) {
        return true
    }

    ; if the focus is on GUI – process separately
    if UI.Hwnd && (WinActive("A") == UI.Hwnd) {
        SetBit(sc, current_presses)
        HandleKeyPress(sc)  ; gui func
        return true
    } else if s_gui && s_gui.Hwnd && (WinActive("A") == s_gui.Hwnd) && PasteSCToInput(sc) {
        SetBit(sc, current_presses)
        return true
    }

    ; skip the single system modifier
    if SYS_MODIFIERS.Has(sc) {
        return true
    }

    ; triggered when the key was held with a modifier, but the modifier was released first
    ; prevents new sends after mod release
    if skip_once {
        SetBit(sc, current_presses)
        skip_once := false
        return true
    }
    return false
}


CheckLayout() {
    global CurrentLayout, curr_unode, current_mod, pressed_mod_sc, pressed_mod_val

    layout := GetCurrentLayout()
    if layout == CurrentLayout {
        return
    }

    ; force sending the last stored value and reset curr_unode to the root by the new layout
    TimerSendCurrent()
    CurrentLayout := layout
    curr_unode := ROOTS[CurrentLayout]

    ; reset all modifiers
    current_mod := 0
    pressed_mod_sc := Map()
    pressed_mod_val := Map()
}


GetEntries(sc) {
    global curr_unode

    entries := curr_unode.GetBaseHoldMod(sc, current_mod, false, true)

    if TreatMod(entries, sc) {
        return false
    }

    if entries.ubase || entries.uhold {
        return entries  ; has at least one assignment; there's a point in further processing
    }

    ; if the scancode or both modifiers (base/hold) are missing in the current node
    b := curr_unode == ROOTS[CurrentLayout]  ; save the 'node is root' check
    TimerSendCurrent()  ; …and force sending previous value

    if current_mod {  ; ignore current press if it with active modifier
        return false
    }

    curr_unode := ROOTS[CurrentLayout]  ; for sure

    ; if the curr_unode has not changed, just send the native press
    if b {
        SendKbd(TYPES.Default, "{Blind}" . SC_STR_BR[sc])
        return false
    }

    return GetEntries(sc)  ; …else repeat the checks with changed curr_unode
    ; it's definitely over by the second lap
}


TreatMod(entries, sc) {
    global last_val, current_mod, pressed_mod_sc, pressed_mod_val

    if entries.uhold {
        if entries.uhold.fin.down_type !== TYPES.Modifier {
            return false
        }
        val := entries.uhold.fin.down_val
    } else if !entries.umod {
        return false
    } else {
        val := entries.umod.fin.down_val
    }

    last_val := entries.ubase ? [entries.ubase, sc] : GetDefaultSim(sc, true)

    ; store count of pressed keys with the same mod values
    ; this will allow us to avoid reseting the modval on the first release
    pressed_mod_val[val] := pressed_mod_val.Get(val, 0) + 1
    pressed_mod_sc[sc] := val  ; store the value only for checking when changing the node
    current_mod |= 1 << val
    SetTimer(TimerResetBase, -(last_val[1].fin.custom_nk_time || CONF.MS_NK))
    return true
}


GetDefaultSim(sc, extended:=false) {
    return [
        {
            scancodes: Map(), chords: Map(), active_scancodes: Map(), active_chords: Map(),
            fin: GetDefaultNode(sc, current_mod)},
        extended ? sc : false
    ]
}


OnKeyUp(sc, extra_mod:=0) {
    global curr_unode, current_mod, skip_once, pressed_mod_sc, pressed_mod_val

    if extra_mod {  ; separately count modifiers from hotkeys with system keys
        current_mod &= ~extra_mod
    }

    if up_actions.Has(sc) {
        SendKbd(up_actions[sc].up_type, up_actions[sc].up_val)
        up_actions.Delete(sc)
    }

    if pressed_mod_sc.Has(sc) {  ; release mod
        ; decrease corresponding values
        val := curr_unode.GetModFin(sc).down_val
        if pressed_mod_val[val] == 1 {
            current_mod &= ~(1 << val)
            pressed_mod_val.Delete(val)
        } else {
            pressed_mod_val[val] -= 1
        }
        pressed_mod_sc.Delete(sc)
        ; there are no more modifiers ? reset the node to the root
        if !current_mod && curr_unode !== ROOTS[CurrentLayout] {
            curr_unode := ROOTS[CurrentLayout]
        }
    } else if CheckBit(sc, current_presses) {  ; release regular key
        ClearBit(sc, current_presses)
    } else if SYS_MODIFIERS.Has(sc) {  ; release sysmod
        md := curr_unode.GetModFin(sc)
        if md {
            b := 1 << md.down_val
            if current_mod & b == b {
                current_mod &= ~b
                skip_once := true  ; deny sending a held key when the mod is released before it
            }
        }
    }

    ; deny last_val processing from other keys, when last_val get from mod/chord base
    if last_val && (!last_val[2] || last_val[2] == sc) {
        TransitionProcessing(last_val[1])
        SetTimer(TimerResetBase, 0)
    }
}


SendKbd(action_type, action_val) {
    global last_val

    last_val := false

    switch action_type {
        case TYPES.Text:
            SendText(action_val)
        case TYPES.Default, TYPES.KeySimulation:
            SendInput(action_val)
        case TYPES.Function:
            if !RegExMatch(action_val, "^(?<name>\w+)(?:\((?<args>.*)\))?$", &m) {
                throw Error("Wrong function value: " . action_val)
            }
            args := _ParseFuncArgs(m["args"])
            %m["name"]%.Call(args*)
    }
}


TreatAsOtherNode(path) {  ; custom func
    if !path || !path.Length {
        return
    }
    if path[1] is Integer {
        path := [path]
    }

    start_unode := ROOTS[CurrentLayout]
    for arr in path {
        len := arr.Length
        start_unode := start_unode.Get(arr[1], len > 1 ? arr[2] : 0, len > 2 ? arr[3] : 0)
        if !start_unode {
            return  ; wrong path
        }
    }

    TransitionProcessing(start_unode)
}