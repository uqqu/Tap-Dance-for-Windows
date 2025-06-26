mouse_buttons := [
    "LButton", "RButton", "MButton", "XButton1", "XButton2",
    "WheelUp", "WheelDown", "WheelLeft", "WheelRight"
]

MOUSE_SCS := Map()
MOUSE_SCS_R := Map()
for key in empty_scs {
    SC_STR[key] := mouse_buttons[A_Index]
    MOUSE_SCS[mouse_buttons[A_Index]] := key
    MOUSE_SCS_R[key] := mouse_buttons[A_Index]
    if A_Index == 9 {
        break
    }
}

for sc in ALL_SCANCODES {
    if !(sc is Number) {
        if sc == "LButton" || sc == "RButton" {
            HotIf CheckMSC.Bind(sc)
                Hotkey(sc, ((sc) => (*) => OnKeyDown(sc))(sc))
                Hotkey(sc . " up", ((sc) => (*) => OnKeyUp(sc))(sc))
        } else {
            HotIf CheckSC.Bind(sc)
                Hotkey(sc, ((sc) => (*) => OnKeyDown(sc))(sc))
                Hotkey(sc . " up", ((sc) => (*) => OnKeyUp(sc))(sc))
        }
    } else if !SYS_MODIFIERS.Has(sc) {
        HotIf CheckSC.Bind(sc)
            Hotkey(SC_STR[sc], ((sc) => (*) => OnKeyDown(sc))(sc))
            Hotkey(SC_STR[sc] . " up", ((sc) => (*) => OnKeyUp(sc))(sc))
    } else {
        HotIf CheckSysSC.Bind(sc)
            Hotkey("~" . SC_STR[sc], ((sc) => (*) => OnKeyDown(sc))(sc))
            Hotkey("~" . SC_STR[sc] . " up", ((sc) => (*) => OnKeyUp(sc))(sc))
    }
}
HotIf


CheckSysSC(sc, *) {
    if (UI.Hwnd && (WinActive("A") == UI.Hwnd))
        || (s_gui && s_gui.Hwnd && (WinActive("A") == s_gui.Hwnd) && PasteSCToInput(sc)) {
        return true
    }
    return false
}


CheckSC(sc, *) {
    entries := curr_unode.GetBaseHoldMod(sc, current_mod, false, true)
    if last_val
        || (entries.ubase || entries.uhold || entries.umod)
        || (UI.Hwnd && (WinActive("A") == UI.Hwnd))
        || (s_gui && s_gui.Hwnd && (WinActive("A") == s_gui.Hwnd) && PasteSCToInput(sc)) {
        return true
    }

    entries := ROOTS[CurrentLayout].GetBaseHoldMod(sc, current_mod, false, true)
    if entries.ubase || entries.uhold || entries.umod {
        return true
    }

    return false
}


CheckMSC(sc, *) {
    entries := curr_unode.GetBaseHoldMod(sc, current_mod, false, true)
    if (last_val || entries.ubase || entries.uhold || entries.umod)
        && !(UI.Hwnd && (WinActive("A") == UI.Hwnd))
        && !(s_gui && s_gui.Hwnd && (WinActive("A") == s_gui.Hwnd)) {
        return true
    }

    entries := ROOTS[CurrentLayout].GetBaseHoldMod(sc, current_mod, false, true)
    if entries.ubase || entries.uhold || entries.umod {
        return true
    }

    return false
}


SetSysModHotkeys() {
    static first_start := true

    if first_start {
        first_start := false
        return
    }

    stack := []
    for lang, root in ROOTS {
        if lang !== 0 {
            stack.Push(root)
        }
    }

    while stack.Length {
        unode := stack.Pop()

        bit_modifiers := Map()
        for key, ch in SYS_MODIFIERS {
            m_node := unode.GetModFin(key)
            if m_node {
                bit := Integer(m_node.down_val)
                if !bit_modifiers.Has(bit) {
                    bit_modifiers[bit] := []
                }
                bit_modifiers[bit].Push(ch)
            }
        }

        hks := []
        for sc, mods in unode.active_scancodes {
            for md, next_unode in mods {
                chs := []
                bt := 0
                seen_ch := Map()
                for bit, ch in bit_modifiers {
                    if (md & (1 << bit)) && !seen_ch.Has(ch) {
                        chs.Push(ch)
                        bt += 1 << bit
                        seen_ch[ch] := 1
                    }
                }
                if chs.Length {
                    for res in CombineGroups(chs) {
                        if sc is Number {
                            hks.Push([res . SC_STR[sc], sc, bt])
                        } else {
                            hks.Push([res . sc, MOUSE_SCS[sc], bt])
                        }
                    }
                }

                if next_unode.scancodes.Count {
                    stack.Push(next_unode)
                }
            }
        }

        HotIf(_CompareGlob.Bind(unode, version))
        for sc in hks {
            Hotkey(sc[1], ((sc, extra_mod) => (*) => OnKeyDown(sc, extra_mod))(sc[2], sc[3]))
            Hotkey(sc[1] . " up", ((sc, extra_mod) => (*) => OnKeyUp(sc, extra_mod))(sc[2], sc[3]))
        }
        HotIf()
    }
}


_CompareGlob(mem_unode, mem_version, *) {
    return version == mem_version && curr_unode == mem_unode
}


CombineGroups(groups, index:=1, pref:="") {
    result := []

    if index > groups.Length {
        result.Push(pref)
        return result
    }

    for val in groups[index] {
        result.Push(CombineGroups(groups, index+1, pref . val)*)
    }

    return result
}