﻿SerializeMap(mp, filename, conv:=false) {
    for lang, values in mp {
        _CleanMap(values)
    }
    json := Dump(mp, "", conv)
    try FileDelete("layers/" . filename . ".json")
    FileAppend(json, "layers/" . filename . ".json", "UTF-8")
}


_CleanMap(mp, parent_md:=0) {
    for opt in [mp[-1], mp[-2]] {
        to_del_sc := []
        for schex, mods in opt {
            to_del_md := []
            for md, val in mods {
                if !_CleanMap(val, md) {
                    to_del_md.Push(md)
                }
            }
            for md in to_del_md {
                mods.Delete(md)
            }
            if !mods.Count {
                to_del_sc.Push(schex)
            }
        }
        for schex in to_del_sc {
            opt.Delete(schex)
        }
    }
    ref := parent_md ? TYPES.Disabled : TYPES.Default
    if mp.Length > 2 && !mp[-1].Count && !mp[-2].Count && mp[1] == ref && !mp[2]
        && mp[3] == TYPES.Disabled && !mp[4] && !mp[5] && !mp[6] && !mp[7] && !mp[8] {
        return false
    }
    return true
}


DeserializeMap(filename) {
    return Load(FileRead("layers/" . filename . ".json"))
}


Load(json) {
    p := 1
    return ParseValue(&p, json)
}


ParseValue(&p, s) {
    SkipWhitespace(&p, s)
    ch := SubStr(s, p, 1)

    if ch == "{" {
        return ParseObject(&p, s)
    }
    if ch == "[" {
        return ParseArray(&p, s)
    }
    if ch == "`"" {
        return ParseString(&p, s)
    }
    if ch ~= "[-\d]" {
        return ParseNumber(&p, s)
    }
    if SubStr(s, p, 4) == "null" {
        p += 4
        return ""
    }
    throw Error("Unexpected value at position " . p)
}


ParseObject(&p, s) {
    obj := Map()
    p++
    SkipWhitespace(&p, s)
    if SubStr(s, p, 1) == "}" {
        p++
        return obj
    }

    loop {
        SkipWhitespace(&p, s)
        key := ParseString(&p, s)
        SkipWhitespace(&p, s)
        if SubStr(s, p, 1) !== ":" {
            throw Error("Expected ':' at " . p)
        }
        p++
        value := ParseValue(&p, s)
        if StrLen(key) !== 96 {
            try key := Integer(key)
        }
        obj[key] := value
        SkipWhitespace(&p, s)
        ch := SubStr(s, p, 1)
        if ch == "}" {
            p++
            return obj
        }
        if ch !== "," {
            throw Error("Expected ',' or '}' at " . p)
        }
        p++
    }
}


ParseArray(&p, s) {
    arr := []
    p++
    SkipWhitespace(&p, s)
    if SubStr(s, p, 1) == "]" {
        p++
        return arr
    }

    loop {
        arr.Push(ParseValue(&p, s))
        SkipWhitespace(&p, s)
        ch := SubStr(s, p, 1)
        if ch == "]" {
            p++
            return arr
        }
        if ch !== "," {
            throw Error("Expected ',' or ']' at " . p)
        }
        p++
    }
}


ParseString(&p, s) {
    if SubStr(s, p, 1) !== "`"" {
        throw Error("Expected string at " . p)
    }
    p++
    str := ""
    while p <= StrLen(s) {
        ch := SubStr(s, p, 1)
        if ch == "`"" {
            p++
            return str
        }
        if ch == "\" {
            p++
            esc := SubStr(s, p, 1)
            p++
            str .= esc = "n" ? "`n"
                 : esc = "r" ? "`r"
                 : esc = "t" ? "`t"
                 : esc = '"' ? '"'
                 : esc = "\" ? "\"
                 : esc = "b" ? "`b"
                 : esc = "f" ? "`f"
                 : esc = "/" ? "/"
                 : esc = "u" ? ParseUnicode(&p, s)
                 : esc
            continue
        }
        str .= ch
        p++
    }
    throw Error("Unterminated string at " . p)
}


ParseUnicode(&p, s) {
    hex := SubStr(s, p, 4)
    p += 4
    return Chr("0x" . hex)
}


ParseNumber(&p, s) {
    start := p
    if SubStr(s, p, 1) == "-" {
        p++
    }
    while SubStr(s, p, 1) ~= "\d" {
        p++
    }
    if SubStr(s, p, 1) == "." {
        p++
        while SubStr(s, p, 1) ~= "\d" {
            p++
        }
    }
    if SubStr(s, p, 1) ~= "[eE]" {
        p++
        if SubStr(s, p, 1) ~= "[-+]" {
            p++
        }
        while SubStr(s, p, 1) ~= "\d" {
            p++
        }
    }
    return Number(SubStr(s, start, p - start))
}


SkipWhitespace(&p, s) {
    while SubStr(s, p, 1) ~= "\s" {
        p++
    }
}


Dump(obj, indent:="", conv:=false) {
    if obj is Map {
        out := "{"
        for k, v in obj {
            out .= "`n" . indent . "  " . "`"" . EscapeStr(k) . "`": "
                . Dump(v, indent . "  ", conv) . ","
        }
        return out ~= ",$" ? SubStr(out, 1, -1) . "`n" . indent . "}" : out . "}"
    }
    if obj is Array {
        out := "["
        for v in obj {
            out .= "`n" . indent . "  " . Dump(v, indent . "  ", conv) . ","
        }
        return out ~= ",$" ? SubStr(out, 1, -1) . "`n" . indent . "]" : out . "]"
    }
    if obj is Number {
        return obj
    }
    if obj == "" {
        return "null"
    }
    return "`"" . EscapeStr(obj, conv) . "`""
}


EscapeStr(str, conv:=false) {
    if conv {
        pref := SubStr(str, 1, 6)
        str := pref == "{Text}" ? SubStr(str, 7) : pref == "{Blind" ? SubStr(str, 8) : str
        if RegExMatch(str, "^([\^+!#]*)\{(.+)\}$", &m) {
            sc := GetKeySC(m[2])
            if sc {
                return m[1] . sc
            }
        }
    }
    str .= ""
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`t", "\t")
    return str
}