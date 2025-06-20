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

TYPES := {}
TYPES_R := ["Disabled", "Default", "Text", "KeySimulation", "Function", "Modifier", "Chord"]
for i, v in TYPES_R {
    TYPES.%v% := i
}

BUFFER_SIZE := 48  ; 0x173 (372) is the last "standard" code; 8×48 = 384

SC_STR := []
SC_STR_BR := []
loop 511 {
    curr := Format("SC{:03X}", A_Index)
    SC_STR.Push(curr)
    SC_STR_BR.Push("{" . curr . "}")
}

LANGS := OrderedMap()
LANGS.Add(0, "Global")

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
            . "`nHelpTexts=1"
            . "`nGuiAltIgnore=1"
            . "`nGuiScale=1.25"
            . "`nFontScale=1"
            . "`nReferenceHeight=314"
            . "`nKeynameType=1"
            . "`nActiveLayers="  ; TODO?
            . "`nLongPressDuration=150"
            . "`nNextKeyWaitDuration=250"
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
    CONF.layout_format := IniRead("config.ini", "Main", "LayoutFormat", "ANSI")
    CONF.extra_k_row := Integer(IniRead("config.ini", "Main", "ExtraKRow", 0))
    CONF.extra_f_row := Integer(IniRead("config.ini", "Main", "ExtraFRow", 0))
    CONF.help_texts := Integer(IniRead("config.ini", "Main", "HelpTexts", 1))
    CONF.gui_alt_ignore := Integer(IniRead("config.ini", "Main", "GuiAltIgnore", 1))
    CONF.keyname_type := Integer(IniRead("config.ini", "Main", "KeynameType", 1))
    CONF.ref_height := Integer(IniRead("config.ini", "Main", "ReferenceHeight", 314))
    CONF.wide_mode := Integer(IniRead("config.ini", "Main", "WideMode", 0))
    CONF.font_scale := Float(IniRead("config.ini", "Main", "FontScale", 1))
    CONF.gui_scale := Float(IniRead(
        "config.ini", "Main", "GuiScale", scale_defaults.Get(A_ScreenWidth, 1.0)
    ))
    CONF.gui_back_sc := Integer(IniRead("config.ini", "Main", "GuiBack", 74))
    CONF.gui_set_sc := Integer(IniRead("config.ini", "Main", "GuiSet", 78))
    CONF.gui_set_hold_sc := Integer(IniRead("config.ini", "Main", "GuiSetHold", 284))
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
        LANGS.Add(lang, GetLayoutNameFromHKL(lang))
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

    s_gui.Add("CheckBox", "x20 y15 w140 vHelpTexts", "Show help texts").Value := CONF.help_texts
    s_gui.Add("CheckBox", "x+30 yp-2 w140 vWideMode", "Enable wide mode").Value := CONF.wide_mode

    s_gui.Add("CheckBox", "x20 y+10 w280 vGuiAltIgnore",
        "Ignore phisical Alt presses on the GUI")
        .Value := CONF.gui_alt_ignore

    s_gui.Add("CheckBox", "x20 y+0 w290 vCollectUnfamiliarLayouts",
        "Collect unfamiliar layouts (langs) from layers")
        .Value := CONF.unfam_layouts

    s_gui.Add("CheckBox", "x20 y+0 w280 vIgnoreInactiveLayers",
        "Ignore inactive layers")
        .Value := CONF.ignore_inactive
    s_gui.Add("Button", "x+10 yp-5", "?").OnEvent("Click",
        (*) => (MsgBox("With this option, the program doesn’t parse inactive layer values "
            . "into a core structure. "
            . "`nTurn off only temporarily for work with GUI to view cross-values for all layers. "
            . "`n⚠Turn on after adjusting the layers.", "IgnoreInactiveLayers")))

    s_gui.Add("CheckBox", "x20 y+1 w280 vExtraKRow", "Show extra keys (media, browser, apps)")
        .Value := CONF.extra_k_row
    s_gui.Add("CheckBox", "x20 y+0 w280 vExtraFRow", "Show extra f-row (13-24)")
        .Value := CONF.extra_f_row

    s_gui.Add("Text", "x20 y+10 w160", "Layout format:")
    s_gui.Add("DropDownList", "Center x+10 yp-2 w160 vLayoutFormat", ["ANSI", "ISO"])
        .Text := CONF.layout_format

    s_gui.Add("Text", "x20 y+10 w160", "Keyname type:")
    s_gui.Add("DropDownList", "Center x+10 yp-2 w160 vKeynameType",
        ["Always use keynames", "Always use scancodes", "Scancodes on empty keys"])
        .Value := CONF.keyname_type

    s_gui.Add("Text", "x20 y+10 w160", "Overlay type:")
    s_gui.Add("DropDownList", "Center x+10 yp-2 w160 vOverlayType",
        ["Disabled", "Indicators only", "With counters"])
        .Value := CONF.overlay_type

    s_gui.Add("Text", "x20 y+10 w160", "Longpress duration (ms):")
    s_gui.Add("Edit", "Center Number x+10 yp-2 w160 vLongPressDuration", CONF.MS_LP)

    s_gui.Add("Text", "x20 y+10 w160", "Next key wait dur. (ms):")
    s_gui.Add("Edit", "Center Number x+10 yp-2 w160 vNextKeyWaitDuration", CONF.MS_NK)

    s_gui.Add("Text", "x20 y+10 w160", "Gui scale:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiScale", Round(CONF.gui_scale, 2))

    s_gui.Add("Text", "x20 y+10 w160", "Font scale:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vFontScale", Round(CONF.font_scale, 2))

    s_gui.Add("Text", "x20 y+10 w160", "Reference height:")
    s_gui.Add("Edit", "Center Number x+10 yp-2 w160 vReferenceHeight", CONF.ref_height)

    s_gui.Add("Text", "x20 y+10 w160", "'Back' action GUI hotkey:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiBackEdit", _GetKeyName(CONF.gui_back_sc))

    s_gui.Add("Text", "x20 y+10 w160", "…'Set tap' action:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiSetEdit", _GetKeyName(CONF.gui_set_sc))

    s_gui.Add("Text", "x20 y+10 w160", "…'Set hold' action:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiSetHoldEdit", _GetKeyName(CONF.gui_set_hold_sc))

    s_gui.Add("Button", "Center x20 y+15 w320 h20", "Reread system langs")
        .OnEvent("Click", TrackLayouts)

    s_gui.Add("Button", "Center x20 y+10 w320 h20 Default vApply", "✔ Apply")
        .OnEvent("Click", SaveConfig)

    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiBack", CONF.gui_back_sc)
    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiSet", CONF.gui_set_sc)
    s_gui.Add("Edit", "Center x-1000 y-1000 w0 h0 vGuiSetHold", CONF.gui_set_hold_sc)

    s_gui.Show()
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
    old_extra_f := CONF.extra_f_row
    old_extra_k := CONF.extra_k_row

    for name in [  ; texts/numbers
        "LayoutFormat", "LongPressDuration", "NextKeyWaitDuration", "GuiScale", "FontScale",
        "ReferenceHeight", "GuiBack", "GuiSet", "GuiSetHold"
    ] {
        IniWrite(s_gui[name].Text, "config.ini", "Main", name)
    }

    for name in [  ; checkboxes
        "HelpTexts", "WideMode", "KeynameType", "OverlayType", "GuiAltIgnore",
        "ExtraKRow", "ExtraFRow", "CollectUnfamiliarLayouts", "IgnoreInactiveLayers"
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