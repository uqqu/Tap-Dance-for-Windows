version := 0
SYS_MODIFIERS := Map(
    0x02A, "<+",
    0x136, ">+",
    0x036, ">+",
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
            . "`nHelpTexts=1"
            . "`nGuiAltIgnore=1"
            . "`nGuiScale=1.25"
            . "`nFontScale=1"
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
    CONF.help_texts := Integer(IniRead("config.ini", "Main", "HelpTexts", 1))
    CONF.gui_alt_ignore := Integer(IniRead("config.ini", "Main", "GuiAltIgnore", 1))
    CONF.font_scale := Float(IniRead("config.ini", "Main", "FontScale", 1))
    CONF.keyname_type := Integer(IniRead("config.ini", "Main", "KeynameType", 1))
    CONF.wide_mode := Integer(IniRead("config.ini", "Main", "WideMode", 0))
    CONF.gui_scale := Float(IniRead(
        "config.ini", "Main", "GuiScale", scale_defaults.Get(A_ScreenWidth, 1.0)
    ))
    CONF.gui_back_sc := Integer(IniRead("config.ini", "Main", "GuiBackScancode", "74"))
    CONF.gui_set_sc := Integer(IniRead("config.ini", "Main", "GuiSetScancode", "78"))
    CONF.gui_set_hold_sc := Integer(IniRead("config.ini", "Main", "GuiSetHoldScancode", "284"))
    CONF.overlay_type := Integer(IniRead("config.ini", "Main", "OverlayType", "3"))
    CONF.unfam_layouts := Integer(IniRead("config.ini", "Main", "CollectUnfamiliarLayouts", "0"))
    CONF.ignore_inactive := Integer(IniRead("config.ini", "Main", "IgnoreInactiveLayers", "0"))

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

    layout_gui := Gui("+AlwaysOnTop -SysMenu", "Layout Detector").SetFont("s10")
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
            str_value .= lang . ","
        }
        IniWrite(SubStr(str_value, 3, -1), "config.ini", "Main", "UserLayouts")
        Sleep(1000)
        layout_gui.Destroy()
    }
}


ShowSettings(*) {
    global s_gui

    try s_gui.Destroy()

    s_gui := Gui(, "Settings")
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
        (*) => (MsgBox("Don’t parse inactive layer values into a structure. "
            . "`nTurn off only temporarily for work with GUI to view cross-values for all layers. "
            . "`nTurn on after adjusting the layers", "IgnoreInactiveLayers", )))

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
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vLongPressDuration", CONF.MS_LP)

    s_gui.Add("Text", "x20 y+10 w160", "Next key wait dur. (ms):")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vNextKeyWaitDuration", CONF.MS_NK)

    s_gui.Add("Text", "x20 y+10 w160", "Gui scale:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiScale", Round(CONF.gui_scale, 2))

    s_gui.Add("Text", "x20 y+10 w160", "Font scale:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vFontScale", Round(CONF.font_scale, 2))

    s_gui.Add("Text", "x20 y+10 w160", "GUI 'Back' scancode:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiBack", CONF.gui_back_sc)

    s_gui.Add("Text", "x20 y+10 w160", "GUI 'Set' scancode:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiSet", CONF.gui_set_sc)

    s_gui.Add("Text", "x20 y+10 w160", "GUI 'Set hold' scancode:")
    s_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiSetHold", CONF.gui_set_hold_sc)

    s_gui.Add("Button", "Center x20 y+15 w320 h20", "Re-read langs").OnEvent("Click", TrackLayouts)

    s_gui.Add("Button", "Center x20 y+10 w320 h20 Default vApply", "✔ Apply")
        .OnEvent("Click", SaveConfig)

    s_gui.Show()
}


SaveConfig(*) {
    for name in [  ; texts
        "LayoutFormat", "LongPressDuration", "NextKeyWaitDuration", "GuiScale", "FontScale",
        "GuiBack", "GuiSet", "GuiSetHold"
    ] {
        IniWrite(s_gui[name].Text, "config.ini", "Main", name)
    }

    for name in [  ; checkboxes
        "HelpTexts", "WideMode", "KeynameType", "OverlayType", "GuiAltIgnore",
        "CollectUnfamiliarLayouts", "IgnoreInactiveLayers"
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
    CheckConfig()
    DrawLayout()
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