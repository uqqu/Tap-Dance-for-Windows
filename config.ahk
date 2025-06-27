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

BUFFER_SIZE := 48  ; 0x173 (372) is the last "standard" code; 8×48 = 384

SC_STR := []
SC_STR_BR := []
empty_scs := Map()
loop 511 {
    curr := Format("SC{:03X}", A_Index)
    SC_STR.Push(curr)
    SC_STR_BR.Push("{" . curr . "}")
    empty_scs[A_Index] := true
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
            . "`nWideMode=0"
            . "`nExtraFRow=0"
            . "`nExtraKRow=0"
            . "`nHelpTexts=1"
            . "`nHideMouseWarnings=0"
            . "`nIgnoreUnassignedUnderMods=1"
            . "`nIgnoreUnassignedNonRoot=0"
            . "`nGuiAltIgnore=1"
            . "`nGuiScale=1.25"
            . "`nFontScale=1"
            . "`nFontName=Segoe UI"
            . "`nReferenceHeight=314"
            . "`nKeynameType=1"
            . "`nActiveLayers="  ; TODO?
            . "`nLongPressDuration=150"
            . "`nNextKeyWaitDuration=250"
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
    CONF.wheel_unlock_time := Integer(IniRead("config.ini", "Main", "WheelLRUnlockTime", 150))
    CONF.layout_format := IniRead("config.ini", "Main", "LayoutFormat", "ANSI")
    CONF.extra_k_row := Integer(IniRead("config.ini", "Main", "ExtraKRow", 0))
    CONF.extra_f_row := Integer(IniRead("config.ini", "Main", "ExtraFRow", 0))
    CONF.help_texts := Integer(IniRead("config.ini", "Main", "HelpTexts", 1))
    CONF.gui_alt_ignore := Integer(IniRead("config.ini", "Main", "GuiAltIgnore", 1))
    CONF.hide_mouse_warnings := Integer(IniRead("config.ini", "Main", "HideMouseWarnings", 0))
    CONF.ignore_unassigned_under_mods := Integer(IniRead(
        "config.ini", "Main", "IgnoreUnassignedUnderMods", 1
    ))
    CONF.ignore_unassigned_non_root := Integer(IniRead(
        "config.ini", "Main", "IgnoreUnassignedNonRoot", 0
    ))
    CONF.keyname_type := Integer(IniRead("config.ini", "Main", "KeynameType", 1))
    CONF.ref_height := Integer(IniRead("config.ini", "Main", "ReferenceHeight", 314))
    CONF.wide_mode := Integer(IniRead("config.ini", "Main", "WideMode", 0))
    CONF.font_name := IniRead("config.ini", "Main", "FontName", "Segoe UI")
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
        LANGS.Add(hkl, GetLayoutNameFromHKL(hkl))
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

    s_gui.Add("Text", "x20 y15 h20 w160", "Layout format:")
    s_gui.Add("DropDownList", "Center x+10 yp-2 w160 vLayoutFormat", ["ANSI", "ISO"])
        .Text := CONF.layout_format

    s_gui.Add("Text", "x20 y+10 h20 w160", "Keyname type:")
    s_gui.Add("DropDownList", "Center x+10 yp-2 w160 vKeynameType",
        ["Always use keynames", "Always use scancodes", "Scancodes on empty keys"])
        .Value := CONF.keyname_type

    s_gui.Add("Text", "x20 y+10 h20 w160", "Overlay type:")
    s_gui.Add("DropDownList", "Center x+10 yp-2 w160 vOverlayType",
        ["Disabled", "Indicators only", "With counters"])
        .Value := CONF.overlay_type

    str_settings := [
        ["LongPressDuration Number", "Longpress duration (ms):", CONF.MS_LP],
        ["NextKeyWaitDuration Number", "Next key wait dur. (ms):", CONF.MS_NK],
        ["WheelLRUnlockTime Number", "Unlock l/r mouse wheel after (ms):", CONF.wheel_unlock_time],
        ["GuiScale", "Gui scale:", Round(CONF.gui_scale, 2)],
        ["FontScale", "Font scale:", Round(CONF.font_scale, 2)],
        ["FontName", "Font name:", CONF.font_name],
        ["ReferenceHeight Number", "Reference height:", CONF.ref_height],
        ["GuiBackEdit", "'Back' action GUI hotkey:", ""],
        ["GuiSetEdit", "…'Set tap' action:", ""],
        ["GuiSetHoldEdit", "…'Set hold' action:", ""],
    ]

    for arr in str_settings {
        s_gui.Add("Text", "x20 y+13 h20 w160", arr[2])
        s_gui.Add("Edit", "Center x+10 yp-2 h20 w160 v" . arr[1], arr[3])
    }

    s_gui["GuiBackEdit"].Text := _GetKeyName(CONF.gui_back_sc)
    s_gui["GuiSetEdit"].Text := _GetKeyName(CONF.gui_set_sc)
    s_gui["GuiSetHoldEdit"].Text := _GetKeyName(CONF.gui_set_hold_sc)


    chb_settings := [
        ["ExtraFRow", "Show extra &f-row (13-24)", CONF.extra_f_row, 0],
        ["ExtraKRow", "Show &special keys (media, browser, apps)", CONF.extra_k_row, 0],
        ["HelpTexts", "Show &help texts", CONF.help_texts, 0],
        ["WideMode", "Enable &wide mode", CONF.wide_mode, 0],
        ["GuiAltIgnore", "Ignore phisical &Alt presses on the GUI", CONF.gui_alt_ignore, 0],
        ["IgnoreUnassignedUnderMods",
            "Ignore unassigned kbd events when pressing with &modifiers (empty action)",
            CONF.ignore_unassigned_under_mods, 1],
        ["IgnoreUnassignedNonRoot",
            "Ignore unassigned kbd events when pressing from &deep within the chain (empty action)",
            CONF.ignore_unassigned_non_root, 1],
        ["HideMouseWarnings", "Hide warnings about disabling drag &behavior for LBM/RBM/MBM",
            CONF.hide_mouse_warnings, 1],
        ["CollectUnfamiliarLayouts", "Collect unfamiliar &layouts (langs) from layers",
            CONF.unfam_layouts, 0],
    ]

    for arr in chb_settings {
        y := A_Index == 1 ? " y15 " : " y+10 "
        h := arr[4] ? " h41 " : " h20 "
        s_gui.Add("CheckBox", "x380 w295" . h . y . "v" . arr[1], arr[2]).Value := arr[3]
    }

    s_gui.Add("Button", "x380 y+10 h20 w20", "?").OnEvent("Click",
        (*) => (MsgBox("With this option, the program doesn’t parse inactive layer values "
            . "into a core structure. "
            . "`nTurn off only temporarily for work with GUI to view cross-values for all layers. "
            . "`n⚠Turn on after adjusting the layers.", "Ignore inactive layers", "Iconi")))
    s_gui.Add("CheckBox", "x+3 w260 yp+0 h20 vIgnoreInactiveLayers", "&Ignore inactive layers")
        .Value := CONF.ignore_inactive

    s_gui.Add("Button", "Center x20 y+45 w330 h20", "Reread system langs")
        .OnEvent("Click", TrackLayouts)
    s_gui.Add("Button", "Center x+30 yp+0 w320 h20 Default vApply", "✔ Apply")
        .OnEvent("Click", SaveConfig)

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

    old_extra_f := CONF.extra_f_row
    old_extra_k := CONF.extra_k_row

    for name in [  ; texts/numbers
        "LayoutFormat", "LongPressDuration", "NextKeyWaitDuration", "WheelLRUnlockTime",
        "GuiScale", "FontScale", "FontName", "ReferenceHeight", "GuiBack", "GuiSet", "GuiSetHold"
    ] {
        IniWrite(s_gui[name].Text, "config.ini", "Main", name)
    }

    for name in [  ; checkboxes
        "HelpTexts", "WideMode", "KeynameType", "OverlayType", "GuiAltIgnore", "HideMouseWarnings",
        "IgnoreUnassignedUnderMods", "IgnoreUnassignedNonRoot",
        "CollectUnfamiliarLayouts", "IgnoreInactiveLayers", "ExtraKRow", "ExtraFRow"
    ] {
        IniWrite(s_gui[name].Value, "config.ini", "Main", name)
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