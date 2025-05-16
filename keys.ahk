for sc in ALL_SCANCODES {
    if SYS_MODIFIERS.Has(sc) {
        continue
    }

    Hotkey(SC_STR[sc], ((sc) => (*) => OnKeyDown(sc))(sc))
    Hotkey(SC_STR[sc] . " up", ((sc) => (*) => OnKeyUp(sc))(sc))
}

for sc in SYS_MODIFIERS {
    Hotkey("~" . SC_STR[sc], ((sc) => (*) => OnKeyDown(sc))(sc))
    Hotkey("~" . SC_STR[sc] . " up", ((sc) => (*) => OnKeyUp(sc))(sc))
}


SetSysModHotkeys() {
    stack := []
    for _, root in ROOTS {
        stack.Push(root)
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
                        hks.Push([res . SC_STR[sc], sc, bt])
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