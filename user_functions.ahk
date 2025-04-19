SetActiveLayers(args) {
    global ACTIVE_LAYERS
    ACTIVE_LAYERS := args
    _WriteActiveLayersToConfig()
}


ToggleLayers(args) {
    global ACTIVE_LAYERS
    for layer in args {
        b := false
        for i, v in ACTIVE_LAYERS {
            if v == layer {
                ACTIVE_LAYERS.RemoveAt(i)
                b := true
                break
            }
        }
        if !b {
            ACTIVE_LAYERS.Push(layer)
        }
    }
    _WriteActiveLayersToConfig()
}


SendCurrentDate(*) {
    Send(FormatTime(, "dddd, d MMMM yyyy"))
}


SendCurrentDateTime(*) {
    Send(FormatTime(, "dddd, d MMMM yyyy HH:mm"))
}


GetWeather(args) {
    ;args == [city_name]
    static weather_key := RegRead("HKEY_CURRENT_USER\Environment", "OPENWEATHERMAP", 0)
    if !weather_key {
        MsgBox("The api key was not found in the environment variables.", "OPENWEATHERMAP")
    }

    web_request := ComObject("WinHttp.WinHttpRequest.5.1")
    web_request.Open("GET",
        "https://api.openweathermap.org/data/2.5/weather?q=" . args[1] . "&appid=" . weather_key . "&units=metric"
    )
    web_request.Send()

    stat := StrTitle(RegExReplace(web_request.ResponseText, '.+"main":"(\w+)".+', "$1"))
    temp := RegExReplace(web_request.ResponseText, '.+"temp":(-?\d+\.\d+).+', "$1")
    feel := RegExReplace(web_request.ResponseText, '.+"feels_like":(-?\d+\.\d+).+', "$1")
    wind := RegExReplace(web_request.ResponseText, '.+"speed":(\d+\.\d+|\d+).+', "$1")

    MsgBox(stat . "`n" . temp . "° (" . feel . "°)`n" . wind . "m/s", args[1])
}


ExchRates(args) {
    ;args == [from_currency, to_currency]
    static currency_key := RegRead("HKEY_CURRENT_USER\Environment", "GETGEOAPI", 0)
    if !currency_key {
        MsgBox("The api key was not found in the environment variables.", "GETGEOAPI")
    }

    web_request := ComObject("WinHttp.WinHttpRequest.5.1")
    web_request.Open("GET",
        "https://api.getgeoapi.com/api/v2/currency/convert?api_key="
        . currency_key . "&from=" . args[1] . "&to=" . args[2] . "&amount=1&format=json"
    )
    web_request.Send()

    MsgBox(
        Round(RegExMatch(web_request.ResponseText, '"rate_for_amount":"(\d+\.\d+)"', &m) ? m[1] : 0, 2),
        args[1] . "–" . args[2]
    )
}


Reminder(*) {
    inp := InputBox("Remind me in ... minutes", "Reminder", "h100 w170")
    if inp.Result == "OK" {
        try {
            delay := inp.Value * 60000
            SetTimer(_Alarma, delay)
        } catch {
            if MsgBox("The input must be a number!", "Incorrect value", 53) == "Retry" {
                Reminder()
            }
        }
    }
}


DelayedMediaPlayPause(*) {
    inp := InputBox("Trigger the play/pause after ... minutes", "", "h100 w170")
    if inp.Result == "OK" {
        try {
            delay := inp.Value * 60000
            SetTimer(_MPPTimer, delay)
        } catch {
            if MsgBox("The input must be a number!", "Incorrect value", 53) == "Retry" {
                DelayedMediaPlayPause()
            }
        }
    }
}


_Alarma() {
    MsgBox("Reminder", "Reminder", 48)
    SetTimer(_Alarma, 0)
}


_MPPTimer() {
    SendInput("{Media_Play_Pause}")
    SetTimer(_MPPTimer, 0)
}


NormalizeSelectedText(*) {
    saved := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{SC02E}")

    ClipWait(1)
    if A_Clipboard == "" {
        return
    }

    result := StrLower(A_Clipboard)
    result := RegExReplace(result, "[ \t]+", " ")
    result := Trim(result)
    result := RegExReplace(result, " ?([.,!?;]+) ?", "$1 ")
    result := RegExReplace(result, "((^|[.!?]\s|^[–—]\s)([a-zа-яё]))", "$U1")
    result := RegExReplace(result, "\bi(['’])\b", "I$1")

    A_Clipboard := Trim(result)
    SendInput("^{SC02F}")
    Sleep(100)
    A_Clipboard := saved
}


LowercaseSelectedText(*) {
    saved := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{SC02E}")

    ClipWait(1)
    if A_Clipboard == "" {
        return
    }

    result := StrLower(A_Clipboard)

    A_Clipboard := Trim(result)
    SendInput("^{SC02F}")
    Sleep(100)
    A_Clipboard := saved
}


SmartTranslit(*) {
    static to_cyr := Map(
        "shch", "щ", "yo", "ё", "zh", "ж", "kh", "х", "ts", "ц",
        "ch", "ч", "sh", "ш", "yu", "ю", "ya", "я",
        "a", "а", "b", "б", "v", "в", "g", "г", "d", "д", "e", "е",
        "z", "з", "i", "и", "y", "й", "k", "к", "l", "л", "m", "м",
        "n", "н", "o", "о", "p", "п", "r", "р", "s", "с", "t", "т",
        "u", "у", "f", "ф", "h", "х", "c", "ц", "'", "ь", "``", "ъ"
    )
    static to_lat := Map()
    for k, v in to_cyr {
        if !to_lat.Has(v)
            to_lat[v] := k
    }

    saved := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{SC02E}")
    ClipWait(1)
    text := A_Clipboard

    if text == "" {
        return
    }

    reverse := !RegExMatch(text, "[а-яА-ЯёЁ]")

    keys := []

    table := reverse ? to_cyr : to_lat
    for k in table
        keys.Push(k)
    _SortByLengthDesc(keys)

    result := ""
    i := 1

    while i <= StrLen(text) {
        matched := false
        for k in keys {
            len := StrLen(k)
            chunk := SubStr(text, i, len)
            if StrLower(chunk) == k {
                repl := table[k]
                result .= _PreserveCase(chunk, repl)
                i += len
                matched := true
                break
            }
        }
        if !matched {
            result .= SubStr(text, i, 1)
            i++
        }
    }

    A_Clipboard := result
    SendInput("^{SC02F}")
    Sleep(100)
    A_Clipboard := saved
}


_PreserveCase(from, to) {
    if from == "" || to == ""
        return to
    if RegExMatch(from, "^[A-ZА-ЯЁ]+$") {
        return StrUpper(to)
    } else if RegExMatch(from, "^[a-zа-яё]+$") {
        return StrLower(to)
    } else if RegExMatch(from, "^[A-ZА-ЯЁ][a-zа-яё]+$") {
        return StrUpper(SubStr(to, 1, 1)) . SubStr(to, 2)
    } else {
        return to
    }
}


_SortByLengthDesc(arr) {
    loop arr.Length {
        loop arr.Length - 1 {
            if StrLen(arr[A_Index]) < StrLen(arr[A_Index + 1]) {
                tmp := arr[A_Index]
                arr[A_Index] := arr[A_Index + 1]
                arr[A_Index + 1] := tmp
            }
        }
    }
}


IncrDecr(args){
    n := Integer(args[0])
    saved := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{SC02E}")

    ClipWait(1)
    if A_Clipboard == "" {
        return
    }

    inp := A_Clipboard

    if inp is Number {
        if inp is Float {
            inp := Round(inp + 1*n, StrLen(inp) - InStr(inp, "."))
        } else {
            inp := inp + 1*n
        }
        new_value_len := StrLen(inp)
        Send(inp . "{Left " . new_value_len . "}" . "+{Right " . new_value_len . "}")
        Sleep(100)
        A_Clipboard := saved
        return
    } else if StrLen(inp) == 1 {
        order := Ord(inp) + 1*n
    } else {
        order := Ord(SubStr(inp, 0)) + 1*n
        Send("{Right}+{Left}")
    }

    if order == 31 {
        order := 32
    } else if order < 31 {
        Sleep(100)
        A_Clipboard := saved
        return
    }

    while RegExMatch(Chr(order), "\p{M}|\p{C}") || order == 6277 || order == 6278 {
        order := order + 1*n
    }

    try {
        SendEvent("{Text}" . Chr(order))
    }
    Send("{Left}")
    Send("+{Right}")
    A_Clipboard := saved
}