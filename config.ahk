CoordMode "Mouse", "Screen"
A_HotkeyInterval := 0
version := 0
s_gui := false

CONF := {Main: [], GUI: [], Gestures: [], GestureDefaults: []}

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


class ConfValue {
    __New(sect, ini_name, form_type, val_type, def_val, descr, double_height, is_num, extra) {
        this.ini_name := ini_name
        this.form_type := form_type
        this.val_type := val_type
        this.default := def_val
        this.descr := descr
        this.double_height := double_height
        this.is_num := is_num
        this.extra_params := extra

        this.v := IniRead("config.ini", sect, ini_name, def_val)

        if val_type == "int" {
            this.v := Integer(this.v)
        } else if val_type == "float" {
            this.v := Round(Float(this.v), 2)
        }
        CONF.%sect%.Push(this)
    }
}


CheckConfig() {
    static scale_defaults:=Map(
        1366, 1.1, 1920, 1.1, 1440, 1.15, 1536, 1.2, 1600, 1.25, 2560, 1.25, 3840, 1.5
    )

    if !FileExist("config.ini") {
        FileAppend(
            "[Main]`n"
            . "ActiveLayers=`n"
            . "UserLayouts=`n"
            . "`n[GUI]`n"
            . "`n[Gestures]`n"
            . "`n[GestureDefaults]`n"
            , "config.ini"
        )
    }
    DirCreate("layers")


    CONF.MS_LP := ConfValue("Main", "LongPressDuration", "str", "int", 150,
            "Hold threshold (ms):", 0, 1, [])
    CONF.MS_NK := ConfValue("Main", "NextKeyWaitDuration", "str", "int", 300,
            "Nested event waiting time (ms):", 0, 1, [])

    CONF.T := "T" . CONF.MS_LP.v / 1000

    CONF.wheel_unlock_time := ConfValue("Main", "WheelLRUnlockTime", "str", "int", 150,
            "Unlock l/r mouse wheel (ms):", 0, 1, [])
    CONF.layout_format := ConfValue("Main", "LayoutFormat", "ddl", "str", "ANSI",
            "Layout format:", 0, 0,
            [["ANSI", "ISO"], true])
    CONF.extra_f_row := ConfValue("Main", "ExtraFRow", "checkbox", "int", 0,
            "Use extra &f-row (13-24)", 0, 0, [])
    CONF.extra_k_row := ConfValue("Main", "ExtraKRow", "checkbox", "int", 0,
            "Use &special keys (media, browser, apps)", 0, 0, [])
    CONF.unfam_layouts := ConfValue("Main", "CollectUnfamiliarLayouts", "checkbox", "int", 0,
            "Collect unfamiliar kbd &layouts from layers", 0, 0, [])
    CONF.sendtext_output := ConfValue("Main", "UseSendTextOutput", "h_checkbox", "int", 0,
            "Use Send&Text mode", 0, 0,
            ["Temporary test option."
                . "`nTo minimize bugs with sticking and inputting unwanted characters "
                . "when over-holding a hotkey with long text assignment, the SendInput {Raw} is "
                . "currently in test use. If this leads to undesirable consequences, turn on this "
                . "option to return to usual SendText and report to Issues.", "Use SendText mode"
            ])
    CONF.ignore_inactive := ConfValue("Main", "IgnoreInactiveLayers", "h_checkbox", "int", 0,
            "&Ignore inactive layers", 0, 0,
            ["With this option, the program doesn’t parse "
                . "inactive layer values into a core structure."
                . "`nTurn off only temporarily for work with GUI to view cross-values for all "
                . "layers.`n⚠Turn on after adjusting the layers.", "Ignore inactive layers"
            ])
    CONF.start_minimized := ConfValue("Main", "StartMinimized", "checkbox", "int", 0,
            "Start &minimized", 0, 0, [])

    CONF.keyname_type := ConfValue("GUI", "KeynameType", "ddl", "int", 1,
            "Keyname type:", 0, 0,
            [["Always use keynames", "Always use scancodes", "Scancodes on empty keys"], false])
    CONF.overlay_type := ConfValue("GUI", "OverlayType", "ddl", "int", 3,
            "Indicator overlay type:", 0, 0,
            [["Disabled", "Indicators only", "With counters"], false])
    CONF.gui_scale := ConfValue("GUI", "GuiScale", "str", "float",
            scale_defaults.Get(A_ScreenWidth, 1.0), "Gui scale:", 0, 0, [])
    CONF.font_scale := ConfValue("GUI", "FontScale", "str", "float", 1,
            "Font scale:", 0, 0, [])
    CONF.font_name := ConfValue("GUI", "FontName", "str", "str", "Segoe UI",
            "Font name:", 0, 0, [])
    CONF.ref_height := ConfValue("GUI", "ReferenceHeight", "str", "int", 314,
            "Reference height:", 0, 1, [])
    CONF.gui_back_sc := ConfValue("GUI", "GuiBackEdit", "str", "str", 74,
            "'Back' action GUI hotkey:", 0, 0, [])
    CONF.gui_set_sc := ConfValue("GUI", "GuiSetEdit", "str", "str", 78,
            "…'Set tap' action:", 0, 0, [])
    CONF.gui_set_hold_sc := ConfValue("GUI", "GuiSetHoldEdit", "str", "str", 284,
            "…'Set hold' action:", 0, 0, [])
    CONF.help_texts := ConfValue("GUI", "HelpTexts", "checkbox", "int", 0,
            "Show &help texts", 0, 0, [])
    CONF.gui_alt_ignore := ConfValue("GUI", "GuiAltIgnore", "checkbox", "int", 1,
            "Ignore physical &Alt presses on the GUI", 0, 0, [])
    CONF.hide_mouse_warnings := ConfValue("GUI", "HideMouseWarnings", "checkbox", "int", 0,
            "Hide warnings about disabling drag &behavior for LBM/RBM/MBM", 1, 0, [])

    CONF.gest_color_mode := ConfValue("Gestures", "ColorMode", "ddl", "str", "HSV",
            "Color mode:", 0, 0,
            [["RGB", "Gamma-correct", "HSV"], true])
    CONF.edge_gestures := ConfValue("Gestures", "EdgeGestures", "ddl", "int", 4,
            "Use edge gestures:", 0, 0,
            [["No", "With edges", "With corners", "With edges and corners"], false])
    CONF.edge_size := ConfValue("Gestures", "EdgeSize", "str", "int", 100,
            "Edge definition width:", 0, 1, [])
    CONF.min_gesture_len := ConfValue("Gestures", "MinGestureLen", "str", "int", 150,
            "Gesture min length:", 0, 1, [])
    CONF.min_cos_similarity := ConfValue("Gestures", "MinCosSimilarity", "str", "float", 0.90,
            "Gesture min similarity:", 0, 0, [])
    CONF.overlay_opacity := ConfValue("Gestures", "OverlayOpacity", "str", "int", 200,
            "Overlay opacity (up to 255):", 0, 1, [])
    CONF.font_size_lh := ConfValue("Gestures", "LHSize", "str", "int", 32,
            "Font size on live hint:", 0, 1, [])
    CONF.live_hint_extended := ConfValue("Gestures", "LiveHintExtended", "checkbox", "int", 1,
            "Show unrecognized gestures on live hint", 0, 0, [])

    CONF.gest_rotate := ConfValue("GestureDefaults", "Rotate", "ddl", "int", 1,
            "Rotate:", 0, 0,
            [["No", "Remove orientation noise", "Orientation invariance"], false])
    CONF.scale_impact := ConfValue("GestureDefaults", "Scaling", "str", "float", 0,
            "Scale impact:", 0, 0, [])
    CONF.gest_live_hint := ConfValue("GestureDefaults", "LiveHint", "ddl", "int", 1,
            "Live recognition hint position:", 0, 0,
            [["Top", "Center", "Bottom", "Disabled"], false])

    CONF.gest_colors := [
        ConfValue("GestureDefaults", "GestureColors", "str", "str", "random(3)",
            "Gesture colors`n(more than one for gradient):", 1, 0, []),
        ConfValue("GestureDefaults", "GestureColorsEdges", "str", "str", "4FC3F7,9575CD,F06292",
            "Gesture colors`n(more than one for gradient):", 1, 0, []),
        ConfValue("GestureDefaults", "GestureColorsCorners", "str", "str", "66BB6A,26C6DA,FBC02D",
            "Gesture colors`n(more than one for gradient):", 1, 0, []),
    ]
    CONF.grad_len := [
        ConfValue("GestureDefaults", "GradientLength", "str", "int", 1000,
            "Full gradient cycle length (px):", 0, 1, []),
        ConfValue("GestureDefaults", "GradientLengthEdges", "str", "int", 1000,
            "Full gradient cycle length (px):", 0, 1, []),
        ConfValue("GestureDefaults", "GradientLengthCorners", "str", "int", 1000,
            "Full gradient cycle length (px):", 0, 1, []),
    ]
    CONF.grad_loop := [
        ConfValue("GestureDefaults", "GradientLoop", "checkbox", "int", 1,
            "&Gradient cycling", 0, 0, []),
        ConfValue("GestureDefaults", "GradientLoopEdges", "checkbox", "int", 1,
            "&Gradient cycling", 0, 0, []),
        ConfValue("GestureDefaults", "GradientLoopCorners", "checkbox", "int", 1,
            "&Gradient cycling", 0, 0, []),
    ]

    if !IniRead("config.ini", "Main", "UserLayouts", "") {
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

    s_gui := Gui("-SysMenu", "Settings")
    s_gui.OnEvent("Close", CloseSettingsEvent)
    s_gui.OnEvent("Escape", CloseSettingsEvent)
    s_gui.SetFont("s9")

    s_gui.Add("Button", "Center x270 y0 w60 h18 Default vCancel", "❌ Cancel")
        .OnEvent("Click", CloseSettingsEvent)
    s_gui.Add("Button", "Center x335 y0 w60 h18 Default vApply", "✔ Accept")
        .OnEvent("Click", SaveConfig)

    tabs := s_gui.Add("Tab3", "x0 y0 w402 h666", ["Main", "GUI", "Gestures", "Gesture defaults"])

    tabs.UseTab("Main")
    for c in CONF.Main {
        _AddElems(c.form_type, A_Index == 1 ? 40 : "",
            [c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*])
    }
    s_gui.Add("Button", "Center x15 y+15 w370 h20", "Reread system layouts")
        .OnEvent("Click", TrackLayouts)

    tabs.UseTab("GUI")
    for c in CONF.GUI {
        _AddElems(c.form_type, A_Index == 1 ? 40 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }

    tabs.UseTab("Gestures")
    for c in CONF.Gestures {
        _AddElems(c.form_type, A_Index == 1 ? 40 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }

    tabs.UseTab("Gesture defaults")
    s_gui.Add("Text", "x20 w360 y34 h34 Center",
        "Default gesture matching and color options`n(can be overridden in each assignment)")
    s_gui.Add("Text", "x20 w360 y+8 h1 0x10")

    for c in CONF.GestureDefaults {
        if A_Index == 4 {
            break
        }
        _AddElems(c.form_type, A_Index == 1 ? 90 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }

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
                CONF.gest_colors[i].v],
            [0, "GradientLength" . name . " Number", "Full gradient cycle length (px):",
                CONF.grad_len[i].v],
        )
        _AddElems("checkbox",,
            [0, "GradientLoop" . name, "&Gradient cycling", CONF.grad_loop[i].v]
        )
        if i > 1 {
            s_gui["GestureColors" . name].Visible := false
            s_gui["GradientLength" . name].Visible := false
            s_gui["GradientLoop" . name].Visible := false
        }
    }

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
                    "x+10 yp" . (arr[1] ? 8 : -2) . " w180 v" . arr[2], arr[5])
                if arr[6] {
                    elem.Text := arr[4]
                } else {
                    elem.Value := arr[4]
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
                fn := MsgBox.Bind(arr[5], arr[6], "IconI")
                s_gui.Add("Button", "x11 y" . cur_h . " h20 w20", "?")
                    .OnEvent("Click",(*) => fn.Call())
                s_gui.Add("CheckBox", "x+3 w330 yp+0 h20 v" . arr[2], arr[3]).Value := arr[4]
                cur_h += h + _shift
            }
    }
}


PasteSCToInput(sc) {
    switch ControlGetFocus("A") {
        case s_gui["GuiBackEdit"].Hwnd:
            s_gui["GuiBackEdit"].Text := _GetKeyName(sc)
        case s_gui["GuiSetEdit"].Hwnd:
            s_gui["GuiSetEdit"].Text := _GetKeyName(sc)
        case s_gui["GuiSetHoldEdit"].Hwnd:
            s_gui["GuiSetHoldEdit"].Text := _GetKeyName(sc)
        default:
            return false
    }
    return true
}


SaveConfig(*) {
    global s_gui

    CancelChordEditing(0, true)

    b := CheckChanges()
    if b {
        if s_gui["ExtraFRow"].Value != CONF.extra_f_row.v
            || s_gui["ExtraKRow"].Value != CONF.extra_k_row.v
            || s_gui["UseSendTextOutput"].Value != CONF.sendtext_output.v {
            b := 2
        }

        if s_gui["IgnoreInactiveLayers"].Value != CONF.ignore_inactive.v {
            for layer in ActiveLayers.map {
                raw_roots := DeserializeMap(layer)
                AllLayers.map[layer] := _CountLangMappings(raw_roots)
            }
        }

        for name in ["Main", "GUI", "Gestures", "GestureDefaults"] {
            for elem in CONF.%name% {
                val := elem.form_type == "str" || elem.form_type == "ddl" && elem.val_type == "str"
                    ? s_gui[elem.ini_name].Text : s_gui[elem.ini_name].Value
                IniWrite(val, "config.ini", name, elem.ini_name)
                elem.v := elem.val_type == "int" ? Integer(val)
                    : elem.val_type == "float" ? Round(Float(val), 2) : val
            }
        }
    }

    s_gui.Destroy()
    s_gui := false
    if b == 2 {
        Run(A_ScriptFullPath)  ; rerun with new keys
    } else if b {
        DrawLayout()
    }
}


CheckChanges(*) {
    for name in ["Main", "GUI", "Gestures", "GestureDefaults"] {
        for elem in CONF.%name% {
            if elem.form_type == "str" || elem.form_type == "ddl" && elem.val_type == "str" {
                val := s_gui[elem.ini_name].Text
            } else {
                val := s_gui[elem.ini_name].Value
            }
            if val != elem.v {
                return true
            }
        }
    }
    return false
}


CloseSettingsEvent(*) {
    global s_gui

    if CheckChanges() && MsgBox("You have unsaved changes. Do you really want to close the window?",
        "Confirmation", "YesNo Icon?") == "No" {
        return true
    }
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