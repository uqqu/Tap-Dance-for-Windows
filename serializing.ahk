SerializeMap(map, filename, conv:=false) {
    for k, v in map {
        CleanFlatMap(v)
    }
    json := Dump(map, "", conv)
    try {
        FileDelete("layers/" . filename . ".json")
    }
    FileAppend(json, "layers/" . filename . ".json", "UTF-8")
}


DeserializeMap(filename) {
    json := FileRead("layers/" . filename . ".json")
    return Load(json)
}


Load(json) {
    pos := 1
    return ParseValue(&pos, json)
}


ParseValue(&pos, s) {
    SkipWhitespace(&pos, s)
    ch := SubStr(s, pos, 1)

    if ch == "{" {
        return ParseObject(&pos, s)
    } else if ch == "[" {
        return ParseArray(&pos, s)
    } else if ch == "`"" {
        return ParseString(&pos, s)
    } else if ch ~= "[-\d]" {
        return ParseNumber(&pos, s)
    } else if SubStr(s, pos, 4) == "true" {
        pos += 4
        return true
    } else if SubStr(s, pos, 5) == "false" {
        pos += 5
        return false
    } else if SubStr(s, pos, 4) == "null" {
        pos += 4
        return ""
    } else {
        throw Error("Unexpected value at position " . pos)
    }
}


ParseObject(&pos, s) {
    obj := Map()
    pos++
    SkipWhitespace(&pos, s)
    if SubStr(s, pos, 1) == "}" {
        pos++
        return obj
    }

    loop {
        SkipWhitespace(&pos, s)
        key := ParseString(&pos, s)
        SkipWhitespace(&pos, s)
        if SubStr(s, pos, 1) != ":" {
            throw Error("Expected ':' at " . pos)
        }
        pos++
        value := ParseValue(&pos, s)
        if StrLen(key) == 128 {
            key := SubStr(key, 1, 96)  ; for saved with previous buffer size
        } else if StrLen(key) != 96 {
            try {
                key := Integer(key)
            }
        }
        obj[key] := value
        SkipWhitespace(&pos, s)
        ch := SubStr(s, pos, 1)
        if ch == "}" {
            pos++
            return obj
        } else if ch != "," {
            throw Error("Expected ',' or '}' at " . pos)
        }
        pos++
    }
}


ParseArray(&pos, s) {
    arr := []
    pos++
    SkipWhitespace(&pos, s)
    if SubStr(s, pos, 1) == "]" {
        pos++
        return arr
    }

    loop {
        arr.Push(ParseValue(&pos, s))
        SkipWhitespace(&pos, s)
        ch := SubStr(s, pos, 1)
        if ch == "]" {
            pos++
            return arr
        } else if ch != "," {
            throw Error("Expected ',' or ']' at " . pos)
        }
        pos++
    }
}


ParseString(&pos, s) {
    if SubStr(s, pos, 1) != "`"" {
        throw Error("Expected string at " . pos)
    }
    pos++
    str := ""
    while pos <= StrLen(s) {
        ch := SubStr(s, pos, 1)
        if ch == "`"" {
            pos++
            return str
        } else if ch == "\" {
            pos++
            esc := SubStr(s, pos, 1)
            pos++
            str .= esc = "n"  ? "`n"
                 : esc = "r"  ? "`r"
                 : esc = "t"  ? "`t"
                 : esc = '"'  ? '"'
                 : esc = "\"  ? "\"
                 : esc = "b"  ? "`b"
                 : esc = "f"  ? "`f"
                 : esc = "/"  ? "/"
                 : esc = "u"  ? ParseUnicode(&pos, s)
                 : esc
        } else {
            str .= ch
            pos++
        }
    }
    throw Error("Unterminated string at " . pos)
}


ParseUnicode(&pos, s) {
    hex := SubStr(s, pos, 4)
    pos += 4
    return Chr("0x" . hex)
}


ParseNumber(&pos, s) {
    start := pos
    if SubStr(s, pos, 1) == "-" {
        pos++
    }
    while SubStr(s, pos, 1) ~= "\d" {
        pos++
    }
    if SubStr(s, pos, 1) == "." {
        pos++
        while SubStr(s, pos, 1) ~= "\d" {
            pos++
        }
    }
    if SubStr(s, pos, 1) ~= "[eE]" {
        pos++
        if SubStr(s, pos, 1) ~= "[-+]" {
            pos++
        }
        while SubStr(s, pos, 1) ~= "\d" {
            pos++
        }
    }
    return Number(SubStr(s, start, pos - start))
}


SkipWhitespace(&pos, s) {
    while SubStr(s, pos, 1) ~= "\s" {
        pos++
    }
}


Dump(obj, indent:="", conv:=false) {
    if obj is Map {
        out := "{"
        for k, v in obj {
            out .= "`n" . indent . "  " . "`"" . EscapeStr(k) . "`": " . Dump(v, indent . "  ", conv) . ","
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
    if obj == true {
        return "true"
    }
    if obj == false {
        return "false"
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
    str := str . ""
    str := StrReplace(str, "\", "\\")
    str := StrReplace(str, '"', '\"')
    str := StrReplace(str, "`r", "\r")
    str := StrReplace(str, "`n", "\n")
    str := StrReplace(str, "`t", "\t")
    return str
}