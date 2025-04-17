GetMapKeys(user_map) {
    result := []
    for key, _ in user_map {
        result.Push(key)
    }
    return result
}


GetCurrentLayout() {
    return Integer(DllCall(
        "GetKeyboardLayout", "UInt",
        DllCall("GetWindowThreadProcessId", "Ptr", WinActive("A"), "Ptr", 0),
        "UPtr"
    ))
}


GetLayoutNameFromHKL(hkl) {
    buf := Buffer(9)
    DllCall("GetLocaleInfoW", "UInt", hkl & 0xFFFF, "UInt", 0x59, "Ptr", buf, "Int", 9)
    return StrGet(buf)
}


DeepCopy(obj, seen:=Map()) {
    if obj is Array {
        copy := []
        seen[obj] := copy
        for v in obj {
            copy.Push(DeepCopy(v, seen))
        }
        return copy
    }

    if obj is Map {
        copy := Map()
        seen[obj] := copy
        for k, v in obj {
            copy[DeepCopy(k, seen)] := DeepCopy(v, seen)
        }
        return copy
    }

    return obj
}


DeepEqual(a, b) {
    if Type(a) != Type(b) {
        return false
    }

    if !IsObject(a) {
        return a == b
    }

    if a is Array {
        if a.Length != b.Length {
            return false
        }
        for i, val in a {
            if !DeepEqual(val, b[i]) {
                return false
            }
        }
        return true
    }

    if a is Map {
        if a.Count != b.Count {
            return false
        }
        for key, val in a {
            if !b.Has(key) || !DeepEqual(val, b[key]) {
                return false
            }
        }
        return true
    }

    return a == b
}


_WalkPath(start, path, merged:=true) {
    if !path.Length {
        return [start, false, false]
    }
    if !(path[1] is Array) {
        path := [path]
    }

    curr_map := start
    curr_base := false
    curr_hold := false
    for arr in path {
        rem := Mod(arr[2], 2)

        if arr[3] {  ; chord
            if !curr_map.Has(-1) {
                curr_map[-1] := Map()
            }
            curr_map := curr_map[-1]
        }

        if !curr_map.Has(arr[1]) {  ; sc/buf
            curr_map[arr[1]] := Map()
        }
        for md in [arr[2] - rem, arr[2] - rem + 1] {  ; pure mod, mod+hold
            if !curr_map[arr[1]].Has(md) {
                core := md || arr[3] ? [0, "", Map()] : [2, SC_STR_BR[arr[1]], Map()]
                if merged {
                    core.Push([])  ; names
                    curr_map[arr[1]][md] := [core]
                } else {
                    curr_map[arr[1]][md] := core
                }
            }
        }

        curr_base := curr_map[arr[1]][arr[2] - rem]
        curr_hold := curr_map[arr[1]][arr[2] - rem + 1]
        if !curr_hold && curr_map[arr[1]].Has(1) && _GetType(curr_map[arr[1]][1]) == 4 {  ; modifier on base level
            curr_hold := curr_map[arr[1]][1]
        }
        curr_map := merged ? curr_map[arr[1]][arr[2]][1][3] : curr_map[arr[1]][arr[2]][3]
    }
    return [curr_map, curr_base, curr_hold]
}


_SetTypeVal(arr, new_type, new_val, name:="") {
    if arr[1] is Integer {
        arr[1] := new_type
        arr[2] := new_val
    } else if arr[1][1] is Integer {
        arr[1][1] := new_type
        arr[1][2] := new_val
    } else {
        arr[1][1][1] := new_type
        arr[1][1][2] := new_val

        if name {
            b := false
            if arr[1][3] {
                for existing_name in arr[1][3] {
                    if existing_name == name {
                        b := true
                        break
                    }
                }
            }
            if !b {
                arr[1][3].Push(name)
            }
        }
    }
}


__GetFromStruct(arr, idx) {
    if !arr {
        return 0
    }
    if arr[1] is Integer {
        return arr[idx]
    }
    return arr[1][idx]
}

_GetType(arr) {
    return __GetFromStruct(arr, 1)
}

_GetVal(arr) {
    return __GetFromStruct(arr, 2)
}

_GetMap(arr) {
    return __GetFromStruct(arr, 3)
}

_GetNames(arr) {
    return __GetFromStruct(arr, 4)
}


_DeepMergePreserveVariants(merged, flat, name) {
    for code, mods in flat {
        if code == -1 {
            if !merged.Has(-1) {
                merged[-1] := Map()
            }
            _DeepMergePreserveVariants(merged[-1], mods, name)
            continue
        }

        if !merged.Has(code) {
            merged[code] := Map()
        }
        for k, v in mods {
            if !merged[code].Has(k) {
                merged[code][k] := [[v[1], v[2], Map(), []]]
            }
            flag := false
            for i, opt in merged[code][k] {
                if v[1] == opt[1] && v[2] == opt[2] {
                    merged[code][k][i][4].Push(name)
                    _DeepMergePreserveVariants(merged[code][k][i][3], v[3], name)
                    flag := true
                    break
                }
            }
            if !flag {
                a := [v[1], v[2], Map(), [name]]
                merged[code][k].Push(a)
                _DeepMergePreserveVariants(a[3], v[3], name)
            }
        }
    }
}


GetPriorKeys(merged) {
    result := Map()
    for sc, mods in merged {
        if sc == -1 {
            result[-1] := GetPriorKeys(mods)
            continue
        }

        result[sc] := Map()

        for md, opts in mods {
            if (opts[1][2] == "" || opts[1][1] == 0) && opts.Length > 1 {
                result[sc][md] := [opts[2][1], opts[2][2], GetPriorKeys(opts[1][3])]
            } else {
                result[sc][md] := [opts[1][1], opts[1][2], GetPriorKeys(opts[1][3])]
            }
        }
    }
    return result
}


CleanMergedMap(validated, level:=1, in_path:=true) {
    if !validated.Count {
        return
    }

    to_del_sc := []
    for sc, mods in validated {
        if sc == -1 {
            CleanMergedMap(mods, level, in_path)
            if !mods.Count {
                to_del_sc.Push(-1)
            }
            continue
        }

        to_del_mods := []
        for md, opts in mods {
            t_in_path := in_path && level <= current_path.Length && current_path[level][1] == sc
            to_del_opts := []
            for i, opt in opts {
                if !opt[4].Length {
                    to_del_opts.Push(i)
                } else {
                    CleanMergedMap(opt[3], level + 1, t_in_path)
                    if ((md && (!opt[1] || opt[1] < 4 && !opt[2])) || (!md && opt[1] == 2 && opt[2] == SC_STR_BR[sc]))
                        && !opt[3].Count && !t_in_path {  ; TODO opt[1] != 5 && !opt[2]
                        to_del_opts.Push(i)
                    }
                }
            }
            while to_del_opts.Length {
                opts.RemoveAt(to_del_opts.Pop())
            }
            if !opts.Length {
                to_del_mods.Push(md)
            }
        }

        for md in to_del_mods {
            mods.Delete(md)
        }
        if !mods.Count {
            to_del_sc.Push(sc)
        }
    }

    for sc in to_del_sc {
        validated.Delete(sc)
    }
}


CleanFlatMap(validated) {
    if !validated.Count {
        return
    }

    to_del := []
    for sc, v in validated {
        if sc == -1 {
            CleanFlatMap(v)
            if !v.Count {
                to_del.Push(-1)
            }
            continue
        }

        to_del_mods := []
        for mod_k, mod_v in v {
            if Mod(mod_k, 2) {
                continue
            }

            h := v[mod_k + 1]
            CleanFlatMap(mod_v[3])
            CleanFlatMap(h[3])
            if ((!mod_k && mod_v[1] == 2 && mod_v[2] == SC_STR_BR[sc]) || (mod_k && mod_v[1] == 0 && mod_v[2] == ""))
                && h[1] == 0 && h[2] == "" && !h[3].Count && !mod_v[3].Count {
                to_del_mods.Push(mod_k)
            }
        }

        for md in to_del_mods {
            v.Delete(md)
            v.Delete(md + 1)
        }
        if !v.Count {
            to_del.Push(sc)
        }
    }
    for sc in to_del {
        validated.Delete(sc)
    }
}