outs := Map(
    "Output: SendText", (txt) => Send(txt),
    "Output: Clipboard", (txt) => (A_Clipboard := txt, 0),
    "Ouptut: Tooltip", (txt) => (Tooltip(txt), SetTimer(() => Tooltip(), -3000)),
    "Output: MessageBox", (txt) => MsgBox(txt)
)

inps := Map(
    "Input: Clipboard", (main_func) => main_func.Call(A_Clipboard),
    "Input: InputBox", (main_func) => main_func.Call(InputBox("Write text to processing").Value),
    "Input: Selected", (main_func) => _FromSelected(main_func)
)

_FromSelected(main_func) {
    saved := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{SC02E}")

    ClipWait(1)
    if A_Clipboard == "" {
        return
    }
    res := main_func.Call(A_Clipboard)
    A_Clipboard := saved
    return res
}


SetActiveLayers(layers*) {
    global ActiveLayers

    ActiveLayers := OrderedMap()
    for layer in layers {
        ActiveLayers.Add(layer)
    }
    _WriteActiveLayersToConfig()
}


ToggleLayers(layers*) {
    global ActiveLayers

    for layer in layers {
        layer_pos := layer[1]
        layer_name := layer[2]
        if ActiveLayers.map.Has(layer_name) {
            ActiveLayers.Remove(layer_name)
        } else {
            ActiveLayers.Add(layer_name, , layer_pos)
            if AllLayers.map[layer_name] is Integer {
                _MergeLayer(layer_name)
            }
        }
    }
    _WriteActiveLayersToConfig()
}


ActivateApp(path, process_name:="") {
    if process_name {
        name := "ahk_exe" . process_name
        WinActive(name) ? WinMinimize(name) : WinActivate(name)
    } else {
        Run(path)
    }
}


ToggleMod(md) {
    global current_mod

    current_mod ^= 1 << md
}


GetDateTime(val, out) {
    outs[out](FormatTime(, val))
}


GetCustomDateTime(val, out) {
    outs[out](FormatTime(, val))
}


GetWeather(city_name, out) {
    static weather_key := RegRead("HKEY_CURRENT_USER\Environment", "OPENWEATHERMAP", 0)

    if !weather_key {
        MsgBox("The api key was not found in the environment variables.",
            "OPENWEATHERMAP", "IconX")
    }

    if !city_name {
        city_name := InputBox("City name", "Get weather", "h100 w170").Value
    }

    web_request := ComObject("WinHttp.WinHttpRequest.5.1")
    web_request.Open("GET",
        "https://api.openweathermap.org/data/2.5/weather?q=" . city_name
        . "&appid=" . weather_key . "&units=metric"
    )
    web_request.Send()

    stat := StrTitle(RegExReplace(web_request.ResponseText, '.+"main":"(\w+)".+', "$1"))
    temp := RegExReplace(web_request.ResponseText, '.+"temp":(-?\d+\.\d+).+', "$1")
    feel := RegExReplace(web_request.ResponseText, '.+"feels_like":(-?\d+\.\d+).+', "$1")
    wind := RegExReplace(web_request.ResponseText, '.+"speed":(\d+\.\d+|\d+).+', "$1")

    outs[out](city_name . ":`n" . stat . "`n" . temp . "° (" . feel . "°)`n" . wind . "m/s")
}


ExchRates(from_currency, to_currency, out) {
    static currency_key := RegRead("HKEY_CURRENT_USER\Environment", "GETGEOAPI", 0)

    if !currency_key {
        MsgBox("The api key was not found in the environment variables.", "GETGEOAPI", "IconX")
    }

    web_request := ComObject("WinHttp.WinHttpRequest.5.1")
    web_request.Open("GET",
        "https://api.getgeoapi.com/api/v2/currency/convert?api_key="
        . currency_key . "&from=" . from_currency . "&to=" . to_currency . "&amount=1&format=json"
    )
    web_request.Send()

    res := RegExMatch(web_request.ResponseText, '"rate_for_amount":"(\d+\.\d+)"', &m) ? m[1] : 0
    outs[out](from_currency . "–" . to_currency . ": " . Round(res, 2))
}


Reminder(given_minutes:=0) {
    if given_minutes {
        SetTimer(_Alarma, given_minutes * 60000)
        return
    }
    res := InputBox("Remind me in ... minutes", "Reminder", "h100 w250")
    if res.Result == "OK" {
        try {
            delay := res.Value * 60000
            SetTimer(_Alarma, delay)
        } catch {
            if MsgBox("The input must be a number!", "Incorrect value", 53) == "Retry" {
                Reminder()
            }
        }
    }
}

_Alarma() {
    MsgBox("Reminder", "Reminder", 48)
    SetTimer(_Alarma, 0)
}


DelayedMediaPlayPause(given_minutes:=0) {
    if given_minutes {
        SetTimer(_MPPTimer, given_minutes * 60000)
        return
    }
    res := InputBox("Trigger the play/pause after ... minutes", "", "h100 w250")
    if res.Result == "OK" {
        try {
            delay := res.Value * 60000
            SetTimer(_MPPTimer, delay)
        } catch {
            if MsgBox("The input must be a number!", "Incorrect value", 53) == "Retry" {
                DelayedMediaPlayPause()
            }
        }
    }
}

_MPPTimer() {
    SendInput("{Media_Play_Pause}")
    SetTimer(_MPPTimer, 0)
}


ChangeTextCase(change_name, inp, out) {
    outs[out](inps[inp](_ChangeTextCase.Bind(change_name)))
}

_ChangeTextCase(change_name, txt) {
    switch change_name {
        case "Normalize":
            result := Trim(RegExReplace(StrLower(txt), "[ \t]+", " "))
            result := RegExReplace(result, " ?([.,!?;]+) ?", "$1 ")
            result := RegExReplace(result, "((^|[.!?]\s|^[–—]\s)([a-zа-яё]))", "$U1")
            return RegExReplace(result, "\bi(['’])\b", "I$1")
        case "Title":
            return StrTitle(txt)
        case "Lower":
            return StrLower(txt)
        case "Upper":
            return StrUpper(txt)
        case "Invert":
            result := ""
            for char in StrSplit(txt) {
                is_upper := char ~= "^[A-ZА-ЯЁ]$"
                is_lower := char ~= "^[a-zа-яё]$"

                if is_upper {
                    result .= StrLower(char)
                } else if is_lower {
                    result .= StrUpper(char)
                } else {
                    result .= char
                }
            }
            return result
    }
}


SmartTranslit(txt, inp, out) {
    outs[out](inps[inp](_SmartTranslit.Bind(txt)))
}

_SmartTranslit(txt) {
    static to_cyr := Map(
        "shch", "щ", "yo", "ё", "zh", "ж", "kh", "х", "ts", "ц", "ch", "ч", "sh", "ш", "yu", "ю",
        "ya", "я", "a", "а", "b", "б", "v", "в", "g", "г", "d", "д", "e", "е", "z", "з", "i", "и",
        "y", "й", "k", "к", "l", "л", "m", "м", "n", "н", "o", "о", "p", "п", "r", "р", "s", "с",
        "t", "т", "u", "у", "f", "ф", "h", "х", "c", "ц", "'", "ь", "``", "ъ"
    )
    static to_lat := Map()
    for k, v in to_cyr {
        if !to_lat.Has(v) {
            to_lat[v] := k
        }
    }

    reverse := !RegExMatch(txt, "[а-яА-ЯёЁ]")
    keys := []

    table := reverse ? to_cyr : to_lat
    for k in table {
        keys.Push(k)
    }
    _SortByLengthDesc(keys)

    result := ""
    i := 1

    while i <= StrLen(txt) {
        matched := false
        for k in keys {
            len := StrLen(k)
            chunk := SubStr(txt, i, len)
            if StrLower(chunk) == k {
                repl := table[k]
                result .= _PreserveCase(chunk, repl)
                i += len
                matched := true
                break
            }
        }
        if !matched {
            result .= SubStr(txt, i, 1)
            i++
        }
    }
    return result
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


IncrDecr(n) {
    saved := ClipboardAll()
    A_Clipboard := ""
    SendInput("^{SC02E}")

    ClipWait(1)
    if A_Clipboard == "" {
        return
    }

    val := A_Clipboard
    try val := Integer(val)

    if val is Number {
        if val is Float {
            val := Round(val + 1*n, StrLen(val) - InStr(val, "."))
        } else {
            val := val + 1*n
        }
        new_value_len := StrLen(val)
        Send(val . "{Left " . new_value_len . "}" . "+{Right " . new_value_len . "}")
        Sleep(10)
        A_Clipboard := saved
        return
    } else if StrLen(val) == 1 {
        order := Ord(val) + 1*n
    } else {
        order := Ord(SubStr(val, 0)) + 1*n
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

    try SendEvent("{Text}" . Chr(order))
    Send("{Left}")
    Send("+{Right}")
    A_Clipboard := saved
}


CustomString(txt, out) {
    outs[out](txt)
}


; don't look here
custom_funcs := Map(
    "SetActiveLayers", ["Set specified layers as current active layers. Multifield.",
        ["Layer name"]
    ],
    "ToggleLayers", ["Toggle the activity of specified layers. Multifield.",
        ["Priority", "Layer name"]],
    "TreatAsOtherNode", [
        "Go to assignment by given path (both in terms of value and transitions). "
        . "Set path step by step (multifield) from root node. You can use shortnames "
        . "%sc% and %md% for autocomplete.",
        ["Scancode (integer) or hexbuffer. '%sc%' is short for current one.",
        "Modifier value. 0/1/…, or '%md%' for autocomplete with current.",
        "Is chord? false/true / 0/1"]
    ],
    "ActivateApp", ["Run app by given path or switch to it process, if specified.",
        "Path to app", "Process name (can be ommited)"
    ],
    "ToggleMod", ["Toggle specified mod value (in script terms, not system modifiers).",
        "Mod value"
    ],
    "GetDateTime", ["Get the current date(time) with selected format.", 3, 2],
    "GetCustomDateTime", ["Get the current datetime with your own format. Without commas!",
        "i.e. 'dddd d MMMM yyyy HH:mm'", 2
    ],
    "GetWeather", ["Get the current weather in specified city "
        . "(requires API key OPENWEATHERMAP in the environment variables).",
        "City name", 2
    ],
    "ExchRates", ["Get the current currency rate for specified pair "
        . "(requires API key GETGEOAPI in the environment variables).",
        "From currency", "To currency", 2
    ],
    "Reminder", ["Set a reminder after a specified number of minutes. "
        . "If value is ommited you will be asked for input when you call the function",
        "Number of minutes"
    ],
    "DelayedMediaPlayPause", ["Start or stop music after a specified number of minutes. "
        . "If value is ommited you will be asked for input when you call the function",
        "Number of minutes"
    ],
    "ChangeTextCase", ["Align the case and spaces of the specified text.", 4, 1, 2],
    "SmartTranslit", ["Транслэйт фром зэ вронг скрипт. `nРаугли, бат андерстэндэйбл."
        . "`nI naoborot, konechno.", 1, 2
    ],
    "IncrDecr", ["Increase/decrease number or symbol (by unicode table) under the cursor",
        "Increase/decrease value (int). 1, -1, 42, …"],
    "CustomString", ["Just return custom text to chosen output.", "Text", 2]
)

custom_func_keys := ["SetActiveLayers", "ToggleLayers", "TreatAsOtherNode", "ActivateApp",
    "ToggleMod", "GetDateTime", "GetCustomDateTime", "GetWeather", "ExchRates", "Reminder",
    "DelayedMediaPlayPause", "ChangeTextCase", "SmartTranslit", "IncrDecr", "CustomString"
]

custom_func_ddls := [
    ["Input: Selected", "Input: Clipboard", "Input: InputBox"],
    ["Output: SendText", "Output: Clipboard", "Ouptut: Tooltip", "Output: MessageBox"],
    ["dddd d MMMM yyyy HH:mm", "dd.MM.yyyy HH:mm", "dd.MM.yyyy HH:mm:ss", "MM/dd/yyyy h:mm tt",
    "yyyy-MM-ddTHH:mm:ss", "yyyy-MM-dd_HH-mm-ss", "HH:mm:ss", "d MMMM yyyy",
    "dd MMMM yyyy", "dd.MM.yy"],
    ["Normalize", "Title", "Lower", "Upper", "Invert"]
]


_ParseFuncArgs(s) {
    args := []
    buffer := ""
    in_array := false
    arr_buf := []

    i := 1
    len := StrLen(s)

    while i <= len {
        ch := SubStr(s, i, 1)

        if ch == "[" {
            in_array := true
            arr_buf := []
            buffer := ""
        } else if ch == "]" {
            if Trim(buffer) !== "" {
                arr_buf.Push(Trim(buffer))
            }
            args.Push(arr_buf)
            in_array := false
            buffer := ""
        } else if ch == "," && SubStr(s, i+1, 1) == " " {
            if in_array {
                arr_buf.Push(Trim(buffer))
            } else {
                args.Push(Trim(buffer))
            }
            buffer := ""
            i += 1
        } else {
            buffer .= ch
        }

        i += 1
    }

    if Trim(buffer) != "" {
        in_array ? arr_buf.Push(Trim(buffer)) : args.Push(Trim(buffer))
    }

    return args
}