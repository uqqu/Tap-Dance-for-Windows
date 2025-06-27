#Include "gui_draw.ahk"
#Include "gui_fill.ahk"
#Include "gui_layers.ahk"
#Include "gui_chords.ahk"
#Include "gui_forms.ahk"


current_path := []
selected_chord := ""
root_text := "root"

selected_layer := ""
selected_layer_priority := 0
layer_editing := 0

gui_mod_val := 0
gui_lang := 0
gui_entries := {ubase: ROOTS[gui_lang], uhold: false, umod: false}

temp_chord := 0
start_temp_chord := 0

A_TrayMenu.Click := TrayClick
A_TrayMenu.Add("tdfw", TrayClick)
A_TrayMenu.Default := "tdfw"
A_TrayMenu.ClickCount := 1

DrawLayout()


_GetFirst(node, certain_layer:="") {
    if !node {
        return false
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


OneNodeDeeper(schex, md:=-1, is_chord:=false) {
    global current_path, gui_entries, gui_mod_val

    if md == -1 {
        md := gui_mod_val
    }
    current_path.Push([schex, md, is_chord])
    gui_mod_val := 0
    gui_entries := gui_entries.ubase.GetBaseHoldMod(schex, md, is_chord)
    CloseForm()
    UpdateKeys()
}


ChangePath(len:=-1, *) {
    global gui_mod_val, gui_entries

    UI["Hidden"].Focus()
    if temp_chord {
        return
    }

    if len == -1 {
        len := current_path.Length
    } else {
        CloseForm()
    }

    ToggleVisibility(0, UI.path)
    UI.path := []

    gui_entries := {ubase: ROOTS[gui_lang], uhold: false, umod: false}
    gui_mod_val := len < current_path.Length ? current_path[len + 1][2] & ~1 : 0
    current_path.Length := len

    for arr in current_path {
        gui_entries := gui_entries.ubase.GetBaseHoldMod(arr[1], arr[2], arr[3])
    }

    UpdateKeys()
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

    ToggleEnabled(1, UI.layer_ctrl_btns, UI.layer_move_btns, UI.chs_toggles)

    _CreateOverlay()
    _FillPathline()
    _FillSetButtons()
    _FillKeyboard()
    _FillLayers()
    _FillChords()

    if prev_lang {
        DllCall("ActivateKeyboardLayout", "ptr", prev_lang, "uint", 0)
    }
}


HandleKeyPress(sc) {
    global temp_chord

    if sc == CONF.gui_back_sc {
        if current_path.Length {
            ChangePath(current_path.Length - 1)
        } else {
            ChangePath()
        }
    } else if sc == CONF.gui_set_sc && UI["BtnBase"].Enabled && UI["BtnBase"].Visible {
        OpenForm(0)
    } else if sc == CONF.gui_set_hold_sc && UI["BtnHold"].Enabled && UI["BtnHold"].Visible {
        OpenForm(1)
    } else if temp_chord {
        btn := UI.buttons[sc]
        if !btn.Enabled {
            return
        }
        if temp_chord.Has(sc) {
            temp_chord.Delete(sc)
            btn.Opt("+BackgroundSilver")
        } else {
            temp_chord[sc] := true
            btn.Opt("+BackgroundBBBB22")
        }
        btn.Text := btn.Text
    } else if CONF.gui_alt_ignore && (sc == 0x038 || sc == 0x138) {
        return
    } else if SubStr(sc, 1, 5) == "Wheel" {
        ButtonLBM(sc)
    } else {
        bnode := _GetFirst(gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val).ubase)
        b := KeyWait((sc is Number ? SC_STR[sc] : sc),
            (bnode && bnode.custom_lp_time ? "T" . bnode.custom_lp_time / 1000 : CONF.T))
        if WinActive("A") == UI.Hwnd {  ; with postcheck
            if sc == 0x038 || sc == 0x138 {  ; unfocus hidden menubar
                Send("{Alt}")
            }

            b ? ButtonLBM(sc) : ButtonRBM(sc)
        }
    }
}


ButtonLBM(sc, *) {
    UI["Hidden"].Focus()
    _Move(sc, 0)
}


ButtonRBM(sc, *) {
    global gui_mod_val

    UI["Hidden"].Focus()

    if sc == "WheelUp" || sc == "WheelDown" || sc == "CurrMod" {
        return
    }

    res := gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val, false, false, false)

    h_node := _GetFirst(res.uhold)
    if h_node && h_node.down_type == TYPES.Chord {
        return
    }

    m_node := _GetFirst(res.umod)
    md := h_node && h_node.down_type == TYPES.Modifier ? h_node
        : m_node && m_node.down_type == TYPES.Modifier ? m_node : false
    if md {
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
    OneNodeDeeper(sc, gui_mod_val + is_hold)
}


SaveValue(
    is_hold, layer, down_type, down_val:="",
    up_type:=false, up_val:="", is_instant:=false, is_irrevocable:=false,
    custom_lp_time:=false, custom_nk_time:=false, shortname:=""
) {
    json_root := DeserializeMap(layer)

    if !json_root.Has(gui_lang) {
        json_root[gui_lang] := [Map(), Map()]
    }
    json_node := _WalkJson(json_root[gui_lang], current_path, is_hold)
    json_node[1] := down_type
    json_node[2] := down_type == TYPES.Default || down_type == TYPES.Disabled ? "" : down_val . ""
    json_node[3] := up_type || TYPES.Disabled
    json_node[4] := up_type == TYPES.Default || json_node[3] == TYPES.Disabled ? "" : up_val . ""
    json_node[5] := is_instant
    json_node[6] := is_irrevocable
    json_node[7] := custom_lp_time
    json_node[8] := custom_nk_time
    json_node[9] := shortname
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
        "Confirmation", "YesNo Icon?"
    ) == "No" {
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
            json_root[gui_lang] := [Map(), Map()]
        }
        json_node := _WalkJson(json_root[gui_lang], current_path, is_hold)
        json_node[-1] := Map()
        json_node[-2] := Map()
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
        SetTimer(UpdateOverlayPos, 100)
    } else {
        UI.Hide()
        SetTimer(UpdateOverlayPos, 0)
        if overlay {
            overlay.Hide()
        }
    }
}


CloseEvent(*) {
    global overlay

    SetTimer(UpdateOverlayPos, 0)
    try overlay.Destroy()
    overlay := false
}


HideHelp(*) {
    IniWrite(0, "config.ini", "Main", "HelpTexts")
    CONF.help_texts := false
    for txt in UI.help_texts {
        txt.Visible := false
    }
    UI.help_texts := []
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


UpdateOverlayPos() {
    global overlay, overlay_x, overlay_y

    if !UI || !UI.Hwnd || !WinExist("ahk_id " . UI.Hwnd)
        || !(WinActive("A") == UI.Hwnd) && !(WinActive("A") == overlay.Hwnd) {
        overlay.Hide()
        return
    }
    WinGetPos &x, &y, , , "ahk_id " . UI.Hwnd

    if overlay && overlay.Hwnd && (overlay_x !== x || overlay_y !== y
        || !DllCall("IsWindowVisible", "Ptr", overlay.Hwnd)) {
        overlay.Show("x" . x . " y" . y)
        overlay_x := x
        overlay_y := y
    }
    WinActivate("ahk_id " . UI.Hwnd)
}