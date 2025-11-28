CoordMode "Mouse", "Screen"
A_HotkeyInterval := 0
version := 0
s_gui := false
is_updating := false

saved_level := false
buffer_view := 0

CONF := {
    Main: [],
    GUI: [],
    Gestures: [],
    GestureDefaults: [],
    Colors: []
}

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

ONLY_BASE_SCS := Map()
for name in ["Volume_Mute", "Volume_Down", "Volume_Up", "Media_Next", "Media_Prev", "Media_Stop",
    "Media_Play_Pause", "Browser_Back", "Browser_Forward", "Browser_Refresh", "Browser_Stop",
    "Browser_Search", "Browser_Favorites", "Browser_Home", "Launch_Mail", "Launch_Media",
    "Launch_App1", "Launch_App2"] {
    ONLY_BASE_SCS[GetKeySC(name)] := true
}
for name in ["WheelLeft", "WheelDown", "WheelUp", "WheelRight"] {
    ONLY_BASE_SCS[name] := true
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

first_start := CheckConfig()
CurrentLayout := GetCurrentLayout()
ReadLayers()
FillRoots()
UpdLayers()

if first_start {
    SetTimer(ShowSettings, -1000)
}


class ConfValue {
    __New(
        sect, ini_name, form_type, val_type, descr, default_val,
        is_num:=false, double_height:=false, extra:=false
    ) {
        this.ini_name := ini_name
        this.form_type := form_type
        this.val_type := val_type
        this.default := default_val
        this.descr := descr
        this.is_num := is_num
        this.double_height := double_height
        this.extra_params := extra || []

        this.v := IniRead("config.ini", sect, ini_name, default_val)

        if val_type == "int" {
            this.v := Integer(this.v)
        } else if val_type == "float" {
            this.v := Round(Float(this.v), 2)
        }
        CONF.%sect%.Push(this)
    }
}


CheckConfig() {
    if !FileExist("config.ini") {
        FileAppend(
            "[Main]`n"
            . "ActiveLayers=`n"
            . "UserLayouts=`n"
            . "`n[GUI]`n"
            . "`n[Gestures]`n"
            . "`n[GestureDefaults]`n"
            . "`n[Colors]`n"
            , "config.ini"
        )
    }
    DirCreate("layers")


    CONF.MS_LP := ConfValue("Main", "LongPressDuration", "str", "int",
        "Hold threshold (ms):", 150, true)
    CONF.MS_NK := ConfValue("Main", "NextKeyWaitDuration", "str", "int",
        "Nested event waiting time (ms):", 300, true)

    CONF.T := "T" . CONF.MS_LP.v / 1000

    CONF.wheel_unlock_time := ConfValue("Main", "WheelLRUnlockTime", "str", "int",
        "Unlock l/r mouse wheel (ms):", 150, true)
    CONF.layout_format := ConfValue("Main", "LayoutFormat", "ddl", "str",
        "Layout format:", "ANSI", , , [["ANSI", "ISO"], true])
    CONF.extra_f_row := ConfValue("Main", "ExtraFRow", "checkbox", "int",
        "Use extra &f-row (13-24)", 0)
    CONF.extra_k_row := ConfValue("Main", "ExtraKRow", "checkbox", "int",
        "Use &special keys (media, browser, apps)", 0)
    CONF.unfam_layouts := ConfValue("Main", "CollectUnfamiliarLayouts", "checkbox", "int",
        "Collect unfamiliar kbd &layouts from layers", 0)
    CONF.sendtext_output := ConfValue("Main", "UseSendTextOutput", "h_checkbox", "int",
        "Use Send&Text mode", 0, , ,
        ["Temporary test option."
            . "`nTo minimize bugs with sticking and inputting unwanted characters "
            . "when over-holding a hotkey with long text assignment, the SendInput {Raw} is "
            . "currently in test use. If this leads to undesirable consequences, turn on this "
            . "option to return to usual SendText and report to Issues.", "Use SendText mode"
        ])
    CONF.ignore_inactive := ConfValue("Main", "IgnoreInactiveLayers", "h_checkbox", "int",
        "&Ignore inactive layers", 0, , ,
        ["With this option, the program doesn’t parse "
            . "inactive layer values into a core structure."
            . "`nTurn off only temporarily for work with GUI to view cross-values for all "
            . "layers.`n⚠Turn on after adjusting the layers.", "Ignore inactive layers"
        ])
    CONF.start_minimized := ConfValue("Main", "StartMinimized", "checkbox", "int",
        "Start &minimized", 0)

    CONF.keyname_type := ConfValue("GUI", "KeynameType", "ddl", "int",
        "Keyname type:", 1, , ,
        [["Always use keynames", "Always use scancodes", "Scancodes on empty keys"], false])
    CONF.overlay_type := ConfValue("GUI", "OverlayType", "ddl", "int",
        "Indicator overlay type:", 3, , ,
        [["Disabled", "Indicators only", "With counters"], false])
    CONF.gui_scale := ConfValue("GUI", "GuiScale", "str", "float",
        "Gui scale:", A_ScreenWidth * 0.8 / 1294)
    CONF.font_scale := ConfValue("GUI", "FontScale", "str", "float",
        "Font scale:", CONF.gui_scale.v / 2 + 0.5)
    CONF.font_name := ConfValue("GUI", "FontName", "str", "str",
        "Font name:", "Segoe UI")
    CONF.ref_height := ConfValue("GUI", "ReferenceHeight", "str", "int",
        "Reference height:", 314, true)
    CONF.gui_back_sc := ConfValue("GUI", "GuiBackEdit", "str", "str",
        "'Back' action GUI hotkey:", "nSub")
    CONF.gui_set_sc := ConfValue("GUI", "GuiSetEdit", "str", "str",
        "…'Set tap' action:", "nAdd")
    CONF.gui_set_hold_sc := ConfValue("GUI", "GuiSetHoldEdit", "str", "str",
        "…'Set hold' action:", "nEnter")
    CONF.help_texts := ConfValue("GUI", "HelpTexts", "checkbox", "int",
        "Show &help texts", 0)
    CONF.gui_alt_ignore := ConfValue("GUI", "GuiAltIgnore", "checkbox", "int",
        "Ignore physical &Alt presses on the GUI", 1)
    CONF.hide_mouse_warnings := ConfValue("GUI", "HideMouseWarnings", "checkbox", "int",
        "Hide warnings about disabling drag &behavior for LMB/RMB/MMB", 0)

    CONF.gest_color_mode := ConfValue("Gestures", "ColorMode", "ddl", "str",
        "Color mode:", "HSV", , , [["RGB", "Gamma-correct", "HSV"], true])
    CONF.edge_gestures := ConfValue("Gestures", "EdgeGestures", "ddl", "int",
        "Use edge gestures:", 4, , ,
        [["No", "With edges", "With corners", "With edges and corners"], false])
    CONF.edge_size := ConfValue("Gestures", "EdgeSize", "str", "int",
        "Edge definition width:", 100, true)
    CONF.min_gesture_len := ConfValue("Gestures", "MinGestureLen", "str", "int",
        "Gesture min length:", 150, true)
    CONF.min_cos_similarity := ConfValue("Gestures", "MinCosSimilarity", "str", "float",
        "Gesture min similarity:", 0.90)
    CONF.overlay_opacity := ConfValue("Gestures", "OverlayOpacity", "str", "int",
        "Overlay opacity (up to 255):", 200, true)
    CONF.font_size_lh := ConfValue("Gestures", "LHSize", "str", "int",
        "Font size on live hint:", 32, true)
    CONF.live_hint_extended := ConfValue("Gestures", "LiveHintExtended", "checkbox", "int",
        "Show unrecognized gestures on live hint", 1)

    CONF.gest_rotate := ConfValue("GestureDefaults", "Rotate", "ddl", "int",
        "Rotate:", 1, , , [["No", "Remove orientation noise", "Orientation invariance"], false])
    CONF.scale_impact := ConfValue("GestureDefaults", "Scaling", "str", "float",
        "Scale impact:", 0)
    CONF.gest_live_hint := ConfValue("GestureDefaults", "LiveHint", "ddl", "int",
        "Live recognition hint position:", 1, , , [["Top", "Center", "Bottom", "Disabled"], false])

    CONF.gest_colors := [
        ConfValue("GestureDefaults", "GestureColors", "color", "str",
            "Gesture colors`n(more than one for gradient):", "random(3)", , true),
        ConfValue("GestureDefaults", "GestureColorsEdges", "color", "str",
            "Gesture colors`n(more than one for gradient):", "4FC3F7,9575CD,F06292", , true),
        ConfValue("GestureDefaults", "GestureColorsCorners", "color", "str",
            "Gesture colors`n(more than one for gradient):", "66BB6A,26C6DA,FBC02D", , true),
    ]
    CONF.grad_len := [
        ConfValue("GestureDefaults", "GradientLength", "str", "int",
            "Full gradient cycle length (px):", 1000, true),
        ConfValue("GestureDefaults", "GradientLengthEdges", "str", "int",
            "Full gradient cycle length (px):", 1000, true),
        ConfValue("GestureDefaults", "GradientLengthCorners", "str", "int",
            "Full gradient cycle length (px):", 1000, true),
    ]
    CONF.grad_loop := [
        ConfValue("GestureDefaults", "GradientLoop", "checkbox", "int",
            "&Gradient cycling", 1),
        ConfValue("GestureDefaults", "GradientLoopEdges", "checkbox", "int",
            "&Gradient cycling", 1),
        ConfValue("GestureDefaults", "GradientLoopCorners", "checkbox", "int",
            "&Gradient cycling", 1),
    ]

    CONF.default_assigned_color := ConfValue("Colors", "DefaultAssigned", "color", "str",
        "Default for assigned:", "Silver")
    CONF.default_unassigned_color := ConfValue("Colors", "DefaultUnssigned", "color", "str",
        "Default for unassigned (empty):", "White")
    CONF.chord_part_color := ConfValue("Colors", "ChordPart", "color", "str",
        "Part of chord(s):", "BBBB22")
    CONF.selected_chord_color := ConfValue("Colors", "SelectedChord", "color", "str",
        "Selected/editing chord:", "CD7F32")
    CONF.has_gestures_color := ConfValue("Colors", "HasNestedGestures", "color", "str",
        "With nested gestures:", "Red")
    CONF.modifier_color := ConfValue("Colors", "Modifier", "color", "str",
        "Modifier:", "7777AA")
    CONF.active_modifier_color := ConfValue("Colors", "ActiveModifier", "color", "str",
        "Active modifier:", "Black")

    CONF.changed_name_ind_color := ConfValue("Colors", "ChangedName", "color", "str",
        "With custom gui name:", "Silver")
    CONF.irrevocable_ind_color := ConfValue("Colors", "Irrevocable", "color", "str",
        "Irrevocable:", "Gray")
    CONF.instant_ind_color := ConfValue("Colors", "Instant", "color", "str",
        "Instant:", "Teal")
    CONF.additional_up_ind_color := ConfValue("Colors", "AdditionalUp", "color", "str",
        "With additional up action:", "Blue")
    CONF.custom_hold_time_ind_color := ConfValue("Colors", "CustomHold", "color", "str",
        "Custom hold threshold:", "Purple")
    CONF.custom_child_time_ind_color := ConfValue("Colors", "CustomNested", "color", "str",
        "Custom nested event waiting time:", "Fuchsia")
    CONF.nested_counter_ind_color := ConfValue("Colors", "NestedCounter", "color", "str",
        "Nested assignment counter:", "Green")

    if !IniRead("config.ini", "Main", "UserLayouts", "") {
        TrackLayouts()
        WinWaitClose(layout_gui.Hwnd)
        return true
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

    tabs := s_gui.Add("Tab3", "x0 y0 w402 h666",
        ["Main", "GUI", "Gestures", "Gesture defaults", "Colors"])

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
        _AddElems("m_color", 215,
            [1, "GestureColors" . name, "Gesture colors`n(more than one for gradient):",
                CONF.gest_colors[i].v],
        )
        _AddElems("str",,
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

    tabs.UseTab("Colors")
    s_gui.Add("Text", "x20 w360 y30 h34 Center",
        "Button borders:")
    loop 7 {
        c := CONF.Colors[A_Index]
        _AddElems(c.form_type, A_Index == 1 ? 55 : "",
            [c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*])
    }
    s_gui.Add("Text", "x20 w360 y+8 h1 0x10")
    s_gui.Add("Text", "x20 w360 y+10 h34 Center", "Indicators on buttons:")
    loop 7 {
        c := CONF.Colors[A_Index + 7]
        _AddElems(c.form_type, A_Index == 1 ? 285 : "",
            [c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*])
    }

    s_gui.Show("w400 h480")
    DllCall("SetFocus", "ptr", s_gui["ExtraFRow"].Hwnd)
}


_ToggleColors(trg, *) {
    for i, name in ["", "Edges", "Corners"] {
        s_gui["GestureColors" . name].Visible := i == trg
        s_gui["GestureColors" . name . "Pick"].Visible := i == trg
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
                    .OnEvent("Click", (*) => fn.Call())
                s_gui.Add("CheckBox", "x+3 w330 yp+0 h20 v" . arr[2], arr[3]).Value := arr[4]
                cur_h += h + _shift
            }
        case "color":
            for arr in data {
                h := arr[1] ? 40 : 20
                name := arr[2]
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w190", arr[3])
                s_gui.Add("Edit", "Center x+0 yp" . (arr[1] ? 8 : -2) . " h20 w160 v"
                    . name, arr[4])
                s_gui.Add("Button", "x+3 yp+0 h20 w20 v" . name . "Pick", "🎨")
                    .OnEvent("Click", (*)
                        => (s_gui[name].Text := ColorPick(s_gui[name].Text) || s_gui[name].Text))
                cur_h += h + _shift
            }
        case "m_color":
            for arr in data {
                h := arr[1] ? 40 : 20
                name := arr[2]
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w190", arr[3])
                s_gui.Add("Edit", "Center x+0 yp" . (arr[1] ? 8 : -2) . " h20 w160 v"
                    . name, arr[4])
                s_gui.Add("Button", "x+3 yp+0 h20 w20 v" . name . "Pick", "🎨")
                    .OnEvent("Click", (*)
                        => (s_gui[name].Text .= (s_gui[name].Text ? "," : "")
                            . ColorPick(s_gui[name].Text)))
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

        for name in ["Main", "GUI", "Gestures", "GestureDefaults", "Colors"] {
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
    for name in ["Main", "GUI", "Gestures", "GestureDefaults", "Colors"] {
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