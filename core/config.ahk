CoordMode "Mouse", "Screen"
A_HotkeyInterval := 0
version := 0
s_gui := false
is_updating := false

static_lang_names:=Map(67699721, "qwerty en", 68748313, "йцукен ru")

saved_level := false
buffer_view := 0

CONF := {
    Main: [],
    GUI: [],
    Gestures: [],
    GestureDefaults: [],
    Colors: [],
    User: []
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
LANGS.Add(0, "Layout: Global")

first_start := CheckConfig()
CurrentLayout := GetCurrentLayout()
ReadLayers()
FillRoots()
UpdLayers()

if first_start {
    MsgBox("Before moving on to assignments, modify the settings.`nSpecify the correct keyboard "
        . "format (ANSI/ISO), presence of additional rows of keys, and play with the GUI/font "
        . "scale.`n`n–––`n`nTo move through the assignment events use LMB for Tap events and RMB "
        . "for Hold events and toggling modifiers.`nYou can also use tap/hold with your physical "
        . "keyboard keys for the same events.`n`n–––`n`nAlmost all elements in the main GUI have "
        . "a hint text that is displayed when Alt is held down. Even if you know what an item does"
        . ", there may be additional information there to help you better understand.`n`n–––`n`n"
        . "Please report any bugs you find (there's still a lot of them ¯\_(ツ)_/¯), unclear "
        . "aspects, or just suggestions for improvement on Github.`nIf you just want to write "
        . "that you enjoyed it, that would be a pleasure to me.", "Welcome!")
    SetTimer(ShowSettings, -666)
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
            . "ChosenTags=Active, Inactive`n"
            . "`n[GUI]`n"
            . "`n[Gestures]`n"
            . "`n[GestureDefaults]`n"
            . "`n[Colors]`n"
            . "`n[User]`n"
            . "OpenWeatherMapApi=`n"
            . "GetGeoApi="
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
    CONF.hide_mouse_warnings := ConfValue("GUI", "HideMouseWarnings", "checkbox", "int",
        "Hide warnings about disabling drag &behavior for LMB/RMB/MMB", 0)

    CONF.gest_color_mode := ConfValue("Gestures", "ColorMode", "ddl", "str",
        "Color mode:", "HSV", , , [["RGB", "Gamma-correct", "HSV"], true])
    CONF.edge_gestures := ConfValue("Gestures", "EdgeGestures", "ddl", "int",
        "Use edge gestures:", 4, , ,
        [["No", "With edges", "With corners", "With edges and corners"], false])
    CONF.edge_size := ConfValue("Gestures", "EdgeSize", "str", "int",
        "Edge definition width:", 128, true)
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
        "Irrevocable:", "E1E1E1")
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

    CONF.tags := Map()
    for tag in StrSplit(IniRead("config.ini", "Main", "ChosenTags", "Active, Inactive"), ",") {
        tag := Trim(tag)
        if SubStr(tag, 1, 1) == "-" {
            CONF.tags[SubStr(tag, 2)] := false
        } else {
            CONF.tags[tag] := true
        }
    }

    CollectUserValues()

    if !IniRead("config.ini", "Main", "UserLayouts", "") {
        GetActiveHKLs()
        return true
    }

    for lang in StrSplit(IniRead("config.ini", "Main", "UserLayouts"), ",") {
        lang := Integer(Trim(lang))
        if LANGS.Has(lang) {
            continue
        }
        LANGS.Add(lang, GetLayoutNameFromHKL(lang))
    }
}


CollectUserValues() {
    for cnf in CONF.User {
        CONF.DeleteProp("user_" . cnf.ini_name)
    }
    CONF.User := []

    user_values := IniRead("config.ini", "User", , false)
    if user_values {
        for line in StrSplit(user_values, "`n", "`r") {
            if !line {
                continue
            }

            p := InStr(line, "=")
            if !p {
                continue
            }

            key := SubStr(line, 1, p - 1)
            val := SubStr(line, p + 1)
            if key {
                CONF.user_%key% := ConfValue("User", key, "user", "str", key, val)
            }
        }
    }
}


GetActiveHKLs(*) {
    global LANGS

    n := DllCall("GetKeyboardLayoutList", "int", 0, "ptr", 0, "int")
    if n <= 0 {
        return []
    }

    buf := Buffer(A_PtrSize * n, 0)
    DllCall("GetKeyboardLayoutList", "int", n, "ptr", buf.Ptr, "int")

    LANGS := OrderedMap()
    LANGS.Add(0, "Layout: Global")

    loop n {
        hkl := NumGet(buf, (A_Index - 1) * A_PtrSize, "uptr")
        LANGS.Add(hkl, GetLayoutNameFromHKL(hkl))
    }
    str_value := ""
    for lang in LANGS.map {
        if lang {
            str_value .= lang . ", "
        }
    }
    IniWrite(SubStr(str_value, 1, -2), "config.ini", "Main", "UserLayouts")
}


ShowSettings(*) {
    global s_gui

    try s_gui.Destroy()

    s_gui := Gui("-SysMenu", "Settings")
    s_gui.OnEvent("Close", CloseSettingsEvent)
    s_gui.OnEvent("Escape", CloseSettingsEvent)
    s_gui.SetFont("s9")

    s_gui.user_values := []

    s_gui.Add("Button", "Center x299 y0 w60 h18 Default vCancel", "❌ Cancel")
        .OnEvent("Click", CloseSettingsEvent)
    s_gui.Add("Button", "Center x358 y0 w60 h18 Default vApply", "✔ Accept")
        .OnEvent("Click", SaveConfig)

    tabs := s_gui.Add("Tab3", "x0 y0 w422 h666",
        ["Main", "GUI", "Gestures", "Gesture defaults", "Colors", "User"])

    tabs.UseTab("Main")
    for c in CONF.Main {
        _AddElems(c.form_type, A_Index == 1 ? 40 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }
    s_gui.Add("Button", "Center x15 y+15 w390 h20", "Reread system layouts")
        .OnEvent("Click", GetActiveHKLs)

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
    s_gui.Add("Text", "x20 w380 y34 h34 Center",
        "Default gesture matching and color options`n(can be overridden in each assignment)")
    s_gui.Add("Text", "x20 w380 y+8 h1 0x10")

    for c in CONF.GestureDefaults {
        if A_Index == 4 {
            break
        }
        _AddElems(c.form_type, A_Index == 1 ? 90 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }

    s_gui.Add("Text", "x85 w250 y+10 h1 0x10")

    s_gui.Add("Button", "vToggleColors x15 y+10 h20 w131 Disabled", "General")
        .OnEvent("Click", _ToggleColors.Bind(1))
    s_gui.Add("Button", "vToggleColorsEdges x145 yp0 h20 w131", "Edges")
        .OnEvent("Click", _ToggleColors.Bind(2))
    s_gui.Add("Button", "vToggleColorsCorners x275 yp0 h20 w130", "Corners")
        .OnEvent("Click", _ToggleColors.Bind(3))

    for i, name in ["", "Edges", "Corners"] {
        _AddElems("m_color", 215, [
            1, "GestureColors" . name,
            "Gesture colors`n(more than one for gradient):", CONF.gest_colors[i].v
        ])
        _AddElems("str",, [
            0, "GradientLength" . name . " Number",
            "Full gradient cycle length (px):", CONF.grad_len[i].v
        ])
        _AddElems("checkbox",, [
            0, "GradientLoop" . name, "&Gradient cycling", CONF.grad_loop[i].v
        ])
        if i > 1 {
            s_gui["GestureColors" . name].Visible := false
            s_gui["GradientLength" . name].Visible := false
            s_gui["GradientLoop" . name].Visible := false
        }
    }

    tabs.UseTab("Colors")
    s_gui.Add("Text", "x20 w380 y30 h34 Center",
        "Button borders:")
    loop 7 {
        c := CONF.Colors[A_Index]
        _AddElems(c.form_type, A_Index == 1 ? 55 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }
    s_gui.Add("Text", "x20 w380 y+8 h1 0x10")
    s_gui.Add("Text", "x20 w380 y+10 h34 Center", "Indicators on buttons:")
    loop 7 {
        c := CONF.Colors[A_Index + 7]
        _AddElems(c.form_type, A_Index == 1 ? 285 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }

    tabs.UseTab("User")
    s_gui.Add("Text", "x50 w320 y34 h20 Center",
        "Here you can place values for your user functions, e.g. api keys.")
    s_gui.Add("Button", "x+17 yp-2 w20 h20 Center", "+").OnEvent("Click",
        _AddElems.Bind("user", false, [false, "", "", ""]))
    s_gui.Add("Text", "x15 w390 y+5 h1 0x10")
    for c in CONF.User {
        _AddElems(c.form_type, A_Index == 1 ? 70 : "", [
            c.double_height, c.ini_name . (c.is_num ? " Number" : ""),
            c.descr, c.v, c.extra_params*
        ])
    }
    _AddElems("user", , [false, "", "", ""])

    s_gui.Show("w420 h480")
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

    for arr in data {
        if type(arr) !== "Array" {
            continue
        }
        h := arr[1] ? 40 : 20
        ysh := arr[1] ? 8 : -2
        name := arr[2]
        switch elem_type {
            case "ddl":
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w190", arr[3])
                elem := s_gui.Add("DropDownList", "x+10 yp" . ysh . " w190 v" . name, arr[5])
                if arr[6] {
                    elem.Text := arr[4]
                } else {
                    elem.Value := arr[4]
                }
            case "str":
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w200", arr[3])
                s_gui.Add("Edit", "Center x+0 yp" . ysh . " h20 w190 v" . name, arr[4])
            case "checkbox":
                s_gui.Add("CheckBox", "x15 y" . cur_h . " h" . h . " w380 v" . name, arr[3])
                    .Value := arr[4]
            case "h_checkbox":
                fn := MsgBox.Bind(arr[5], arr[6], "IconI")
                s_gui.Add("Button", "x11 y" . cur_h . " h20 w20", "?")
                    .OnEvent("Click", (*) => fn.Call())
                s_gui.Add("CheckBox", "x+3 w350 yp+0 h20 v" . name, arr[3]).Value := arr[4]
            case "color":
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w200", arr[3])
                s_gui.Add("Edit", "Center x+0 yp" . ysh . " h20 w170 v" . name, arr[4])
                s_gui.Add("Button", "x+3 yp+0 h20 w20 v" . name . "Pick", "🎨").OnEvent("Click",
                    (*) => (s_gui[name].Text := ColorPick(s_gui[name].Text) || s_gui[name].Text))
            case "m_color":
                s_gui.Add("Text", "x15 y" . cur_h . " h" . h . " w200", arr[3])
                s_gui.Add("Edit", "Center x+0 yp" . ysh . " h20 w170 v" . name, arr[4])
                s_gui.Add("Button", "x+3 yp+0 h20 w20 v" . name . "Pick", "🎨").OnEvent("Click",
                    (*) => (s_gui[name].Text .= (s_gui[name].Text ? "," : "")
                        . ColorPick(s_gui[name].Text))
                )
            case "user":
                n := s_gui.Add("Edit", "x15 y" . cur_h . " h" . h . " w190", arr[3])
                s_gui.Add("Text", "Center x+0 yp+3 h20 w10", "=")
                v := s_gui.Add("Edit", "Center x+0 yp-3 h20 w190", arr[4])
                s_gui.user_values.Push([n, v])

        }
        cur_h += h + _shift
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
    global s_gui, overlay

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
                val := elem.form_type == "color" || elem.form_type == "m_color"
                    || elem.form_type == "str"
                    || elem.form_type == "ddl" && elem.val_type == "str"
                        ? s_gui[elem.ini_name].Text : s_gui[elem.ini_name].Value
                IniWrite(val, "config.ini", name, elem.ini_name)
                elem.v := elem.val_type == "int" ? Integer(val)
                    : elem.val_type == "float" ? Round(Float(val), 2) : val
            }
        }
        IniDelete("config.ini", "User")
        for pair in s_gui.user_values {
            key := pair[1].Text
            value := pair[2].Text
            if key {
                IniWrite(value, "config.ini", "User", key)
            }
        }
    }

    s_gui.Destroy()
    s_gui := false
    if b == 2 {
        Run(A_ScriptFullPath)  ; rerun with new keys
    } else if b {
        CONF.T := "T" . CONF.MS_LP.v / 1000
        A_TrayMenu.Rename("1&", "+10ms hold threshold (to " . CONF.MS_LP.v + 10 . "ms)")
        A_TrayMenu.Rename("2&", "-10ms hold threshold (to " . CONF.MS_LP.v - 10 . "ms)")
        CollectUserValues()
        try overlay.Destroy()
        overlay := false
        DrawLayout()
    }
}


CheckChanges(*) {
    for name in ["Main", "GUI", "Gestures", "GestureDefaults", "Colors"] {
        for elem in CONF.%name% {
            val := elem.form_type == "color" || elem.form_type == "m_color"
                || elem.form_type == "str"
                || elem.form_type == "ddl" && elem.val_type == "str"
                    ? s_gui[elem.ini_name].Text : s_gui[elem.ini_name].Value
            if val != elem.v {
                return true
            }
        }
    }
    cnt := 0
    for pair in s_gui.user_values {
        key := pair[1].Text
        value := pair[2].Text
        if key || value {
            cnt += 1
            if !CONF.HasOwnProp("user_" . key) || CONF.user_%key%.v != value {
                return true
            }
        }
    }
    if cnt !== CONF.User.Length {
        return true
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


GetLayoutLangFromHKL(hkl) {
    if static_lang_names.Has(hkl) {
        return static_lang_names[hkl]
    }

    buf := Buffer(9)
    DllCall("GetLocaleInfoW", "UInt", hkl & 0xFFFF, "UInt", 0x59, "Ptr", buf, "Int", 9)
    return StrGet(buf)
}


GetLayoutNameFromHKL(hkl) {
    if static_lang_names.Has(hkl) {
        return static_lang_names[hkl]
    }

    klid := GetKLIDFromHKL(hkl)
    if !klid {
        return ""
    }

    name := GetLayoutDisplayNameFromKLID(klid)
    return name ? name : klid
}


GetKLIDFromHKL(hkl) {
    cur := DllCall("GetKeyboardLayout", "uint", 0, "ptr")
    DllCall("ActivateKeyboardLayout", "ptr", hkl, "uint", 0)
    buf := Buffer(9 * 2, 0)
    res := DllCall("GetKeyboardLayoutNameW", "ptr", buf, "int")
    DllCall("ActivateKeyboardLayout", "ptr", cur, "uint", 0)
    if !res {
        return ""
    }

    return StrGet(buf, "UTF-16")
}


GetLayoutDisplayNameFromKLID(klid) {
    base := "HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\" . klid

    disp := ""
    try disp := RegRead(base, "Layout Display Name")

    if disp {
        resolved := ResolveIndirectString(disp)
        if resolved {
            return resolved
        }
    }

    txt := ""
    try txt := RegRead(base, "Layout Text")

    return txt
}


ResolveIndirectString(s) {
    buf := Buffer(2048 * 2, 0)
    hr := DllCall(
        "shlwapi\SHLoadIndirectString", "wstr", s, "ptr", buf, "uint", 2048, "ptr", 0, "int"
    )
    return !hr ? StrGet(buf, "UTF-16") : ""
}