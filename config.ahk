CoordMode "Mouse", "Screen"
A_HotkeyInterval := 0
version := 0
s_gui := false

SYS_MODIFIERS := Map(
    0x02A, "<+",
    0x036, ">+",  ; ASCII
    0x136, ">+",  ; ISO
    0x01D, "<^",
    0x11D, ">^",
    0x038, "<!",
    0x138, ">!",
    0x15B, "<#",
    0x15C, ">#"
)

EXTRA_SCS := Map()
for name in ["Volume_Mute", "Volume_Down", "Volume_Up", "Media_Next", "Media_Prev", "Media_Stop",
    "Media_Play_Pause", "Browser_Back", "Browser_Forward", "Browser_Refresh", "Browser_Stop",
    "Browser_Search", "Browser_Favorites", "Browser_Home", "Launch_Mail", "Launch_Media",
    "Launch_App1", "Launch_App2"] {
    EXTRA_SCS[GetKeySC(name)] := true
}

TYPES := {}
TYPES_R := ["Disabled", "Default", "Text", "KeySimulation", "Function", "Modifier", "Chord"]
for i, v in TYPES_R {
    TYPES.%v% := i
}

SC_STR := Map()
SC_STR_BR := []
loop 511 {
    curr := Format("SC{:03X}", A_Index)
    SC_STR[A_Index] := curr
    SC_STR_BR.Push("{" . curr . "}")
}

for key in [
    "LButton", "RButton", "MButton", "XButton1", "XButton2",
    "WheelUp", "WheelDown", "WheelLeft", "WheelRight"
] {
    SC_STR[key] := key
}

LANGS := OrderedMap()
LANGS.Add(0, "Layout: global")

CheckConfig()
CurrentLayout := GetCurrentLayout()
ReadLayers()
FillRoots()
UpdLayers()


CheckConfig() {
    global CONF
    static scale_defaults:=Map(
        1366, 1.1, 1920, 1.1, 1440, 1.15, 1536, 1.2, 1600, 1.25, 2560, 1.25, 3840, 1.5
    )

    if !FileExist("config.ini") {
        FileAppend(
            "[Main]`n"
            . "ActiveLayers=`n"
            . "UserLayouts=`n"
            . "LongPressDuration=150`n"
            . "NextKeyWaitDuration=300`n"
            . "WheelLRUnlockTime=150`n"
            . "LayoutFormat=ANSI`n"
            . "ExtraFRow=0`n"
            . "ExtraKRow=0`n"
            . "CollectUnfamiliarLayouts=0`n"
            . "IgnoreInactiveLayers=0`n"
            . "StartMinimized=0`n"
            . "`n[GUI]`n"
            . "KeynameType=1`n"
            . "OverlayType=3`n"
            . "GuiScale=1.25`n"
            . "FontScale=1`n"
            . "FontName=Segoe UI`n"
            . "ReferenceHeight=314`n"
            . "GuiBack=74`n"
            . "GuiSet=78`n"
            . "GuiSetHold=284`n"
            . "HelpTexts=0`n"
            . "GuiAltIgnore=1`n"
            . "HideMouseWarnings=0`n"
            . "`n[Gestures]`n"
            . "EdgeGestures=4`n"
            . "MinGestureLen=150`n"
            . "MinCosSimilarity=0.9`n"
            . "OverlayOpacity=200`n"
            . "Rotate=1`n"
            . "Scaling=0`n"
            . "ColorMode=HSV`n"
            . "LiveHint=1`n"
            . "LiveHintExtended=1`n"
            . "LHSize=30`n"
            . "GradientLoop=1`n"
            . "GradientLength=1000`n"
            . "GestureColors=random(3)`n"
            . "GradientLoopEdges=1`n"
            . "GradientLengthEdges=1000`n"
            . "GestureColorsEdges=4FC3F7,9575CD,F06292`n"
            . "GradientLoopCorners=1`n"
            . "GradientLengthCorners=1000`n"
            . "GestureColorsCorners=66BB6A,26C6DA,FBC02D`n"
            , "config.ini"
        )
    }
    DirCreate("layers")

    CONF := {}
    CONF.MS_LP := Integer(IniRead("config.ini", "Main", "LongPressDuration", 150))
    CONF.MS_NK := Integer(IniRead("config.ini", "Main", "NextKeyWaitDuration", 300))
    CONF.T := "T" . CONF.MS_LP / 1000
    CONF.wheel_unlock_time := Integer(IniRead("config.ini", "Main", "WheelLRUnlockTime", 150))
    CONF.layout_format := IniRead("config.ini", "Main", "LayoutFormat", "ANSI")
    CONF.extra_k_row := Integer(IniRead("config.ini", "Main", "ExtraKRow", 0))
    CONF.extra_f_row := Integer(IniRead("config.ini", "Main", "ExtraFRow", 0))
    CONF.unfam_layouts := Integer(IniRead("config.ini", "Main", "CollectUnfamiliarLayouts", 0))
    CONF.ignore_inactive := Integer(IniRead("config.ini", "Main", "IgnoreInactiveLayers", 0))
    CONF.start_minimized := Integer(IniRead("config.ini", "Main", "StartMinimized", 0))

    CONF.keyname_type := Integer(IniRead("config.ini", "GUI", "KeynameType", 1))
    CONF.overlay_type := Integer(IniRead("config.ini", "GUI", "OverlayType", 3))
    CONF.gui_scale := Float(IniRead(
        "config.ini", "GUI", "GuiScale", scale_defaults.Get(A_ScreenWidth, 1.0)
    ))
    CONF.font_scale := Float(IniRead("config.ini", "GUI", "FontScale", 1))
    CONF.font_name := IniRead("config.ini", "GUI", "FontName", "Segoe UI")
    CONF.ref_height := Integer(IniRead("config.ini", "GUI", "ReferenceHeight", 314))
    CONF.gui_back_sc := IniRead("config.ini", "GUI", "GuiBack", 74)
    CONF.gui_set_sc := IniRead("config.ini", "GUI", "GuiSet", 78)
    CONF.gui_set_hold_sc := IniRead("config.ini", "GUI", "GuiSetHold", 284)
    CONF.help_texts := Integer(IniRead("config.ini", "GUI", "HelpTexts", 0))
    CONF.gui_alt_ignore := Integer(IniRead("config.ini", "GUI", "GuiAltIgnore", 1))
    CONF.hide_mouse_warnings := Integer(IniRead("config.ini", "GUI", "HideMouseWarnings", 0))

    CONF.edge_gestures := Integer(IniRead("config.ini", "Gestures", "EdgeGestures", 4))
    CONF.edge_size := Integer(IniRead("config.ini", "Gestures", "EdgeSize", 100))
    CONF.min_gesture_len := Integer(IniRead("config.ini", "Gestures", "MinGestureLen", 150))
    CONF.min_cos_similarity := Float(IniRead("config.ini", "Gestures", "MinCosSimilarity", 0.90))
    CONF.overlay_opacity := Integer(IniRead("config.ini", "Gestures", "OverlayOpacity", 200))
    CONF.font_size_lh := Integer(IniRead("config.ini", "Gestures", "LHSize", 32))
    CONF.live_hint_extended := Integer(IniRead("config.ini", "Gestures", "LiveHintExtended", 1))
    CONF.gest_rotate := Integer(IniRead("config.ini", "Gestures", "Rotate", 1))
    CONF.scale_impact := Float(IniRead("config.ini", "Gestures", "Scaling", 0))
    CONF.gest_color_mode := IniRead("config.ini", "Gestures", "ColorMode", "HSV")
    CONF.gest_live_hint := Integer(IniRead("config.ini", "Gestures", "LiveHint", 1))

    CONF.grad_loop := [
        Integer(IniRead("config.ini", "Gestures", "GradientLoop", 1)),
        Integer(IniRead("config.ini", "Gestures", "GradientLoopEdges", 1)),
        Integer(IniRead("config.ini", "Gestures", "GradientLoopCorners", 1)),
    ]
    CONF.grad_len := [
        Integer(IniRead("config.ini", "Gestures", "GradientLength", 1000)),
        Integer(IniRead("config.ini", "Gestures", "GradientLengthEdges", 1000)),
        Integer(IniRead("config.ini", "Gestures", "GradientLengthCorners", 1000)),
    ]
    CONF.gest_colors := [
        IniRead("config.ini", "Gestures", "GestureColors", "random(3)"),
        IniRead("config.ini", "Gestures", "GestureColorsEdges", "4FC3F7,9575CD,F06292"),
        IniRead("config.ini", "Gestures", "GestureColorsCorners", "66BB6A,26C6DA,FBC02D")
    ]

    if !IniRead("config.ini", "Main", "UserLayouts") {
        TrackLayouts()
        WinWaitClose(layout_gui.Hwnd)
        return
    }

    for lang in StrSplit(IniRead("config.ini", "Main", "UserLayouts"), ",") {
        lang := Integer(Trim(lang))
        if LANGS.Has(lang) {
            continue
        }
        LANGS.Add(lang, "Layout: " . GetLayoutNameFromHKL(lang))
    }
}


TrackLayouts(*) {
    global start_hkl, last_hkl, layout_gui

    layout_gui := Gui("+AlwaysOnTop -SysMenu", "Layout Detector")
    layout_gui.SetFont("s10")
    layout_gui.Add(
        "Text", "Center w400 h20", "Initial setup. Switch between all your language layouts."
    )
    layout_gui.Add("Text", "Center x100 w200 vCnt", "Found: 0")
    layout_gui.Add("Button", "Center w100 x300 yp4 h20 vNext", "I only have one")
        .OnEvent("Click", StopTracking)
    layout_gui.Show("h60 w400")

    start_hkl := GetCurrentLayout()
    last_hkl := 0

    SetTimer(Watch, 100)
}


Watch() {
    global last_hkl

    hkl := GetCurrentLayout()
    if hkl == last_hkl {
        return
    }
    last_hkl := hkl
    if !LANGS.Has(hkl) {
        LANGS.Add(hkl, "Layout: " . GetLayoutNameFromHKL(hkl))
        layout_gui["Cnt"].Text := "Found: " . LANGS.Length - 1
    } else if hkl == start_hkl && LANGS.Length > 1 {
        StopTracking()
    }
}


StopTracking(*) {
    layout_gui["Cnt"].Text := "Great! Enjoy using it."
    SetTimer(Watch, 0)
    str_value := ""
    for lang in LANGS.map {
        if lang {
            str_value .= lang . ","
        }
    }
    IniWrite(SubStr(str_value, 1, -1), "config.ini", "Main", "UserLayouts")
    Sleep(1000)
    layout_gui.Destroy()
}


ShowSettings(*) {
    global s_gui

    try s_gui.Destroy()

    s_gui := Gui(, "Settings")
    s_gui.OnEvent("Close", CloseSettingsEvent)
    s_gui.OnEvent("Escape", CloseSettingsEvent)
    s_gui.SetFont("s10")

    s_gui.Add("Button", "Center x370 y0 w20 h20 Default vApply", "✔")
        .OnEvent("Click", SaveConfig)

    tabs := s_gui.Add("Tab3", "x0 y0 w402 h666", ["Main", "GUI", "Gestures", "Gesture defaults"])

    tabs.UseTab("Main")

    _AddElems("str", 40,
        [0, "LongPressDuration Number", "Hold threshold (ms):", CONF.MS_LP],
        [0, "NextKeyWaitDuration Number", "Nested event waiting time (ms):", CONF.MS_NK],
        [0, "WheelLRUnlockTime Number", "Unlock l/r mouse wheel (ms):", CONF.wheel_unlock_time],
    )
    _AddElems("ddl",,
        [0, "LayoutFormat", "Layout format:", ["ANSI", "ISO"], true, CONF.layout_format],
    )
    _AddElems("checkbox",,
        [0, "ExtraFRow", "Use extra &f-row (13-24)", CONF.extra_f_row],
        [0, "ExtraKRow", "Use &special keys (media, browser, apps)", CONF.extra_k_row],
        [0, "CollectUnfamiliarLayouts", "Collect unfamiliar kbd &layouts from layers",
            CONF.unfam_layouts],
    )
    inactive_help_txt := "With this option, the program doesn’t parse inactive layer values "
        . "into a core structure. "
        . "`nTurn off only temporarily for work with GUI to view cross-values for all layers. "
        . "`n⚠Turn on after adjusting the layers."
    _AddElems("h_checkbox",, [0, inactive_help_txt, "Ignore inactive layers",
        "IgnoreInactiveLayers", "&Ignore inactive layers", CONF.ignore_inactive])
    _AddElems("checkbox",,
        [0, "StartMinimized", "Start &minimized", CONF.start_minimized],
    )

    s_gui.Add("Button", "Center x15 y+15 w370 h20", "Reread system layouts")
        .OnEvent("Click", TrackLayouts)


    tabs.UseTab("GUI")

    _AddElems("ddl", 40,
        [0, "KeynameType", "Keyname type:",
            ["Always use keynames", "Always use scancodes", "Scancodes on empty keys"],
            false, CONF.keyname_type],
        [0, "OverlayType", "Indicator overlay type:",
            ["Disabled", "Indicators only", "With counters"], false, CONF.overlay_type],
    )
    _AddElems("str",,
        [0, "GuiScale", "Gui scale:", Round(CONF.gui_scale, 2)],
        [0, "FontScale", "Font scale:", Round(CONF.font_scale, 2)],
        [0, "FontName", "Font name:", CONF.font_name],
        [0, "ReferenceHeight Number", "Reference height:", CONF.ref_height],
        [0, "GuiBackEdit", "'Back' action GUI hotkey:", ""],
        [0, "GuiSetEdit", "…'Set tap' action:", ""],
        [0, "GuiSetHoldEdit", "…'Set hold' action:", ""],
    )
    _AddElems("checkbox",,
        [0, "HelpTexts", "Show &help texts", CONF.help_texts],
        [0, "GuiAltIgnore", "Ignore physical &Alt presses on the GUI", CONF.gui_alt_ignore],
        [1, "HideMouseWarnings", "Hide warnings about disabling drag &behavior for LBM/RBM/MBM",
            CONF.hide_mouse_warnings],
    )

    s_gui["GuiBackEdit"].Text := _GetKeyName(CONF.gui_back_sc)
    s_gui["GuiSetEdit"].Text := _GetKeyName(CONF.gui_set_sc)
    s_gui["GuiSetHoldEdit"].Text := _GetKeyName(CONF.gui_set_hold_sc)


    tabs.UseTab("Gestures")

    _AddElems("ddl", 40, [0, "EdgeGestures", "Use edge gestures:",
        ["No", "With edges", "With corners", "With edges and corners"],
            false, CONF.edge_gestures],
        [0, "ColorMode", "Color mode:", ["RGB", "Gamma-correct", "HSV"],
        true, CONF.gest_color_mode],
    )
    _AddElems("str",,
        [0, "EdgeSize Number", "Edge definition width:", CONF.edge_size],
        [0, "MinGestureLen Number", "Gesture min length:", CONF.min_gesture_len],
        [0, "MinCosSimilarity", "Gesture min similarity:",
            Round(CONF.min_cos_similarity, 2)],
        [0, "OverlayOpacity Number", "Overlay opacity (up to 255):", CONF.overlay_opacity],
        [0, "LHSize Number", "Font size on live hint:", CONF.font_size_lh],
    )
    _AddElems("checkbox",,
        [0, "LiveHintExtended", "Show unrecognized gestures on live hint",
            CONF.live_hint_extended],
    )


    tabs.UseTab("Gesture defaults")

    s_gui.Add("Text", "x20 w360 y34 h34 Center",
        "Default gesture matching and color options`n(can be overridden in each assignment)")
    s_gui.Add("Text", "x20 w360 y+8 h1 0x10")
    _AddElems("ddl", 90,
        [0, "Rotate", "Rotate:", ["No", "Remove orientation noise", "Orientation invariance"],
            false, CONF.gest_rotate],
    )
    _AddElems("str",,
        [0, "Scaling", "Scale impact:", Round(CONF.scale_impact, 1)],
    )
    _AddElems("ddl",,
        [0, "LiveHint", "Live recognition hint position:", ["Top", "Center", "Bottom", "Disabled"],
            false, CONF.gest_live_hint],
    )
    s_gui.Add("Text", "x110 w180 y+10 h1 0x10")

    s_gui.Add("Button", "vToggleColors x15 y+10 h20 w121 Disabled", "General")
        .OnEvent("Click", _ToggleColors.Bind(1))
    s_gui.Add("Button", "vToggleColorsEdges x135 yp0 h20 w121", "Edges")
        .OnEvent("Click", _ToggleColors.Bind(2))
    s_gui.Add("Button", "vToggleColorsCorners x255 yp0 h20 w120", "Corners")
        .OnEvent("Click", _ToggleColors.Bind(3))

    for i, name in ["", "Edges", "Corners"] {
        _AddElems("str", 215,
            [1, "GestureColors" . name, "Gesture colors`n(more than one for gradient):",
                CONF.gest_colors[i]],
            [0, "GradientLength" . name . " Number", "Full gradient cycle length (px):",
                CONF.grad_len[i]],
        )
        _AddElems("checkbox",,
            [0, "GradientLoop" . name, "&Gradient cycling", CONF.grad_loop[i]]
        )
        if i > 1 {
            s_gui["GestureColors" . name].Visible := false
            s_gui["GradientLength" . name].Visible := false
            s_gui["GradientLoop" . name].Visible := false
        }
    }

    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiBack", CONF.gui_back_sc)
    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiSet", CONF.gui_set_sc)
    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiSetHold", CONF.gui_set_hold_sc)

    s_gui.Show("w400 h400")
    DllCall("SetFocus", "ptr", s_gui["ExtraFRow"].Hwnd)
}


_ToggleColors(trg, *) {
    for i, name in ["", "Edges", "Corners"] {
        s_gui["GestureColors" . name].Visible := i == trg
        s_gui["GradientLength" . name].Visible := i == trg
        s_gui["GradientLoop" . name].Visible := i == trg
        s_gui["ToggleColors" . name].Opt((i == trg ? "+" : "-") . "Disabled")
    }
}


_AddElems(elem_type, y:=false, data*) {
    static cur_h:=0, _shift:=8

    cur_h := y || cur_h

    switch elem_type {
        case "ddl":
            for arr in data {
                h := arr[1] ? 40 : 20
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w180", arr[3])
                elem := s_gui.Add("DropDownList",
                    "x+10 yp" . (arr[1] ? 8 : -2) . " w180 v" . arr[2], arr[4])
                if arr[5] {
                    elem.Text := arr[6]
                } else {
                    elem.Value := arr[6]
                }
                cur_h += h + _shift
            }
        case "str":
            for arr in data {
                h := arr[1] ? 40 : 20
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w190", arr[3])
                s_gui.Add("Edit", "Center x+0 yp" . (arr[1] ? 8 : -2) . " h20 w180 v"
                    . arr[2], arr[4])
                cur_h += h + _shift
            }
        case "checkbox":
            for arr in data {
                h := arr[1] ? 40 : 20
                s_gui.Add("CheckBox", "x15 y" . cur_h . " h" . h . " w360 v" . arr[2], arr[3])
                    .Value := arr[4]
                cur_h += h + _shift
            }
        case "h_checkbox":
            for arr in data {
                h := arr[1] ? 40 : 20
                fn := MsgBox.Bind(arr[2], arr[3], "IconI")
                s_gui.Add("Button", "x11 y" . cur_h . " h20 w20", "?")
                    .OnEvent("Click",(*) => fn.Call())
                s_gui.Add("CheckBox", "x+3 w330 yp+0 h20 v" . arr[4], arr[5]).Value := arr[6]
                cur_h += h + _shift
            }
    }
}


PasteSCToInput(sc) {
    switch ControlGetFocus("A") {
        case s_gui["GuiBackEdit"].Hwnd:
            s_gui["GuiBackEdit"].Text := _GetKeyName(sc)
            s_gui["GuiBack"].Text := sc
        case s_gui["GuiSetEdit"].Hwnd:
            s_gui["GuiSetEdit"].Text := _GetKeyName(sc)
            s_gui["GuiSet"].Text := sc
        case s_gui["GuiSetHoldEdit"].Hwnd:
            s_gui["GuiSetHoldEdit"].Text := _GetKeyName(sc)
            s_gui["GuiSetHold"].Text := sc
        default:
            return false
    }
    return true
}


SaveConfig(*) {
    global s_gui

    CancelChordEditing(0, true)

    for arr in [  ; texts/numbers
        ["Main", ["LongPressDuration", "NextKeyWaitDuration", "WheelLRUnlockTime",
            "LayoutFormat"]],
        ["GUI", ["GuiScale", "FontScale", "FontName", "ReferenceHeight",
            "GuiBack", "GuiSet", "GuiSetHold"]],
        ["Gestures", ["EdgeSize", "MinGestureLen", "MinCosSimilarity", "OverlayOpacity", "Scaling",
            "ColorMode", "GradientLength", "GradientLengthEdges", "GradientLengthCorners",
            "GestureColors", "GestureColorsEdges", "GestureColorsCorners", "LHSize"]]
    ] {
        for name in arr[2] {
            IniWrite(s_gui[name].Text, "config.ini", arr[1], name)
        }
    }

    for arr in [  ; checkboxes/ddl values (int)
        ["Main", ["ExtraFRow", "ExtraKRow", "CollectUnfamiliarLayouts", "IgnoreInactiveLayers",
            "StartMinimized"]],
        ["GUI", ["KeynameType", "OverlayType", "HelpTexts", "GuiAltIgnore", "HideMouseWarnings"]],
        ["Gestures", ["EdgeGestures", "Rotate", "LiveHint", "LiveHintExtended",
            "GradientLoop", "GradientLoopEdges", "GradientLoopCorners"]]
    ] {
        for name in arr[2] {
            IniWrite(s_gui[name].Value, "config.ini", arr[1], name)
        }
    }

    if s_gui["ExtraFRow"].Value !== CONF.extra_f_row
        || s_gui["ExtraKRow"].Value !== CONF.extra_k_row {
        Run(A_ScriptFullPath)  ; rerun with new keys
    }

    if s_gui["IgnoreInactiveLayers"].Value !== CONF.ignore_inactive {
        for layer in ActiveLayers.map {
            raw_roots := DeserializeMap(layer)
            AllLayers.map[layer] := _CountLangMappings(raw_roots)
        }
    }

    s_gui.Destroy()
    s_gui := false
    CheckConfig()
    DrawLayout()
}


CloseSettingsEvent(*) {
    global s_gui

    try s_gui.Destroy()
    s_gui := false
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