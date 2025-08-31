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
    static scale_defaults := Map(
        1366, 1.1, 1920, 1.1, 1440, 1.15, 1536, 1.2, 1600, 1.25, 2560, 1.25, 3840, 1.5
    )

    if !FileExist("config.ini") {
        FileAppend(
            "[Main]"
            . "`nLayoutFormat=ANSI"
            . "`nExtraFRow=0"
            . "`nExtraKRow=0"
            . "`nHelpTexts=0"
            . "`nHideMouseWarnings=0"
            . "`nGuiAltIgnore=1"
            . "`nGuiScale=1.25"
            . "`nFontScale=1"
            . "`nFontName=Segoe UI"
            . "`nGestureColor=0x0000FF"
            . "`nReferenceHeight=314"
            . "`nKeynameType=1"
            . "`nActiveLayers="  ; TODO?
            . "`nLongPressDuration=150"
            . "`nNextKeyWaitDuration=250"
            . "`nMinGestureLen=150"
            . "`nMinCosSimilarity=0.9"
            . "`nWheelLRUnlockTime=150"
            . "`nUserLayouts="
            . "`nIgnoreInactiveLayers=0"
            . "`nCollectUnfamiliarLayouts=0"
            . "`nGuiBackScancode=74"
            . "`nGuiSetScancode=78"
            . "`nGuiSetHoldScancode=284"
            . "`nOverlayType=3",
            "config.ini"
        )
    }
    DirCreate("layers")

    CONF := {}
    CONF.MS_NK := Integer(IniRead("config.ini", "Main", "NextKeyWaitDuration", 250))
    CONF.MS_LP := Integer(IniRead("config.ini", "Main", "LongPressDuration", 150))
    CONF.T := "T" . CONF.MS_LP / 1000
    CONF.min_gesture_len := Integer(IniRead("config.ini", "Main", "MinGestureLen", 150))
    CONF.min_cos_similarity := Float(IniRead("config.ini", "Main", "MinCosSimilarity", 0.90))
    CONF.wheel_unlock_time := Integer(IniRead("config.ini", "Main", "WheelLRUnlockTime", 150))
    CONF.layout_format := IniRead("config.ini", "Main", "LayoutFormat", "ANSI")
    CONF.extra_k_row := Integer(IniRead("config.ini", "Main", "ExtraKRow", 0))
    CONF.extra_f_row := Integer(IniRead("config.ini", "Main", "ExtraFRow", 0))
    CONF.help_texts := Integer(IniRead("config.ini", "Main", "HelpTexts", 0))
    CONF.gui_alt_ignore := Integer(IniRead("config.ini", "Main", "GuiAltIgnore", 1))
    CONF.hide_mouse_warnings := Integer(IniRead("config.ini", "Main", "HideMouseWarnings", 0))
    CONF.keyname_type := Integer(IniRead("config.ini", "Main", "KeynameType", 1))
    CONF.ref_height := Integer(IniRead("config.ini", "Main", "ReferenceHeight", 314))
    CONF.font_name := IniRead("config.ini", "Main", "FontName", "Segoe UI")
    CONF.gest_color := IniRead("config.ini", "Main", "GestureColor", "0x0000FF")
    CONF.font_scale := Float(IniRead("config.ini", "Main", "FontScale", 1))
    CONF.gui_scale := Float(IniRead(
        "config.ini", "Main", "GuiScale", scale_defaults.Get(A_ScreenWidth, 1.0)
    ))
    CONF.gui_back_sc := IniRead("config.ini", "Main", "GuiBack", 74)
    CONF.gui_set_sc := IniRead("config.ini", "Main", "GuiSet", 78)
    CONF.gui_set_hold_sc := IniRead("config.ini", "Main", "GuiSetHold", 284)
    CONF.overlay_type := Integer(IniRead("config.ini", "Main", "OverlayType", 3))
    CONF.unfam_layouts := Integer(IniRead("config.ini", "Main", "CollectUnfamiliarLayouts", 0))
    CONF.ignore_inactive := Integer(IniRead("config.ini", "Main", "IgnoreInactiveLayers", 0))

    if !IniRead("config.ini", "Main", "UserLayouts") {
        TrackLayouts()
        WinWaitClose(layout_gui.Hwnd)
        return
    }

    for lang in StrSplit(IniRead("config.ini", "Main", "UserLayouts"), ",") {
        lang := Integer(lang)
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
        "Text", "Center w400", "Initial setup. Switch between all your language layouts."
    )
    layout_gui.Add("Text", "Center w400 vCnt", "Found: 0")
    layout_gui.Show("AutoSize")

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

    tabs := s_gui.Add("Tab3", "x10 y0", ["Main", "GUI"])

    tabs.UseTab("Main")

    str_settings := [
        ["LongPressDuration Number", "Hold threshold (ms):", CONF.MS_LP],
        ["NextKeyWaitDuration Number", "Nested event waiting time (ms):", CONF.MS_NK],
        ["WheelLRUnlockTime Number", "Unlock l/r mouse wheel (ms):", CONF.wheel_unlock_time],
        ["MinGestureLen Number", "Gesture min length:", CONF.min_gesture_len],
        ["MinCosSimilarity Number", "Gesture min similarity:", Round(CONF.min_cos_similarity, 2)],
        ["GestureColor", "Gesture color (BGR):", CONF.gest_color],
    ]

    for arr in str_settings {
        s_gui.Add("Text", "x20 y+13 h20 w190", arr[2])
        s_gui.Add("Edit", "Center x+0 yp-2 h20 w180 v" . arr[1], arr[3])
    }

    ddl_settings := [
        ["LayoutFormat", "Layout format:", ["ANSI", "ISO"], 1, CONF.layout_format],
    ]

    for arr in ddl_settings {
        double := StrLen(arr[2]) > 35
        s_gui.Add("Text", "x20 y+" . (double ? 5 : 15) . " h45 w180", arr[2])
        elem := s_gui.Add("DropDownList",
            "x+10 yp" . (double ? 10 : 0) . " w180 v" . arr[1], arr[3])
        if arr[4] {
            elem.Text := arr[5]
        } else {
            elem.Value := arr[5]
        }
    }

    chb_main := [
        ["ExtraFRow", "Use extra &f-row (13-24)", CONF.extra_f_row],
        ["ExtraKRow", "Use &special keys (media, browser, apps)", CONF.extra_k_row],
        ["CollectUnfamiliarLayouts", "Collect unfamiliar kbd &layouts from layers",
            CONF.unfam_layouts],
    ]

    for arr in chb_main {
        s_gui.Add("CheckBox", "x20 w360 h20 y+10 v" . arr[1], arr[2]).Value := arr[3]
    }

    s_gui.Add("Button", "x20 y+10 h20 w20", "?").OnEvent("Click",
        (*) => (MsgBox("With this option, the program doesn’t parse inactive layer values "
            . "into a core structure. "
            . "`nTurn off only temporarily for work with GUI to view cross-values for all layers. "
            . "`n⚠Turn on after adjusting the layers.", "Ignore inactive layers", "Iconi")))
    s_gui.Add("CheckBox", "x+3 w330 yp+0 h20 vIgnoreInactiveLayers", "&Ignore inactive layers")
        .Value := CONF.ignore_inactive

    s_gui.Add("Button", "Center x20 y+15 w360 h20", "Reread system layouts")
        .OnEvent("Click", TrackLayouts)

    tabs.UseTab("GUI")

    ddl_gui := [
        ["KeynameType", "Keyname type:",
            ["Always use keynames", "Always use scancodes", "Scancodes on empty keys"],
            0, CONF.keyname_type],
        ["OverlayType", "Indicator overlay type:", ["Disabled", "Indicators only", "With counters"],
            0, CONF.overlay_type],
    ]

    for arr in ddl_gui {
        double := StrLen(arr[2]) > 23
        s_gui.Add("Text", "x20 y+" . (double ? 3 : 10) . " h45 w180", arr[2])
        elem := s_gui.Add("DropDownList",
            "Center x+10 yp" . (double ? 10 : 0) . " w180 v" . arr[1], arr[3])
        if arr[4] {
            elem.Text := arr[5]
        } else {
            elem.Value := arr[5]
        }
    }

    str_gui := [
        ["GuiScale", "Gui scale:", Round(CONF.gui_scale, 2)],
        ["FontScale", "Font scale:", Round(CONF.font_scale, 2)],
        ["FontName", "Font name:", CONF.font_name],
        ["ReferenceHeight Number", "Reference height:", CONF.ref_height],
        ["GuiBackEdit", "'Back' action GUI hotkey:", ""],
        ["GuiSetEdit", "…'Set tap' action:", ""],
        ["GuiSetHoldEdit", "…'Set hold' action:", ""],
    ]

    for arr in str_gui {
        s_gui.Add("Text", "x20 y+13 h20 w180", arr[2])
        s_gui.Add("Edit", "Center x+10 yp-2 h20 w180 v" . arr[1], arr[3])
    }

    s_gui["GuiBackEdit"].Text := _GetKeyName(CONF.gui_back_sc)
    s_gui["GuiSetEdit"].Text := _GetKeyName(CONF.gui_set_sc)
    s_gui["GuiSetHoldEdit"].Text := _GetKeyName(CONF.gui_set_hold_sc)

    chb_gui := [
        ["HelpTexts", "Show &help texts", CONF.help_texts],
        ["GuiAltIgnore", "Ignore physical &Alt presses on the GUI", CONF.gui_alt_ignore],
        ["HideMouseWarnings", "Hide warnings about disabling drag &behavior for LBM/RBM/MBM",
            CONF.hide_mouse_warnings],
    ]

    for arr in chb_gui {
        y := A_Index == 1 ? " y15 " : " y+10 "
        h := StrLen(arr[2]) > 44 ? " h44 " : " h20 "
        s_gui.Add("CheckBox", "x20 w360" . h . "y+10 v" . arr[1], arr[2]).Value := arr[3]
    }

    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiBack", CONF.gui_back_sc)
    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiSet", CONF.gui_set_sc)
    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiSetHold", CONF.gui_set_hold_sc)

    s_gui.Show()
    DllCall("SetFocus", "ptr", s_gui["ExtraFRow"].Hwnd)
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

    old_extra_f := CONF.extra_f_row
    old_extra_k := CONF.extra_k_row

    for name in [  ; texts/numbers
        "LayoutFormat", "LongPressDuration", "NextKeyWaitDuration", "WheelLRUnlockTime",
        "MinGestureLen", "MinCosSimilarity", "GestureColor", "GuiScale", "FontScale",
        "FontName", "ReferenceHeight", "GuiBack", "GuiSet", "GuiSetHold"
    ] {
        IniWrite(s_gui[name].Text, "config.ini", "Main", name)
    }

    for name in [  ; checkboxes/ddl values
        "HelpTexts", "KeynameType", "OverlayType", "GuiAltIgnore", "HideMouseWarnings",
        "CollectUnfamiliarLayouts", "IgnoreInactiveLayers", "ExtraKRow", "ExtraFRow"
    ] {
        val := s_gui[name].Value
        IniWrite(val, "config.ini", "Main", name)
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

    if old_extra_f !== CONF.extra_f_row || old_extra_k !== CONF.extra_k_row {
        Run(A_ScriptFullPath)  ; rerun with new keys
    }
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