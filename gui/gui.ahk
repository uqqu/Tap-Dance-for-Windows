#Include "gui_draw.ahk"
#Include "gui_fill.ahk"
#Include "gui_layers.ahk"
#Include "gui_gestures.ahk"
#Include "gui_chords.ahk"
#Include "gui_forms.ahk"
#Include "gui_transitions.ahk"

SM_SCS := Map(42, 1, 54, 1, 310, 1, 29, 2, 285, 2, 56, 4, 312, 8)
; shift 1; ctrl 2; lalt 4; ralt/altgr 8

current_path := []
selected_chord := ""
selected_gesture := ""
root_text := "root"

selected_layer := ""
last_selected_layer := ""
selected_layer_priority := 0
layer_editing := 0
layer_path := []

gui_mod_val := 0
gui_sysmods := 0
gui_lang := 0
gui_entries := {ubase: ROOTS[gui_lang], uhold: false, umod: false}

temp_chord := 0
start_temp_chord := 0

overlay := false

A_TrayMenu.Delete()
A_TrayMenu.Add("+10ms hold threshold (to " . CONF.MS_LP.v + 10 . "ms)",
    (*) => ChangeDefaultHoldTime(+10))
A_TrayMenu.Add("-10ms hold threshold (to " . CONF.MS_LP.v - 10 . "ms)",
    (*) => ChangeDefaultHoldTime(-10))
A_TrayMenu.Add()
A_TrayMenu.Add("Show GUI", (*) => TrayClick())
A_TrayMenu.Add("Settings", (*) => ShowSettings())
A_TrayMenu.Add("Suspend hotkeys", (*) => TrayToggleSuspend())
A_TrayMenu.Add("Reload", (*) => Run(A_ScriptFullPath))
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Show GUI"

A_TrayMenu.Click := TrayClick
A_TrayMenu.ClickCount := 1

DrawLayout(true)


TrayToggleSuspend() {
    Suspend(-1)
    if A_IsSuspended {
        A_TrayMenu.Check("Suspend hotkeys")
        TraySetIcon(A_ScriptDir . "\ico\icon_suspend.ico", , true)
    } else {
        A_TrayMenu.Uncheck("Suspend hotkeys")
        TraySetIcon(A_ScriptDir . "\ico\icon.ico")
    }
}


_GetFirst(node, certain_layer:="") {
    if !node {
        return false
    }
    if buffer_view && node.layers.map.Has("buffer") && node.layers["buffer"][0] {
        return node.layers["buffer"][0]
    }
    if layer_editing || certain_layer {
        layer := certain_layer || selected_layer
        if node.layers[layer] && node.layers[layer][0] {
            return node.layers[layer][0]
        }
        return false
    }

    def := false
    for layer in ActiveLayers.order {
        if node.layers.map.Has(layer) && node.layers[layer][0] {
            if node.layers[layer][0].down_type == TYPES.Default {
                if !def {
                    def := node.layers[layer][0]
                }
            } else {
                return node.layers[layer][0]
            }
        }
    }
    return def
}


OneNodeDeeper(schex, md:=-1, is_chord:=false, is_gesture:=false) {
    global gui_entries, gui_mod_val, gui_sysmods

    if md == -1 {
        md := gui_mod_val
    }
    path := buffer_view ? buffer_path : current_path
    path.Push([schex, md, is_chord, is_gesture])
    gui_mod_val := 0
    gui_sysmods := 0
    gui_entries := gui_entries.ubase.GetBaseHoldMod(schex, md, is_chord, is_gesture)
    CloseForm()
    UpdateKeys()
}


ChangePath(len:=-1, discard_md:=true, *) {
    global gui_mod_val, gui_entries, gui_sysmods

    UI["Hidden"].Focus()
    if temp_chord || is_updating {
        return
    }

    path := buffer_view ? buffer_path : current_path

    if len == -1 {
        len := path.Length
    } else {
        CloseForm()
    }

    ToggleVisibility(0, UI.path)
    UI.path := []

    gui_entries := {
        ubase: ROOTS[buffer_view ? (buffer_view == 1 ? "buffer" : "buffer_h") : gui_lang],
        uhold: (buffer_view == 1 ? ROOTS["buffer_h"] : false),
        umod: false
    }
    gui_mod_val := len < path.Length ? path[len + 1][2] & ~1
        : discard_md ? 0 : gui_mod_val

    path.Length := len

    for arr in path {
        gui_entries := gui_entries.ubase.GetBaseHoldMod(arr*)
    }

    if gui_mod_val {
        _TransferModifiers()
    } else {
        gui_sysmods := 0
    }

    UpdateKeys()
}


_TransferModifiers() {
    global gui_mod_val, gui_sysmods

    temp_mod_val := 0
    temp_sysmods := 0
    for sc in ALL_SCANCODES {
        res := gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val)
        h_node := _GetFirst(res.uhold)
        m_node := _GetFirst(res.umod)
        md := h_node && h_node.down_type == TYPES.Modifier ? h_node
            : m_node && m_node.down_type == TYPES.Modifier ? m_node : false
        if md && (gui_mod_val & (1 << md.down_val)) {
            temp_mod_val |= 1 << md.down_val
            temp_sysmods |= SM_SCS.Get(sc, 0)
        }
    }
    gui_mod_val := temp_mod_val
    gui_sysmods := temp_sysmods
}


_DecomposeMods(n, str_output:=false) {
    n &= ~1
    res := str_output ? "" : []
    bit := 0
    while n {
        if n & 1 {
            if str_output {
                res .= bit . "&"
            } else {
                res.Push(bit)
            }
        }
        n >>= 1
        bit++
    }
    return str_output ? SubStr(res, 1, -1) : res
}


UpdateKeys() {
    prev_lang := false
    if gui_lang {
        prev_lang := GetCurrentLayout()
        if gui_lang !== prev_lang {
            DllCall("ActivateKeyboardLayout", "ptr", gui_lang, "uint", 0)
        } else {
            prev_lang := false
        }
    }

    _CreateOverlay()
    _FillPathline()
    _FillSetButtons()
    UI.SetFont("Norm")
    _FillKeyboard()
    _FillLayers()
    _FillGestures()
    _FillChords()
    _FillOther()

    if gui_mod_val && UI.path[-1].Text != "²" {
        txt := ""
        for n in _DecomposeMods(gui_mod_val) {
            txt .= n . "+"
        }
        UI.SetFont("c808080")
        UI.path.Push(UI.Add("Text", "x+7 yp" . (6 * CONF.gui_scale.v), RTrim(txt, "+")))
        UI.SetFont("cD3D3D3")
        UI.path.Push(UI.Add("Text", "xp-5 yp+13", "²"))
        UI.SetFont("cBlack")
    }

    if prev_lang {
        DllCall("ActivateKeyboardLayout", "ptr", prev_lang, "uint", 0)
    }
}


HandleKeyPress(sc) {
    global temp_chord, drag_physical

    if sc == 0x038 || sc == 0x138 {  ; unfocus hidden menubar
        Send("{Alt}")
    }

    if is_updating {
        return
    }

    if is_drag_mode {
        if drag_physical {
            if UI.buttons[sc].Enabled {
                _SwapButtons(UI.buttons[sc], UI.buttons[drag_physical])
                dn := UI.buttons[drag_physical].dragged_sc
                mn := UI.buttons[sc].dragged_sc
                t := drag_map[dn]
                drag_map[dn] := drag_map[mn]
                drag_map[mn] := t
                drag_physical := false
                for name, btn in UI.buttons {
                    if name !== "CurrMod" {
                        try btn.Opt("-Disabled")
                    }
                }
            }
        } else {
            drag_physical := sc
            UI.buttons[sc].Opt("BackgroundBlack")
            UI.buttons[sc].Text .= ""
            _HideInappropriate(sc)
        }
        return
    }

    name := _GetKeyName(sc)
    path := buffer_view ? buffer_path : current_path
    if name == CONF.gui_back_sc.v && path.Length {
        ChangePath(path.Length - 1)
    } else if name == CONF.gui_set_sc.v && UI["BtnBase"].Enabled && UI["BtnBase"].Visible {
        OpenForm(0)
    } else if name == CONF.gui_set_hold_sc.v && UI["BtnHold"].Enabled && UI["BtnHold"].Visible {
        OpenForm(1)
    } else if temp_chord {
        str_sc := String(sc)
        btn := UI.buttons[sc]
        if !btn.Enabled {
            return
        }
        if temp_chord.Has(str_sc) {
            temp_chord.Delete(str_sc)
            _FillOneButton(sc, btn, sc)
        } else {
            temp_chord[str_sc] := true
            btn.Opt("+Background" . CONF.selected_chord_color.v)
            btn.Text := btn.Text
        }
    } else if sc == 0x038 || sc == 0x138 {
        SetTimer(AltHelp, 8)
    } else if SubStr(sc, 1, 5) == "Wheel" {
        ButtonLMB(sc)
    } else {
        bnode := _GetFirst(gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val).ubase)
        is_hold := KeyWait(SC_STR[sc],
            (bnode && bnode.custom_lp_time ? "T" . bnode.custom_lp_time / 1000 : CONF.T))
        if WinActive("A") == UI.Hwnd {  ; with postcheck
            is_hold ? ButtonLMB(sc) : ButtonRMB(sc)
        }
    }
}


ButtonLMB(sc, *) {
    UI["Hidden"].Focus()

    if !is_updating {
        _Move(sc, 0)
    }
}


ButtonRMB(sc, *) {
    global gui_mod_val, gui_sysmods

    UI["Hidden"].Focus()

    if ONLY_BASE_SCS.Has(sc) || is_updating {
        return
    }

    res := gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val, false, false, false, false)

    h_node := _GetFirst(res.uhold)
    if h_node && h_node.down_type == TYPES.Chord {
        return
    }

    m_node := _GetFirst(res.umod)
    md := h_node && h_node.down_type == TYPES.Modifier ? h_node
        : m_node && m_node.down_type == TYPES.Modifier ? m_node : false
    if md {
        if gui_mod_val & (1 << md.down_val) {
            gui_sysmods &= ~SM_SCS.Get(sc, 0)
        } else {
            gui_sysmods |= SM_SCS.Get(sc, 0)
        }
        gui_mod_val ^= 1 << md.down_val
        UpdateKeys()
        return
    }

    _Move(sc, 1)
}


_Move(sc, is_hold) {
    global gui_mod_val

    if temp_chord {
        HandleKeyPress(sc)
        return
    }
    if SYS_MODIFIERS.Has(sc) {
        if buffer_view {
            return
        }
        path := current_path.Clone()
        path.Push([sc, 0, 0, 0])
        OpenForm(1, path, 0, gui_entries.ubase.GetBaseHoldMod(sc, 0, 0, 0))
        return
    }
    OneNodeDeeper(sc, gui_mod_val + is_hold)
}


SaveValue(
    is_hold, layer, down_type, down_val:="", up_type:=false, up_val:="",
    is_instant:=false, is_irrevocable:=false, custom_lp_time:=false, custom_nk_time:=false,
    child_behavior:=false, shortname:="", gest_opts:="", custom_path:=false
) {
    json_root := DeserializeMap(layer)

    if !json_root.Has(gui_lang) {
        json_root[gui_lang] := ["", Map(), Map(), Map()]
    }
    json_node := _WalkJson(json_root[gui_lang], (custom_path || current_path), is_hold)
    json_node[1] := down_type
    json_node[2] := down_type == TYPES.Default || down_type == TYPES.Disabled ? "" : down_val . ""
    json_node[3] := up_type || TYPES.Disabled
    json_node[4] := up_type == TYPES.Default || json_node[3] == TYPES.Disabled ? "" : up_val . ""
    json_node[5] := Integer(is_instant)
    json_node[6] := Integer(is_irrevocable)
    json_node[7] := Integer(custom_lp_time)
    json_node[8] := Integer(custom_nk_time)
    json_node[9] := Integer(child_behavior)
    json_node[10] := shortname
    json_node[11] := gest_opts
    SerializeMap(json_root, layer)

    FillRoots()
    if layer_editing {
         AllLayers.map[selected_layer] := true
        _MergeLayer(selected_layer)
    }
    UpdLayers()
    ChangePath()
}


ClearCurrentValue(is_hold, layer:="", *) {
    new_dtype := !current_path[-1][2] && !is_hold ? TYPES.Default : TYPES.Disabled
    if layer_editing {
        SaveValue(is_hold, selected_layer, new_dtype)
        return
    }

    if ActiveLayers.Length == 1 {
        selected_layers := ActiveLayers.order
    } else {
        layers := []
        checked_node := _GetFirst(is_hold ? gui_entries.uhold : gui_entries.ubase)
        for comb_node in (is_hold ? gui_entries.uhold : gui_entries.ubase).layers.GetAll() {
            if _EqualNodes(comb_node[0], checked_node) {
                layers.Push(comb_node[0].layer_name)
            }
        }
        if !layers.Length {
            return
        }
        selected_layers := layers.Length == 1 ? layers : ChooseLayers(layers)
    }

    for layer in selected_layers {
        SaveValue(is_hold, layer, new_dtype)
    }
}


ClearNested(is_hold, layer:="", *) {
    if MsgBox("Do you want to delete all nested assignments?",
        "Confirmation", "YesNo Icon?") == "No" {
        return
    }

    if layer_editing {
        selected_layers := [selected_layer]
    } else if ActiveLayers.Length == 1 {
        selected_layers := ActiveLayers.GetAll()
    } else {
        layers := []
        checked_node := _GetFirst(is_hold ? gui_entries.uhold : gui_entries.ubase)
        for comb_node in (is_hold ? gui_entries.uhold : gui_entries.ubase).layers.GetAll() {
            if _EqualNodes(comb_node[0], checked_node) {
                layers.Push(comb_node[0].layer_name)
            }
        }
        if !layers.Length {
            return
        }
        selected_layers := layers.Length == 1 ? layers : ChooseLayers(layers)
    }

    for layer in selected_layers {
        json_root := DeserializeMap(layer)

        if !json_root.Has(gui_lang) {
            json_root[gui_lang] := ["", Map(), Map(), Map()]
        }
        json_node := _WalkJson(json_root[gui_lang], current_path, is_hold)
        json_node[-3] := Map()
        json_node[-2] := Map()
        json_node[-1] := Map()
        SerializeMap(json_root, layer)
    }

    FillRoots()
    if layer_editing {
        AllLayers.map[selected_layer] := true
        _MergeLayer(selected_layer)
    }
    UpdLayers()
    ChangePath()
}


ChangeLang(lang, *) {
    global gui_lang

    UI["Hidden"].Focus()
    gui_lang := LANGS.order[lang]
    ChangePath()
}


TrayClick(*) {
    if !DllCall("IsWindowVisible", "ptr", UI.Hwnd) {
        UI.Show()
    } else {
        UI.Hide()
    }
}


ToggleEnabled(state, arrs*) {
    for arr in arrs {
        if !(arr is Array) {
            arr.Enabled := state == 2 ? !arr.Enabled : state
            continue
        }
        for elem in arr {
            elem.Enabled := state == 2 ? !elem.Enabled : state
        }
    }
}


ToggleVisibility(state, arrs*) {
    for arr in arrs {
        if !(arr is Array) {
            arr.Visible := state == 2 ? !arr.Visible : state
            continue
        }
        for elem in arr {
            elem.Visible := state == 2 ? !elem.Visible : state
        }
    }
}



ColorPick(start_color:="") {
    static cust_colors := Buffer(16 * 4, 0)

    start_color := AHK_COLORS.Get(start_color, start_color)

    if RegExMatch(start_color, "i)^[0-9A-F]{6}$") {
        _rgb := Integer("0x" . start_color)
        bgr := ((_rgb & 0xFF) << 16) | (((_rgb >> 8) & 0xFF) << 8) | ((_rgb >> 16) & 0xFF)
    } else {
        bgr := 0x00FFFFFF
    }

    hwnd := s_gui && s_gui.Hwnd ? s_gui.Hwnd : UI.Hwnd
    is64 := A_PtrSize == 8
    rgb_res := is64 ? 24 : 12

    buf := Buffer(is64 ? 72 : 36, 0)

    NumPut("UInt", buf.Size, buf, 0)
    NumPut("Ptr", hwnd, buf, is64 ? 8 : 4)
    NumPut("UInt", bgr, buf, rgb_res)
    NumPut("Ptr", cust_colors.Ptr, buf, is64 ? 32 : 16)
    NumPut("UInt", 3, buf, is64 ? 40 : 20)

    if !DllCall("Comdlg32\ChooseColorW", "Ptr", buf, "Int") {
        return ""
    }

    bgr := NumGet(buf, rgb_res, "UInt")
    _rgb := ((bgr & 0xFF) << 16) | (((bgr >> 8) & 0xFF) << 8) | ((bgr >> 16) & 0xFF)

    res := Format("{:06X}", _rgb)

    for name, val in AHK_COLORS {
        if val == res {
            return name
        }
    }

    return res
}


AltHelp() {
    static prev_hwnd:=0

    if !GetKeyState("Alt") {
        SetTimer(AltHelp, 0)
        prev_hwnd := 0
        ToolTip()
        return
    }

    MouseGetPos(,, &win_id, &ctrl_hwnd, 2)
    if !ctrl_hwnd || ctrl_hwnd == prev_hwnd {
        return
    }

    by_cursor_pos := false
    txt := ""
    if win_id !== UI.Hwnd {
        prev_hwnd := 0
        ToolTip()
        return
    }
    obj := GuiCtrlFromHwnd(ctrl_hwnd)
    if !obj {
        return
    }
    i_sc := obj.Name
    try i_sc := Integer(i_sc)
    path := buffer_view ? buffer_path : current_path

    if i_sc == "CurrMod" {
        txt := "Not actually a key. Just helpful hint about the current modifier value`nby which "
            . "assignments from the current view will be added and triggered.`n`n"
        if !gui_mod_val {
            txt .= "Is not used for the current view."
        } else {
            mods := _DecomposeMods(gui_mod_val, true)
            if StrLen(mods) > 1 {
                txt .= "Consist of the sum of 2^(mod) for modifiers " . mods . "."
            } else {
                txt .= "Obtained as 2^current_modifier (" . mods . ")."
            }
            txt .= "`nWill be reset on pressing."
        }
    } else if i_sc == "LV_gestures" {
        res := _GetColumnAtCursor(UI[i_sc], true)
        c := res[1]
        r := res[2]
        if r == 0 {
            prev_hwnd := 0
            ToolTip()
            return
        } else if r == -1 {
            fake_hwnd := "1" . c . r
            if prev_hwnd == fake_hwnd {
                return
            }
            by_cursor_pos := true
            prev_hwnd := fake_hwnd
            if obj.GetText(0, 1) == "Has nested gestures" {
                if c == 1 {
                    txt := "On levels where gestures cannot be added, "
                        . "shows the list of key-triggers that have gestures."
                } else if c == 2 {
                    txt := "Number of nested gestures for the key."
                }
            } else if c < 3 {
                txt := "List of assigned gestures by current path."
                    . "`nYou can double click gesture to go deeper and assign some nested."
            } else if c == 3 {
                txt := "Pool and recognition options for gestures.`nOptions are displayed only if "
                    . "they differ from those globally set in the settings.`nAlt-hint show all "
                    . "options.`n`nPool: LeftTop, Top, RightTop, Left, Center, Right, LeftBottom, "
                    . "Bottom, RightBottom`nRotate: without rotation (strict angle),`n  small "
                    . "rotation for noise smoothing (to 8 directions),`n  independence to rotation"
                    . "`nScale impact: from 0 (no impact)`nBidirectional (true/false)`nClosed "
                    . "figure with start point invariance (true/false)"
            } else if c == 4 {
                txt := "Number of nested assignments for the gesture`n(yeah, gestures, as well as "
                    . "chords, can have child assignments too,`neven new drawing "
                    . "key-triggers for new gestures or new chords)"
            } else if c == 6 {
                txt := "Seriously, you don't need this"
            }
        } else {
            fake_hwnd := "1" . r
            if prev_hwnd == fake_hwnd {
                return
            }
            by_cursor_pos := true
            prev_hwnd := fake_hwnd
            res := StrSplit(obj.GetText(r, 6), ";")
            gst := res[1]
            md := Integer(res[2])
            try gst := Integer(gst)
            b := StrLen(gst) > 64
            res := gui_entries.ubase.GetBaseHoldMod(gst, md, false, b, false, false)
            txt := _GetKeyInfo(gst, md & ~1, res, gui_entries, true, , , b)
        }
    } else if i_sc == "LV_layers" {
        res := _GetColumnAtCursor(UI[i_sc], true)
        c := res[1]
        r := res[2]
        if r == 0 {
            prev_hwnd := 0
            ToolTip()
            return
        } else if r == -1 {
            fake_hwnd := "2" . c . r
            if prev_hwnd == fake_hwnd {
                return
            }
            by_cursor_pos := true
            prev_hwnd := fake_hwnd
            if c == 1 {
                txt := "Every layer has a number of categorized by functionality assignments "
                    . "with any number of its levels.`nHere you can toggle their activity "
                    . "with checkboxes.`nSome related layers are grouped in the folders with "
                    . "corresponding icon."
            } else if c == 2 {
                txt := "All active layers have their priority, which is only important if "
                    . "assignments from different layers on the same level overlap.`n"
                    . "In this case assignments from the layer with the highest priority will be "
                    . "taken into account.`nBut identical assignments from different layers will "
                    . "be merged with nested assignments from all (as long as they don't overlap, "
                    . "otherwise read from the beginning)."
            } else if c == 3 {
                txt := "Layers and subdirs, as they named in the 'layers' folder.`nSome layers "
                    . "have description with alt-hint."
            } else if !path.Length {
                if c == 4 {
                    txt := "On the root level in this column you can see total number of "
                        . "assignments on different layers`nfrom the current active in the view "
                        . "language/layout. Try to switch it in the right drop-down list."
                } else if c == 6 {
                    txt := "On the root level in this column you can see total number of "
                        . "assignments on different layers`nfrom all other languages/layouts."
                }
            } else if c == 4 {
                txt := "Tap assignments from different layers for event by "
                    . "your current path (chain of transitions)"
            } else if c == 5 {
                txt := "Number of nested assignments for tap event by current path from "
                    . "different layers."
            } else if c == 6 {
                txt := "Hold assignments from different layers for event by "
                    . "your current path (chain of transitions)"
            } else if c == 7 {
                txt := "Number of nested (not modified) assignments for hold event by current "
                    . "path from different layers."
            }
        } else {
            if c < 4 || !path.Length {
                c := 3
            }
            fake_hwnd := "2" . c . r
            if prev_hwnd == fake_hwnd {
                return
            }
            by_cursor_pos := true
            prev_hwnd := fake_hwnd
            i := _GetRowIconIndex(UI["LV_layers"], r)
            if i > 1 {
                prev_hwnd := 0
                ToolTip()
                return
            } else {
                layer := ""
                for folder in layer_path {
                    layer .= folder . "\"
                }
                layer .= obj.GetText(r, 3)
                val := obj.GetText(r, c)
                if c == 3 || !path.Length {
                    txt := GetLayerDescription(FileRead("layers\" . layer . ".json"))
                } else if c == 4 && val {
                    entries := _GetUnholdEntries()
                    txt := _GetKeyInfo(path[-1][1], path[-1][2] & ~1, entries, entries,
                        true, , path[-1][3], path[-1][4], layer)
                } else if c == 6 && val {
                    entries := _GetUnholdEntries()
                    txt := _GetKeyInfo(path[-1][1], path[-1][2] & ~1, entries, entries,
                        , true, , , layer)
                }
            }
        }
    } else if i_sc == "LV_chords" {
        res := _GetColumnAtCursor(UI[i_sc], true)
        c := res[1]
        r := res[2]
        if r == 0 {
            prev_hwnd := 0
            ToolTip()
            return
        } else if r == -1 {
            fake_hwnd := "3" . c . r
            if prev_hwnd == fake_hwnd {
                return
            }
            by_cursor_pos := true
            prev_hwnd := fake_hwnd
            if c == 1 {
                txt := "Chord keys in string represantation."
                    . "`nClick on the chord once to see these keys on the view."
            } else if c == 2 {
                txt := "Just chord action, as in all other cases."
            } else if c == 3 {
                txt := "Number of nested assignments for the chord`n(yeah, chords, as well as "
                    . "gestures, can have child assignments too,`neven new chords or drawing "
                    . "key-triggers for new gestures)"
            }
        } else {
            fake_hwnd := "3" . r
            if prev_hwnd == fake_hwnd {
                return
            }
            by_cursor_pos := true
            prev_hwnd := fake_hwnd

            val := ChordToStr(obj.GetText(r, 1))
            res := gui_entries.ubase.GetBaseHoldMod(val, gui_mod_val, true)
            txt := _GetKeyInfo(val, gui_mod_val & ~1, res, gui_entries, true, , true)
        }

    } else if i_sc == "BtnEnableDragMode" {
        txt := "Enter drag&drop mode where you can quickly swap assignments."
    } else if i_sc == "BtnShowBuffer" {
        txt := "Show saved buffer. All remaining and replaced after pasting "
            . "assignments stay stored here."
    } else if i_sc == "BtnShowCopyMenu" {
        txt := "Several options for copying to the buffer.`n"
            . "Available only in layer editing mode.`n`nCurrent view – the assignments you "
            . "see now with all their children`n…not including assignments under modifiers "
            . "(it's the neighbors, not the children).`n"
        if path.Length {
            txt .= "Entire level – current tap assignment with all its nested "
                . "from all modifiers.`nExtended level – current tap and hold assignments "
                . "with all their nested assignments."
        } else {
            txt .= "Entire level – all level assignments under all modifiers with their nested."
        }
    } else if i_sc == "BtnShowPasteMenu" {
        txt := "Several options for pasting buffer to the current view.`n`n"
            . "Append – add assignments from the buffer to the current view, without replacing."
            . "`nMerge – add assignments from the buffer to the current view, with replacement "
            . "of conflicting ones. Replaced values will be saved to the buffer.`n"
            . "Replace – delete the entire view and paste the buffer in its place. "
            . "Deleted view/level will be moved to the buffer."
    } else if i_sc == "Langs" {
        txt := "List of layouts. Every layout on every layer may contain its own assignments.`n"
            . "Layouts from your system are named by its system description,`nfound ones in "
            . "the layers (and not listed in your layouts) – by language name with layout code.`n"
            . "'Global' contains layout-independent assignments`n…but if on the same layer "
            . "for the same event there will be global`n   and layout-specific assignments – the "
            . "latter will have priority;`n   the global assignment will work for the rest.`n`n"
        lang_cnt := []
        for code, lang in LANGS.map {
            entries := {ubase: ROOTS[code], uhold: false, umod: false}
            for arr in path {
                entries := entries.ubase.GetBaseHoldMod(arr*)
            }
            cnt := _CountChild(
                "", 0, 0, entries.ubase.scancodes, entries.ubase.chords, entries.ubase.gestures
            )
            if cnt {
                lang_cnt.Push([lang, cnt])
            }
        }
        if lang_cnt.Length {
            txt .= "Number of assignments per layout for current view:`n"
            n := lang_cnt.Length
            loop n - 1 {
                i := A_Index
                loop n - i {
                    j := A_Index
                    if lang_cnt[j][2] < lang_cnt[j+1][2] {
                        tmp := lang_cnt[j]
                        lang_cnt[j] := lang_cnt[j+1]
                        lang_cnt[j+1] := tmp
                    }
                }
            }
            for arr in lang_cnt {
                txt .= arr[1] . ": " . arr[2] . "`n"
            }
        } else {
            txt .= "There is no assignments on any layout for current view."
        }

    } else if i_sc == "Settings" {
        txt := "Settings"
    } else if i_sc == "BtnAddNewChord" {
        txt := "Add a new chord to the current view.`nAfter pressing, select the desired keys "
            . "with clicks in the interface,`nor by pressing the physical keys, then save and "
            . "set the assignment action.`nKeys participating in a chord will receive the "
            . "'part of chord' hold type`n(it could overwrite their current hold assignments!)."
    } else if i_sc == "BtnChangeSelectedChord" {
        txt := "Change selected chord.`nAfter pressing you will enter the key selection mode,`n"
            . "where you can change the keys of a chord,`nor just press 'save' to change the "
            . "chord action."
    } else if i_sc == "BtnDeleteSelectedChord" {
        txt := "Delete selected chord.`nAll keys participated in the chord will lose the hold "
            . "type 'part of chord',`nif they don't participate in other chords."
    } else if i_sc == "BtnAddNewGesture" {
        if UI["LV_gestures"].GetText(0, 1) == "Has nested gestures" {
            txt := "Gestures can be added 'under' its drawing-trigger key.`n"
                . "Select the desired non-modifier key first."
                . "`nGestures are independent of tap/hold branching, and are, technically, "
                . "a third branch,`nbut, conventionally, located under tap events as under the "
                . "whole key event."
        } else {
            txt := "Add a new gesture under the current key-trigger.`n`n"
                . "Gestures under every trigger are divided into 9 separate pools "
                . "– 4 edges, 4 corners and 1 center pool.`n"
                . "Drawing mode starts when you press a key that has assigned gestures "
                . "from the pool at the current cursor position.`nThis does not override the "
                . "standard behavior of the key, nor the tap/hold assignments.`n"
                . "…if you press trigger key without drawing, standard/default assignments "
                . "will be performed`n…if you draw, gesture recognition will be applied.`n`n"
                . "Note that if you assign gestures only to some pools, drawing mode will "
                . "not even start when the cursor is in other pools,`n"
                . "that can be used for partial assignments.`n`n"
                . "At the stage of adding an assignment you will also be given additional "
                . "recognition options:`ndependency of size, direction, rotation and starting "
                . "point.`nGesture color settings are specified via the 'parent' trigger key "
                . "assignment.`nPool settings are global and are defined in the general settings."
        }
    } else if i_sc == "BtnShowSelectedGesture" {
        txt := "Show the gesture drawing`nDrawing starts from the center point of the pool "
            . "where the gesture is defined,`nwith the color defined for the trigger key "
            . "(if defined)"
    } else if i_sc == "BtnChangeSelectedGesture" {
        txt := "Change the assignment for the selected gesture.`n"
            . "Optionally, you can redraw the gesture here."
    } else if i_sc == "BtnDeleteSelectedGesture" {
        txt := "Without notes. Just delete selected gesture."
    } else if i_sc == "BtnBackToRoot" {
        txt := "End layout editing mode and return to assignments from all active layers."
    } else if i_sc == "BtnAddNewLayer" {
        txt := "Add a new empty layer."
    } else if i_sc == "BtnViewSelectedLayer" {
        txt := "Enter layer editing mode for current selected in the list.`n"
            . "You also can double click on it."
    } else if i_sc == "BtnDeleteSelectedLayer" {
        txt := "Completly delete the selected layer. This action cannot be undone."
    } else if i_sc == "BtnRenameSelectedLayer" {
        txt := "Rename selected layer. Use '\' in the path to group layers into folders."
    } else if i_sc == "BtnMoveUpSelectedLayer" {
        txt := "Raise the priority of the selected layer.`nIf different layers have "
            . "assignments for the same events,`nit will be accepted from the layer with "
            . "the highest priority.`nPrioritization 'lang layout > global layout' is "
            . "secondary.`nFirst, the layers priority is taken into account, then layouts."
    } else if i_sc == "BtnMoveDownSelectedLayer" {
        txt := "Lower the priority of the selected layer.`nIf different layers have "
            . "assignments for the same events,`nit will be accepted from the layer with "
            . "the highest priority.`nPrioritization 'lang layout > global layout' is "
            . "secondary.`nFirst, the layers priority is taken into account, then layouts."
    } else if i_sc == "BtnBase" {
        entries := _GetUnholdEntries()
        txt := _GetKeyInfo(path[-1][1], path[-1][2] & ~1, entries, entries,
            true, , path[-1][3], path[-1][4])
    } else if i_sc == "TextBase" {
        t := path[-1][3] ? "chord" : path[-1][4] ? "gesture" : "tap event"
        txt := "Assignment for the " . t . " by the current path.`nClick to change it."
    } else if i_sc == "BtnBaseClear" {
        t := path[-1][3] ? "chord" : path[-1][4] ? "gesture" : "tap"
        txt := "Delete this " . t . " assignment"
    } else if i_sc == "BtnBaseClearNest" {
        t := path[-1][3] ? "chord" : path[-1][4] ? "gesture" : "tap"
        txt := "Delete nested in the " . t . " assignment"
        if path[-1][2] & 1 {
            txt .= "`n(now you see the hold nested on the view!)"
        }
    } else if i_sc == "BtnHold" {
        if path[-1][3] || path[-1][4] {
            txt := "Chords and gestures don't have a hold event"
        } else {
            entries := _GetUnholdEntries()
            txt := _GetKeyInfo(path[-1][1], path[-1][2] & ~1, entries, entries, , true)
        }
    } else if i_sc == "TextHold" {
        if path[-1][3] || path[-1][4] {
            prev_hwnd := 0
            ToolTip()
            return
        }
        txt := "Assignment for the hold event by the current path.`nClick to change it."
    } else if i_sc == "BtnHoldClear" {
        if path[-1][3] || path[-1][4] {
            prev_hwnd := 0
            ToolTip()
            return
        }
        txt := "Delete this hold assignment"
    } else if i_sc == "BtnHoldClearNest" {
        if path[-1][3] || path[-1][4] {
            prev_hwnd := 0
            ToolTip()
            return
        }
        txt := "Delete nested in the hold assignment"
        if !(path[-1][2] & 1) {
            txt .= "`n(now you see the tap nested on the view!)"
        }
    } else if i_sc == "ExpandTags" {
        txt := "Show/hide all tags"
    } else if SubStr(i_sc, 1, 8) == "LayerTag" {
        tag := SubStr(i_sc, 9)
        if tag == "Active" {
            txt := "Toggle visibility of all active layers"
        } else if tag == "Inactive" {
            txt := "Toggle visibility of all inactive layers"
        } else {
            cnt := 0
            for layer in AllLayers.order {
                for tg in LayerTags[layer] {
                    if tg == tag {
                        cnt += 1
                    }
                }
            }
            txt := "Toggle visibility for layers with tag '" . tag . "' (" . cnt . " layer"
                . (cnt == 1 ? "" : "s") . ")"
        }
    } else if UI.buttons.Has(i_sc) {
        res := gui_entries.ubase.GetBaseHoldMod(i_sc, gui_mod_val, false, false, false, false)
        txt := _GetKeyInfo(i_sc, gui_mod_val, res, gui_entries) 
    } else {  ; path
        if type(obj) == "Gui.Text" {
            if obj.Text == "|" {
                prev_hwnd := 0
                ToolTip()
                return
            }
            t := SubStr(obj.Text, -1)
            t := t == "➤" ? "tap"
                : t == "▲" ? "hold"
                    : t == "▼" ? "chord"
                        : t == "•" ? "gesture"
                            : 0
            if !t {
                if obj.Gui.Hwnd == UI.Hwnd {
                    txt := "Current active modifiers for the view and next transition"
                }
            } else {
                md := Integer(SubStr(obj.Text, 1, -1) || 0)
                md := md ? _DecomposeMods(md, true) : false
                txt := "Transition by " . t . " event with"
                    . (md ? StrLen(md) > 1 ? (" mods " . md) : (" mod " . md) : "out mods")
            }
        } else {
            if obj.Text == root_text {
                txt := "Root level for all assignments on the current layout/language."
            } else {
                i := UI.path.Length
                while type(UI.path[i]) !== "Gui.Button" {
                    i -= 1
                }
                if UI.path[i].Text == obj.Text {
                    txt := "Last level of the current transition chain."
                    if i !== UI.path.Length {
                        txt .= "`nClick on it to reset active modifiers."
                    }
                } else {
                    txt := "One of the levels of the current transition chain.`n"
                        . "You can go to it with a click."
                }
            }
        }
    }

    if by_cursor_pos {
        ToolTip(txt)
    } else {
        prev_hwnd := ctrl_hwnd
        obj.GetPos(&x, &y, &w, &h)
        ToolTip(txt, x+w, y+h)
    }
}


_GetKeyInfo(sc, md, cur_entries, prev_entries,
    only_base:=false, only_hold:=false, is_chord:=false, is_gesture:=false, layer:="") {
    if !is_chord && !is_gesture {
        txt := "Key '" . _GetKeyName(sc, , true) . "' (sc " . sc . ")"
    } else if is_chord {
        txt := "Chord '" . sc . "'"
    } else if is_gesture {
        txt := ""
    }
    if !is_gesture {
        mods := _DecomposeMods(md, true)
        if md {
            txt .= " with mod " . mods
        } else {
            txt .= " without mods"
        }
    }
    b_node := only_hold ? false : _GetFirst(cur_entries.ubase, layer)
    h_node := only_base ? false : _GetFirst(cur_entries.uhold, layer)
    m_node := only_base ? false : _GetFirst(cur_entries.umod, layer)

    if !b_node && !h_node && !m_node {
        txt .= "`n`nUnassigned" . (only_base ? " tap event" : only_hold ? " hold event" : "")
    } else {
        if b_node {
            txt .= _GetNodeStrInfo(is_chord || is_gesture ? "Action" : "Tap",
                b_node, cur_entries.ubase, is_gesture, layer)
        }
        if m_node || h_node && h_node.down_type == TYPES.Modifier {
            node := m_node ? m_node : h_node
            cnt := _CountChild("", 0, 1 << node.down_val,
                prev_entries.ubase.scancodes,
                prev_entries.ubase.chords,
                prev_entries.ubase.gestures)
            cnt_combined := _CountChild("", 0, 1 << node.down_val,
                prev_entries.ubase.scancodes,
                prev_entries.ubase.chords,
                prev_entries.ubase.gestures, true)
            txt .= "`n`nHold: modifier " . node.down_val
                . " with " . cnt . " assignments under it"
            if cnt_combined > cnt {
                txt .= " (+" . cnt_combined - cnt . " from combined modifiers)"
            }
            if !layer_editing {
                cnt := 1
                if layer {
                    layers := layer
                    cnt := 1
                } else {
                    layers := ""
                    cnt := 0
                    t_unode := m_node ? cur_entries.umod : cur_entries.uhold
                    for l in t_unode.layers.order {
                        t_node := _GetFirst(t_unode, l)
                        if t_node.down_type == TYPES.Default || _EqualNodes(t_node, node) {
                            layers .= l . " & "
                            cnt += 1
                        }
                    }
                    layers := SubStr(layers, 1, -3)
                }
                txt .= "`nAssigned on the '" . layers . "' layer" . (cnt == 1 ? "" : "s")
            }
            txt .= _GetNodeExtraInfo(node) . "`n"
        } else if h_node {
            txt .= _GetNodeStrInfo("Hold", h_node, cur_entries.uhold, , layer)
        }
    }

    if !m_node {
        other_mods := prev_entries.ubase.active_scancodes.Get(sc, Map()).Clone()
        try other_mods.Delete(md)
        try other_mods.Delete(md+1)
        if other_mods.Count {
            seen := Map()
            t := ""
            b := false
            for md, val in other_mods {
                if !seen.Has(md & ~1) {
                    if !layer_editing || val.layers.map.Has(selected_layer) {
                        mods := _DecomposeMods(md, true)
                        if !mods {
                            b := true
                        } else {
                            t .= " " . mods . ","
                        }
                    }
                }
                seen[md & ~1] := true
            }
            if b && StrLen(t) {
                txt .= "`n`nHas other assignments without mods and with mods"
                . SubStr(t, 1, -1)
            } else if b {
                txt .= "`n`nHas other assignment without mods"
            } else if t {
                plural := (StrLen(t) == 3 ? "" : "s")
                txt .= "`n`nHas other assignment" . plural . " with mod" . plural
                . SubStr(t, 1, -1)
            }
        }
    }
    return Trim(txt, "`n")
}


_GetNodeStrInfo(base, node, unode, is_gesture:=false, layer:="") {
    res := "`n`n" . base . ": " . _SwitchByActionType(node.down_type, node.down_val)
    if !layer_editing {
        cnt := 1
        if layer {
            layers := layer
            cnt := 1
        } else {
            layers := ""
            cnt := 0
            for l in unode.layers.order {
                t_node := _GetFirst(unode, l)
                if t_node.down_type == TYPES.Default || _EqualNodes(t_node, node) {
                    layers .= l . " & "
                    cnt += 1
                }
            }
            layers := SubStr(layers, 1, -3)
        }
        res .= "`nAssigned on the '" . layers . "' layer" . (cnt == 1 ? "" : "s")
    }
    res .= _GetNodeExtraInfo(node, is_gesture)
    scs_cnt := _CountChild(layer, 0, 0, unode.scancodes, Map(), Map())
    chs_cnt := _CountChild(layer, 0, 0, Map(), unode.chords, Map())
    gst_cnt := _CountChild(layer, 0, 0, Map(), Map(), unode.gestures)
    if scs_cnt || chs_cnt || gst_cnt {
        t := (scs_cnt ? (scs_cnt . " scancodes; ") : "")
            . (chs_cnt ? (chs_cnt . " chords; ") : "")
            . (gst_cnt ? (gst_cnt . " gestures; ") : "")
        res .= "`nHas " . SubStr(t, 1, -2) . " nested on the next level"
    }
    return res
}


_GetNodeExtraInfo(node, is_gesture:=false) {
    res := ""
    if node.gui_shortname && node.gui_shortname !== node.down_val {
        res .= "`nNamed as '" . node.gui_shortname . "'"
    }
    if node.up_type !== TYPES.Disabled {
        res .= "`nAdditional action on release: " . _SwitchByActionType(node.up_type, node.up_val)
    }
    if node.is_instant && node.is_irrevocable {
        res .= "`nInstant and irrevocable execution is indicated"
    } else if node.is_instant {
        res .= "`nInstant execution is indicated"
    } else if node.is_irrevocable {
        res .= "`nIrrevocable execution is indicated"
    }
    if node.custom_lp_time {
        res .= "`nHas custom hold threshold – " . node.custom_lp_time
    }
    if node.custom_nk_time {
        res .= "`nHas custom child event waiting time – " . node.custom_nk_time
    }
    if node.child_behavior !== 4 {
        res .= "`nChild behavior is changed to '" . [
            "Backsearch", "Send current + backsearch",
            "To root", "Send current + to root", "Ignore"
        ][node.child_behavior] . "'"
    }
    if node.gesture_opts {
        vals := StrSplit(node.gesture_opts, ";")
        if is_gesture {
            res .= "`n`n" . ["Left top corner", "Top edge", "Right top corner", "Left edge",
                "Center", "Right edge", "Left bottom corner", "Bottom edge",
                "Right bottom corner"][Integer(vals[1])] . " pool"
            if vals[1] != 5 {
                res .= " (edge size by conf – " . CONF.edge_size.v . "px)"
            }
            sh := 0
            if vals[1] = 2 || vals[1] = 4 || vals[1] = 6 || vals[1] = 7 {
                sh := 3
                if CONF.edge_gestures.v == 1 || CONF.edge_gestures.v == 3 {
                    res .= "`nBUT according to global conf, you have disabled edge gestures!"
                }
            } else if vals[1] = 1 || vals[1] = 3 || vals[1] = 7 || vals[1] = 9 {
                sh := 6
                if CONF.edge_gestures.v == 1 || CONF.edge_gestures.v == 2 {
                    res .= "`nBUT according to global conf, you have disabled corner gestures!"
                }
            }
            if vals[2] = 0 {
                res .= "`nRotation: " . ["disabled", "de-noise", "any rotate"][CONF.gest_rotate.v]
                    . " (by global conf)"
            } else {
                res .= "`nRotation is "
                    . ["disabled", "de-noise", "any rotate"][Integer(vals[2]) + 1]
            }
            res .= "`nScale impact: " . (vals[3] || (CONF.scale_impact.v . " (by global conf)"))
                . "`nBidirectional is "
                . ["disabled", "enabled"][vals[4] ? (Integer(vals[4]) + 1) : 1]
                . "`nClosed figure with start point invariance is "
                . ["disabled", "enabled"][vals[5] ? (Integer(vals[5]) + 1) : 1]
            parent_opts := StrSplit(_GetFirst(_GetUnholdEntries().ubase).gesture_opts, ";")
            colors := parent_opts.Has(2+sh) ? parent_opts[2+sh] : 0
            grad_len := parent_opts.Has(3+sh) ? parent_opts[3+sh] : 0
            grad_loop := parent_opts.Has(4+sh) ? parent_opts[4+sh] : 0
            if colors || grad_len || grad_loop {
                res .= "`nCustom options from parent key-trigger:"
                if colors !== "" {
                    res .= "`n   Color " . colors
                }
                if grad_loop !== "" && grad_loop != CONF.grad_loop[sh/3+1].v {
                    res .= "`n   Gradient cycling is " . ["disabled", "enabled"][grad_loop+1]
                }
                if grad_len !== "" && grad_len != CONF.grad_loop[sh/3+1].v {
                    res .= "`n   Gradient cycle length " . grad_len
                }
            }
        } else {
            res .= "`n`nCustom for nested gestures:"
            p := vals.Get(1, CONF.gest_live_hint.v + 2)
            if p !== CONF.gest_live_hint.v + 2 {
                res .= "`nLive hints position – " . ["top", "center", "bottom", "disabled"][p-1]
            }
            loop 3 {
                i := (A_Index - 1) * 3
                colors := vals.Has(2+i) ? vals[2+i] : 0
                grad_len := vals.Has(3+i) ? vals[3+i] : 0
                grad_loop := vals.Has(4+i) ? vals[4+i] : 0
                if colors || grad_len || grad_loop {
                    res .= ["`nCenter pool:", "`nEdges:", "`nCorners:"][A_Index]
                    if colors !== "" {
                        res .= "`n   Color " . colors
                    }
                    if grad_loop !== "" && grad_loop != CONF.grad_loop[A_Index].v {
                        res .= "`n   Gradient cycling is " . ["disabled", "enabled"][grad_loop+1]
                    }
                    if grad_len !== "" && grad_len != CONF.grad_len[A_Index].v {
                        res .= "`n   Gradient cycle length " . grad_len
                    }
                }
            }
        }
    }
    return res
}


_SwitchByActionType(_type, _val) {
    switch _type {
        case TYPES.Disabled:
            return "{Disabled}"
        case TYPES.Default:
            return "{Default}"
        case TYPES.Text:
            return (StrLen(_val) == 1 ? "symbol '" : "text '")
                . _CheckDiacr(_val) . "'"
        case TYPES.KeySimulation:
            return "key simulation '" . _val . "'"
        case TYPES.Function:
            return "custom function '" . _val . "' execution"
        case TYPES.Chord:
            return "part of chord"
    }
}


_GetUnholdEntries() {
    path := buffer_view ? buffer_path : current_path
    if path.Length && path[-1][2] & 1 {
        _gui_entries := {
            ubase: ROOTS[buffer_view ? (buffer_view == 1 ? "buffer" : "buffer_h") : gui_lang],
        }
        for arr in path {
            if A_Index !== path.Length {
                _gui_entries := _gui_entries.ubase.GetBaseHoldMod(arr*)
            } else {
                _gui_entries := _gui_entries.ubase.GetBaseHoldMod(
                    arr[1], arr[2] & ~1, arr[3], arr[4]
                )
            }
        }
    } else {
        _gui_entries := gui_entries
    }
    return _gui_entries
}