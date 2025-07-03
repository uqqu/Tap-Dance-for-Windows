#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "serializing.ahk"
#Include "structs.ahk"
#Include "config.ahk"
#Include "gui/gui.ahk"
#Include "user_functions.ahk"

last_val := false  ; unsended value while we wait nested event (if the timer expires/interrupted)
pending := false  ; tap value of assignment, while we wait if the hold will be confirmed
interrupted_kw := false  ; strange case – unassigned event with existing pending mimics it in kw oO
delayed := false
prev_unode := false
catched_entries := false
catched_gui_func := false
current_presses := Map()
up_actions := Map()
ResetModifiers()

#Include "keys.ahk"
SetSysModHotkeys()


TimerSendCurrent() {
    ; delayed send for assignments with child transitions, if there are no new presses
    ;   …or for direct call when a new press is not found in the current table / layout has changed

    SetTimer(TimerSendCurrent, 0)
    if !last_val || !last_val[1].fin.is_irrevocable {
        ToRoot()
    }
    ; mods/chords store the tap value with additional argument
    if last_val && !last_val[2] {  ; skip mod/chord triggers
        SendKbd(last_val[1].fin.down_type, last_val[1].fin.down_val)
    }
}


TimerResetBase() {
    ; mods and chords on hold save their tap value to last_val;
    ; if the mod/chord key was released before activation of TimerResetBase
    ;   …or before last_val was overwritten by other press – send the last_val
    global last_val, prev_unode

    last_val := false
    prev_unode := false
}


TransitionProcessing(checked_unode, sc:=0) {
    ; branching, whether we proceed to waiting for a child press or process the current one;
    ; the sc comes from the calls with empty hold assignments
    global curr_unode, last_val, prev_unode

    ; if there are no child assignments – send current and try to reset unode
    if !checked_unode.active_scancodes.Count && !checked_unode.active_chords.Count {
        SendKbd(checked_unode.fin.down_type, checked_unode.fin.down_val)
        if !checked_unode.fin.is_irrevocable && curr_unode !== ROOTS[CurrentLayout] {
            ToRoot()
        } else if sc {  ; only if the curr_unode has not been reseted
            if sc !== "WheelLeft" && sc !== "WheelRight" {
                try current_presses.Delete(sc)  ; allow repeat on hold for the corresponding keys
            }
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
    if curr_unode !== checked_unode {
        prev_unode := curr_unode
        curr_unode := checked_unode
    }

    ; transfer the pressed modifiers, if they have the same values
    TransferModifiers()
}


TransferModifiers(extra_mod:=0) {
    global current_mod

    current_mod := extra_mod
    for sc in current_presses {
        res_md := curr_unode.GetModFin(sc)
        if res_md {
            current_mod |= 1 << res_md.down_val
        }
    }
}


UnlockWhL() {
    OnKeyUp("WheelLeft")
}

UnlockWhR() {
    OnKeyUp("WheelRight")
}


PreCheck(sc, *) {
    ;; determine whether we will intercept the event or allow it to be executed natively
    ;;  …with accompanying logic operations (in fact, everything except
    ;;  …the final processing of the found assignment)
    global catched_entries, pending, delayed, interrupted_kw

    if !(sc is Number) {
        ; simulate wheel l/r up action manually
        if sc == "WheelLeft" {
            SetTimer(UnlockWhL, -CONF.wheel_unlock_time)
        } else if sc == "WheelRight" {
            SetTimer(UnlockWhR, -CONF.wheel_unlock_time)
        }
    }

    ;; unprocessing conditions
    ; deny repetition via holding (conflicts with hold catching)
    if current_presses.Has(sc) {
        return true
    }

    if GuiCheck(sc) {
        return true
    }

    ; continue the chain of transitions, if the previous unsent push had a table of transitions
    ; case: {a down (with hold assignment)}[keywait start]{b down}
    if pending {
        SetTimer(TransitionProcessing.Bind(pending), -1)  ; SetTimer allow use Send "inside" HotIf
        delayed := true  ; …but we must approve that next send will be sent after current
        pending := false
    }

    CheckLayout()  ; switch to a new root if the layout has changed

    entries := GetEntries(sc)
    if entries == 0 {  ; no assignments found
        if !delayed {  ; allow native press in the base case
            return false
        }
        ; else (if there are cross sends) follow the send order with default simulation
        TransitionProcessing(GetDefaultSim(sc)[1])
        interrupted_kw := true
        return true
    } else if entries == 1 {  ; processed as mod/basemod or blocked by conf.unassigned
        return true
    }
    ; else catched_entries is obj
    catched_entries := entries  ; memorize for main func; cannot be performed now due to keywait
    return true
}


GetEntries(sc, extra_mod:=0) {
    global delayed

    SetTimer(TimerSendCurrent, 0)
    entries := curr_unode.GetBaseHoldMod(sc, current_mod, false, true)

    if TreatMod(entries, sc) {
        current_presses[sc] := true
        return 1
    }

    if entries.ubase || entries.uhold {  ; TODO umod?
        return entries  ; has at least one assignment; there's a point in further processing
    }

    ;; if the scancode or both events (base/hold [+mod]) are missing in the current node

    is_root := curr_unode == ROOTS[CurrentLayout]

    for conditions in [
        [current_mod, CONF.unassigned_under_mods], [!is_root, CONF.unassigned_non_root]] {
        if conditions[1] {
            if conditions[2] == 5 {  ; block unassigned
                return 1  ; do nothing else
            } else if prev_unode && conditions[2] == 1 {  ; backsearch
                StepBack(extra_mod)
                return GetEntries(sc)  ; repeat scmod check from previous step
            } else if prev_unode && conditions[2] == 2 {  ; send + backsearch
                if last_val {
                    delayed := true
                    SendKbd(last_val[1].fin.down_type, last_val[1].fin.down_val)
                }
                StepBack(extra_mod)
                return GetEntries(sc)
            } else if !is_root {
                if conditions[2] == 4 && last_val {  ; force sending stored value
                    delayed := true
                    SendKbd(last_val[1].fin.down_type, last_val[1].fin.down_val)
                }
                ToRoot(extra_mod)
                return GetEntries(sc)
            }
        }
    }

    ;; root reached, not assigned, not blocked, not found on the prev node/root (if configured so)

    ; to prevent the native press from being sent earlier than previous simulated. rare case
    if last_val {
        delayed := true
        SendKbd(TYPES.KeySimulation, SC_STR_BR[sc])
        return 1
    }
    return 0
}


TreatMod(entries, sc) {
    global last_val, current_mod

    ; if there is an assignment for hold, it has higher priority than basemod (1)
    ; without `current_mod` – umod is uhold, so this is only for assignments under mods
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

    ; mods and chord_parts are stored with their scs to indicate that the assignment will
    ; …only triggered from its own event (without execution from cross-presses)
    last_val := entries.ubase ? [entries.ubase, sc] : GetDefaultSim(sc, true)

    current_mod |= 1 << val
    SetTimer(TimerResetBase, -(last_val[1].fin.custom_nk_time || CONF.MS_NK))
    return true
}


StepBack(extra_mod:=0) {
    global curr_unode, prev_unode

    if prev_unode {
        curr_unode := prev_unode
        prev_unode := false
        TransferModifiers(extra_mod)
    } else {
        ToRoot(extra_mod)
    }
}


ToRoot(extra_mod:=0) {
    global curr_unode, prev_unode

    curr_unode := ROOTS[CurrentLayout]
    prev_unode := false
    TransferModifiers(extra_mod)
}


SysModComboDown(sc, extra_mod) {
    global current_mod, catched_entries

    if current_presses.Has(sc) {
        return
    }

    current_mod |= extra_mod
    catched_entries := GetEntries(sc, extra_mod)
    OnKeyDown(sc)
}


OnKeyDown(sc) {
    global last_val, pending, catched_entries, catched_gui_func, delayed, interrupted_kw

    if catched_gui_func {
        if sc !== "WheelDown" && sc !== "WheelUp" {
            current_presses[sc] := true
        }
        catched_gui_func := false
        HandleKeyPress(sc)
        return
    }

    if !catched_entries {
        return
    }

    TimerResetBase()
    SetTimer(TimerResetBase, 0)

    if !interrupted_kw {
        current_presses[sc] := true  ; store current press for repetition and chord checks
    }

    ; only tap assigned or insignificant hold
    if !catched_entries.uhold || catched_entries.uhold.fin.down_type == TYPES.Disabled
        && !catched_entries.uhold.active_scancodes.Count
        && !catched_entries.uhold.active_chords.Count {
        TransitionProcessing(catched_entries.ubase, sc)
        if catched_entries.ubase.fin.up_type !== TYPES.Disabled {
            up_actions[sc] := catched_entries.ubase.fin
        }

    ; chord part
    } else if catched_entries.uhold.fin.down_type == TYPES.Chord {
        res := curr_unode.Get(ChordToStr(current_presses), current_mod, true)
        if res {  ; chord matched!
            TransitionProcessing(res)
            catched_entries := false
            return
        }
        ; in other case store tap/default value with sc note
        ; …(can be sent with corresponding KeyUp(sc) only)
        if catched_entries.ubase {
            last_val := [catched_entries.ubase, sc]
            if catched_entries.ubase.fin.up_type !== TYPES.Disabled {
                up_actions[sc] := catched_entries.ubase.fin
            }
            SetTimer(TimerResetBase, -(catched_entries.ubase.fin.custom_nk_time || CONF.MS_NK))
        } else {
            last_val := GetDefaultSim(sc, true)
            SetTimer(TimerResetBase, -CONF.MS_NK)
        }

    ; full-fledged tap/hold
    } else {
        ; store base value for the case if KeyWait will be interrupted
        pending := catched_entries.ubase || GetDefaultSim(sc)[1]
        is_hold := KeyWait(SC_STR[sc],
            (pending.fin.custom_lp_time ? "T" . pending.fin.custom_lp_time / 1000 : CONF.T))
        ; determine tap/hold and than recheck pending that may be reset by other presses during KW
        if pending && !delayed {
            if interrupted_kw {
                interrupted_kw := false
                pending := false
                return
            }
            res_unode := is_hold ? pending : catched_entries.uhold
            TransitionProcessing(res_unode)
            if res_unode.fin.up_type !== TYPES.Disabled {
                up_actions[sc] := res_unode.fin
            }
            pending := false
        }
    }
    catched_entries := false
}


CheckLayout() {
    global CurrentLayout

    layout := GetCurrentLayout()
    if layout == CurrentLayout {
        return
    }

    ; force sending the last stored value and reset curr_unode to the root by the new layout
    TimerSendCurrent()
    CurrentLayout := layout
    ToRoot()
}


ResetModifiers() {
    global current_mod

    current_mod := 0
}


GetDefaultSim(sc, extended:=false) {
    return [
        {
            scancodes: Map(), chords: Map(),
            active_scancodes: Map(), active_chords: Map(),
            fin: GetDefaultNode(sc, current_mod)
        },
        extended ? sc : false
    ]
}


OnKeyUp(sc, extra_mod:=0) {
    global current_mod

    if extra_mod {  ; separately count modifiers from hotkeys with system keys
        current_mod &= ~extra_mod
    }

    if up_actions.Has(sc) {
        SendKbd(up_actions[sc].up_type, up_actions[sc].up_val)
        up_actions.Delete(sc)
    }

    try current_presses.Delete(sc)
    md := curr_unode.GetModFin(sc)
    if md {  ; release mod
        current_mod &= ~(1 << md.down_val)
        ; there are no more modifiers ? reset the node to the root
        if !current_mod && curr_unode !== ROOTS[CurrentLayout] {
            ToRoot()
        }
    }

    if last_val && prev_unode {  ; same for previous level if exists
        md := prev_unode.GetModFin(sc)
        if md {
            current_mod &= ~(1 << md.down_val)
            TimerSendCurrent()
            if !current_mod && curr_unode !== ROOTS[CurrentLayout] {
                ToRoot()
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
    global last_val, delayed

    last_val := false

    switch action_type {
        case TYPES.Text:
            if delayed {
                SetTimer(SendText.Bind(action_val), -1)
                delayed := false
            } else {
                SendText(action_val)
            }
        case TYPES.Default, TYPES.KeySimulation:
            if delayed {
                SetTimer(SendInput.Bind(action_val), -1)
                delayed := false
            } else {
                SendInput(action_val)
            }
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