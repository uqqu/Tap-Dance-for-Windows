#Include "gui_draw.ahk"

is_gui_closed := 0

current_path := []
selected_chord := 0
root_text := "root"

selected_layer := 0
selected_layer_priority := 0
layer_editing := 0
cur_mod := 0
gui_lang := 0
gui_keys := DeepCopy(LANG_KEYS[gui_lang])

temp_chord := 0
start_temp_chord := 0
form := false

A_TrayMenu.Click := TrayClick
A_TrayMenu.Add("tdfw", TrayClick)
A_TrayMenu.Default := "tdfw"
A_TrayMenu.ClickCount := 1

DrawLayout()


Init() {
    global current_map, current_base, current_hold
    res := _WalkPath(gui_keys, current_path)
    current_map := res[1]
    current_base := res[2]
    current_hold := res[3]
    UpdateKeys()
}


TrayClick(*) {
    global is_gui_closed
    if is_gui_closed {
        keyboard_gui.Show()
    } else {
        keyboard_gui.Hide()
    }
    is_gui_closed := !is_gui_closed
}


CloseEvent(*) {
    global is_gui_closed
    is_gui_closed := true
}


ToggleDisabled(arr, state:=0) {
    for name in arr {
        sign := state == 0 || state == 2 && keyboard_gui[name].HasOpt("Disabled") ? "-" : "+"
        keyboard_gui[name].Opt(sign . "Disabled")
    }
}


ToggleVisibility(arr, state:=0) {
    for name in arr {
        keyboard_gui[name].Visible := !state ? false : (state == 1 ? true : !keyboard_gui[name].Visible)
    }
}


ChangePath(len, *) {
    keyboard_gui["Hidden"].Focus()
    if temp_chord {
        return
    }

    for elem in keyboard_gui.path {
        elem.Visible := false
    }

    keyboard_gui.path := []
    current_path.Length := len
    CleanMergedMap(gui_keys)
    Init()
}


UpdateKeys() {
    prev_lang := false
    if gui_lang {
        prev_lang := GetCurrentLayout()
        if gui_lang != prev_lang {
            DllCall("ActivateKeyboardLayout", "ptr", gui_lang, "uint", 0)
        } else {
            prev_lang := false
        }
    }

    ToggleDisabled([
        "BtnDeleteSelectedChord", "BtnChangeSelectedChord", "BtnViewSelectedLayer", "BtnRenameSelectedLayer",
        "BtnDeleteSelectedLayer", "BtnMoveUpSelectedLayer", "BtnMoveDownSelectedLayer"
    ], 1)

    _FillPathline()
    _FillKeyboard()
    _FillLV()

    if prev_lang {
        DllCall("ActivateKeyboardLayout", "ptr", prev_lang, "uint", 0)
    }
}


HandleKeyPress(sc) {
    global temp_chord

    if temp_chord {
        btn := keyboard_gui.buttons[sc]
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
        return
    }

    b := KeyWait(SC_STR[sc], T)
    if WinActive("A") == keyboard_gui.Hwnd {  ; with postcheck
        if sc == 0x038 || sc == 0x138 {  ; unfocus hidden menubar
            Send("{Alt}")
        }

        b ? ButtonLBM(sc) : ButtonRBM(sc)
    }
}


ButtonLBM(sc, *) {
    keyboard_gui["Hidden"].Focus()
    _Move(sc, 0)
}


ButtonRBM(sc, *) {
    global cur_mod

    keyboard_gui["Hidden"].Focus()
    if _GetType(current_hold) == 5 {
        return
    } else if _GetType(_WalkPath(current_map, [sc, 0, false])[3]) == 4 {
        cur_mod ^= 1 << _GetVal(_WalkPath(current_map, [sc, 0, false])[3])
        Init()
        return
    }
    _Move(sc, 1)
}


_Move(sc, is_hold) {
    global cur_mod

    if temp_chord {
        HandleKeyPress(sc)
        return
    }

    current_path.Push([sc, cur_mod + is_hold, false])
    cur_mod := 0
    Init()
}


SC_ArrToString(arr) {
    result := ""
    for sc in arr {
        if sc {
            result .= _GetKeyName(sc) . " "
        }
    }
    return result
}


OpenForm(save_type, *) {
    ; 0 – base value, 1 – hold value, 2 – chord
    global form
    try {
        form.Destroy()
    }

    form := Gui(, "Set value")
    form.OnEvent("Close", CloseForm)

    val := 0
    if save_type == 0 {
        val := current_base
    } else if save_type == 1 {
        val := current_hold
    } else if selected_chord != "" {
        val := _WalkPath(current_map, [selected_chord, cur_mod, true])[2]
    }

    y := 40
    layer_vals := Map()
    if val {
        for opt in val {
            for name in opt[4] {
                layer_vals[name] := [opt[1], opt[2]]
            }
        }
    }

    if !current_path.Length || !SYS_MODIFIERS.Has(current_path[current_path.Length][1]) {
        prior_type := _GetType(val) ? _GetType(val) : 1
        if prior_type == 2 && !current_path[current_path.Length][2] {
            prior_type := 1
        }
        form.Add("DropDownList", "x10 y10 w300 vDDL",
            save_type == 1 ? ["Text", "Key simulation", "Function", "Modifier"]
                : ["Text", "Key simulation", "Function"]
        )
        form["DDL"].OnEvent("Change", ChangeFormPlaceholder.Bind(layer_vals))
        form["DDL"].Value := prior_type
        y += 20
    }
    form.Add("Edit", "w300 vInput")

    if !layer_editing {
        form.Add("DropDownList", "x10 y" . y . " w300 vLayersDDL Choose1",
            ACTIVE_LAYERS.Length ? ACTIVE_LAYERS : ALL_LAYERS
        )
        form["LayersDDL"].OnEvent("Change", ChangeFormPlaceholder.Bind(layer_vals))
        y += 20
    }
    ChangeFormPlaceholder(layer_vals)

    form.Add("Button", "x10 y" . y . " h20 w150 vCancel", "❌ Cancel")
    form.Add("Button", "x160 y" . y . " h20 w150 vSave", "✔ Save")
    form["Cancel"].OnEvent("Click", CloseForm)
    if save_type == 2 {
        form["Save"].OnEvent("Click", WriteChord)
    } else {
        form["Save"].OnEvent("Click", WriteValue.Bind(save_type))
    }

    form.Show("h" . 30 + y . " w320")
    form["Input"].Focus()
}


CloseForm(*) {
    global form
    try {
        form.Destroy()
    }
    form := 0
}


WriteValue(is_hold, *) {
    global form
    val := 4  ; only case without ddl – form for system modifier keys
    try {
        val := form["DDL"].Value
    }
    if val == 4 {
        try {
            if !(0 < Integer(form["Input"].Text) && Integer(form["Input"].Text) < 61) {
                throw
            }
        } catch {
            MsgBox("The modifier value must be a number up to 60.")
            return
        }
    }
    if layer_editing {
        SaveValue(is_hold, val, form["Input"].Text)
    } else {
        SaveValue(is_hold, val, form["Input"].Text, 
            (ACTIVE_LAYERS.Length ? ACTIVE_LAYERS : ALL_LAYERS)[form["LayersDDL"].Value]
        )
    }
    form.Destroy()
    form := 0
}


SaveValue(is_hold, type, val, layer:=0) {
    global gui_keys

    temp_layer := layer_editing ? selected_layer : layer
    current_temp_keys := DeserializeMap(temp_layer)

    if !current_temp_keys.Has(gui_lang) {
        current_temp_keys[gui_lang] := Map()
    }
    res := _WalkPath(current_temp_keys[gui_lang], current_path, false)

    _SetTypeVal(res[2 + is_hold], type, val)
    SerializeMap(current_temp_keys, temp_layer)

    ReadLayers()
    if !layer_editing {
        gui_keys := DeepCopy(LANG_KEYS[gui_lang])
    } else {
        gui_keys := Map()
        _DeepMergePreserveVariants(gui_keys, current_temp_keys[gui_lang], temp_layer)
    }
    Init()
}


ClearCurrentValue(is_hold, *) {
    if !current_path[current_path.Length][2] && !is_hold {
        new_type := 2
        new_val := SC_STR_BR[current_path[current_path.Length][1]]
    } else {
        new_type := 0
        new_val := ""
    }
    if layer_editing {
        SaveValue(is_hold, new_type, new_val)
    } else {
        res := _WalkPath(ALL_LAYERS_LANG_KEYS[gui_lang], current_path)
        layers := []
        for opt in (is_hold ? res[3] : res[2]) {
            for v in _GetNames(opt) {
                layers.Push(v)
            }
        }
        if !layers.Length {
            return
        }
        selected_layers := layers.Length == 1 ? layers : ChooseLayers(layers)
        for layer in selected_layers {
            SaveValue(is_hold, new_type, new_val, layer)
        }
    }
}


ChangeFormPlaceholder(layer_vals, *) {
    static placeholders := [
        "Value (just raw text)",
        "Key simulation in ahk syntax like '+{SC010}', '{Volume_up}'",
        "Function name",
        "Modifier number"
    ]

    val := 4
    try {
        val := form["DDL"].Value
    }
    SendMessage(0x1501, true, StrPtr(placeholders[val]), form["Input"].Hwnd)
    if layer_vals.Count == 0 {
        layer := ""
    } else {
        try {
            layer := form["LayersDDL"].Text
        } catch {
            for k, _ in layer_vals {
                layer := k
            }
        }
    }
    if layer_vals.Has(layer) && val == layer_vals[layer][1] {
        form["Input"].Text := layer_vals[layer][2]
    } else {
        form["Input"].Text := ""
    }
}


ChangeLang(lang, *) {
    global gui_lang, gui_keys
    keyboard_gui["Hidden"].Focus()
    gui_lang := LANG_CODES[lang]
    if !layer_editing {
        gui_keys := DeepCopy(LANG_KEYS[gui_lang])
    } else {
        LVLayerDoubleClick(0, 0, true)
    }
    Init()
}


#Include "gui_chords.ahk"
#Include "gui_layers.ahk"