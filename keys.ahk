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

SetSysModHotkeys()


SetSysModHotkeys() {
    stack := []
    for lang, mp in KEYS {
        stack.Push(mp)
    }

    while stack.Length {
        mp := stack.Pop()

        bit_modifiers := Map()
        for key, ch in SYS_MODIFIERS {
            if mp.Has(key) && mp[key][1][1] == 4 {
                bit := Integer(mp[key][1][2])
                if !bit_modifiers.Has(bit) {
                    bit_modifiers[bit] := []
                }
                bit_modifiers[bit].Push(ch)
            }
        }

        hks := []
        for sc, mods in mp {
            if sc == -1 {
                stack.Push(mods)
                continue
            }
            for md, val in mods {
                if Mod(md, 2) {
                    continue
                }
                chs := []
                bt := 0
                seen_ch := Map()
                for bit, ch in bit_modifiers {
                    if (md & (1 << bit)) {
                        if !seen_ch.Has(ch) {
                            chs.Push(ch)
                            bt += 1 << bit
                            seen_ch[ch] := 1
                        }
                    }
                }
                if chs.Length {
                    for res in CombineGroups(chs) {
                        hks.Push([res . SC_STR[sc], sc, bt])
                    }
                }

                if val[3].Count {
                    stack.Push(val[3])
                }
            }
        }

        HotIf(_CompareGlob.Bind(mp))
        for sc in hks {
            Hotkey(sc[1], ((sc, extra_mod) => (*) => OnKeyDown(sc, extra_mod))(sc[2], sc[3]))
            Hotkey(sc[1] . " up", ((sc, extra_mod) => (*) => OnKeyUp(sc, extra_mod))(sc[2], sc[3]))
        }
        HotIf()
    }
}


_CompareGlob(mem, *) {
    return glob == mem
}


CombineGroups(groups, index:=1, pref:="") {
    result := []

    if index > groups.Length {
        result.Push(pref)
        return result
    }

    for val in groups[index] {
        for r in CombineGroups(groups, index + 1, pref . val) {
            result.Push(r)
        }
    }

    return result
}