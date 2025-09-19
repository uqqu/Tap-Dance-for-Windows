﻿form := false
func_form := false
init_drawing := false
from_prev := false


OpenForm(save_type, *) {
    ; 0 – base value, 1 – hold value, 2 – chord, 3 – gesture
    global form, from_prev

    try form.Destroy()

    if !CONF.hide_mouse_warnings && current_path.Length
        && SubStr(current_path[-1][1], 2) == "Button"
        && MsgBox("This assignment will remove the corresponding drag-and-drop behavior!",
            "Attention", "OKCancel Icon!") == "Cancel" {
            return
    }

    form := Gui(, "Set value")
    form.OnEvent("Close", CloseForm)
    form.OnEvent("Escape", CloseForm)

    chord_as_base := false
    gest_as_base := false
    ; check and correct if it "base" from chord/gesture
    if !save_type && current_path.Length && (current_path[-1][3] || current_path[-1][4]) {
        entries := {ubase: ROOTS[gui_lang], uhold: false, umod: false}
        path := current_path.Clone()
        path.Length -= 1

        for arr in path {
            entries := entries.ubase.GetBaseHoldMod(arr*)
        }

        if current_path[-1][3] {
            chord_as_base := true
            save_type := 2
            unode := entries.ubase.GetBaseHoldMod(selected_chord, gui_mod_val, true).ubase
        } else {
            gest_as_base := true
            save_type := 3
            unode := entries.ubase.GetBaseHoldMod(selected_gesture, gui_mod_val, false, true).ubase
        }
    } else {
        unode := save_type == 1 ? gui_entries.uhold : save_type == 2
            ? gui_entries.ubase.GetBaseHoldMod(selected_chord, gui_mod_val, true).ubase
            : save_type == 3
                ? gui_entries.ubase.GetBaseHoldMod(selected_gesture, gui_mod_val, false, true).ubase
                : gui_entries.ubase
    }

    layers := layer_editing ? [selected_layer] : GetLayerList()
    prior_layer := false
    if unode {
        for layer in layers {
            if unode.layers.map.Has(layer) && unode.layers[layer][0] {
                prior_layer := layer
                break
            }
        }
    }
    curr_val := prior_layer ? unode.layers[prior_layer][0] : false

    if layers.Length > 1 {
        form.Add("DropDownList", "x10 y+10 w320 vLayersDDL Choose1", layers)
        form["LayersDDL"].OnEvent("Change",
            ChangeFormPlaceholder.Bind(
                unode, layers, save_type, (save_type > 1 ? 0 : 2), 1
            )
        )
        try form["LayersDDL"].Text := prior_layer
    }

    child_behavior_opts := [
        "Backsearch", "Send current + backsearch", "To root", "Send current + to root", "Ignore"
    ]

    ; sysmod
    if current_path.Length && SYS_MODIFIERS.Has(current_path[-1][1]) {
        form.Title := "Set modifier value"
        form.Add("Edit", "y+10 w320 vValInp")
        form.Add("Text", "y+10 w160", "Unassigned child behavior:")
        form.Add("DropDownList", "yp-3 x+0 w160 vChildBehaviorDDL Choose5", child_behavior_opts)
        form.Add("Edit", "y+10 x10 w320 vShortname")
        form.Add("Button", "x10 y+10 h20 w160 vCancel", "❌ Cancel")
        form.Add("Button", "x170 yp+0 h20 w160 Default vSave", "✔ Save")
        form["Cancel"].OnEvent("Click", CloseForm)
        form["Save"].OnEvent("Click", WriteValue.Bind(save_type))

        SendMessage(0x1501, true, StrPtr("Modifier number"), form["ValInp"].Hwnd)
        SendMessage(0x1501, true, StrPtr("GUI shortname"), form["Shortname"].Hwnd)

        form.Show("w340")
        ChangeFormPlaceholder(unode, layers, 1, 0, 0)
        form["ValInp"].Focus()
        return
    }

    ; action types for different events
    type_list := [
        ["Disabled", "Default", "Text", "KeySimulation", "Function"],  ; base / hold under mods
        ["Disabled", "Default", "Text", "KeySimulation", "Function", "Modifier"],  ; hold
        ["Disabled", "Text", "KeySimulation", "Function"],  ; chords
        ["Text", "KeySimulation", "Function"]  ; gestures
    ][save_type == 1 && current_path[-1][2] ? 1 : save_type + 1]

    form.Add("DropDownList", "x10 y+10 w320 vTypeDDL", type_list)
    form.Add("Edit", "y+10 w320 vValInp")
    form.Add("Text", "y+10 w160", "Unassigned child behavior:")
    form.Add("DropDownList", "yp-3 x+0 w160 vChildBehaviorDDL Choose4", child_behavior_opts)

    ; custom values
    form.Add("CheckBox", "x10 y+10 w160 vCBInstant", "Instant")

    form.Add("Edit", "x170 yp-3 w160 vCustomLP Number +Center", CONF.MS_LP).Visible := false
    SendMessage(0x1501, true, StrPtr("Your custom lp value (in ms)"), form["CustomLP"].Hwnd)
    form.Add("Button", "x170 yp+0 w160 vBtnLP", "Custom hold waiting time")
        .OnEvent("Click", (*) => (
            form["BtnLP"].Visible := false, form["CustomLP"].Visible := true)
        )

    form.Add("CheckBox", "x10 y+5 w160 vCBIrrevocable", "Irrevocable")

    if current_path.Length && current_path[-1][2] & ~1 {
        form["CBIrrevocable"].Value := true
    }

    form.Add("Edit", "x170 yp-3 w160 vCustomNK Number +Center", CONF.MS_NK).Visible := false
    SendMessage(0x1501, true, StrPtr("Your custom nk value (in ms)"), form["CustomNK"].Hwnd)
    form.Add("Button", "x170 yp+0 w160 vBtnNK", "Custom next event waiting time")
        .OnEvent("Click", (*) => (
            form["BtnNK"].Visible := false, form["CustomNK"].Visible := true)
        )

    ; gesture
    if save_type == 3 {
        form.Add("Edit", "x10 y+10 w320 vShortname")
        SendMessage(0x1501, true, StrPtr("GUI shortname"), form["Shortname"].Hwnd)
        form.Add("Button", "x10 y+20 w320 vSetGesture", "Set gesture pattern")
            .OnEvent("Click", SetGesture)

        form.Add("Text", "x10 y+7 w160 Center", "Scale impact:")
        form.Add("Edit", "x+0 yp-3 w160 vScaling +Center")
        SendMessage(0x1501, true, StrPtr("Empty – by conf; 0-0.99"), form["Scaling"].Hwnd)
        for arr in [
            ["Rotate", "Rotate:",
                ["By global conf", "No", "Remove orientation noise", "Orientation invariance"]],
            ["Direction", "Any direction:", ["No", "Yes (draw direction invariance)"]],
            ["Phase", "Any start point (for closed figures):", ["No", "Yes (start invariance)"]],
        ] {
            form.Add("Text", "x10 y+7 w160 Center", arr[2])
            form.Add("DDL", "x+0 yp-3 w160 Choose1 v" . arr[1], arr[3])
        }
        form["Phase"].Opt("Disabled")

    ; extra up value/gesture colors & shortname
    } else if save_type !== 2 {
        form.Add("Edit", "x10 y+10 w320 vShortname")
        form.Add("Button", "x10 y+10 w160 vUpToggle", "Additional up action")
        form.Add("Button", "x+0 yp0 w160 vColorToggle", "Custom gesture overlay opts")
            .OnEvent("Click", ShowHideGestOpts)
        form.Add("DropDownList", "x10 y+10 w320 vUpTypeDDL", type_list).Visible := false
        form.Add("Edit", "x10 y+10 w320 vUpValInp").Visible := false

        form.Add("Text", "x10 yp-35 w160 Center vLHText", "Live recognition position:")
            .Visible := false
        form.Add("DDL", "x+0 yp-3 w160 Choose1 vLiveHint",
            ["By conf", "Top", "Center", "Bottom", "Disable"]).Visible := false
        form.color_buttons := [
            form.Add("Button", "x10 y+8 w106 vColorGeneral", "General"),
            form.Add("Button", "x+0 yp0 w106 vColorEdges", "Edges"),
            form.Add("Button", "x+0 yp0 w106 vColorCorners", "Corners"),
        ]
        for i, btn in form.color_buttons {
            btn.OnEvent("Click", _FormToggleColors.Bind(i))
            btn.Visible := false
        }
        form["ColorGeneral"].Opt("+Disabled")

        form.colors := [[], [], []]
        for i, name in ["", "Edges", "Corners"] {
            form.colors[i].Push(
                form.Add("Text", "x10 y288 h20 w160", "Gesture colors:"),
                form.Add("Edit", "Center x+0 yp0 h20 w160 vColorInp" . name),
                form.Add("Text", "x10 y+5 h20 w160", "Gradient cycle length:"),
                form.Add("Edit", "Center x+0 yp0 h20 w160 vGradLenInp" . name),
                form.Add("CheckBox", "x10 y+5 w320 vGradCycle" . name, "Gradient cycling"),
            )
            for a in form.colors[i] {
                a.Visible := false
            }
        }

        form["UpTypeDDL"]
            .OnEvent("Change", ChangeFormPlaceholder.Bind(unode, layers, save_type, 1, 0))
        form["UpTypeDDL"].Text := curr_val ? TYPES_R[curr_val.up_type] : "Disabled"
        form["UpToggle"].OnEvent("Click", ShowHideUpVals)
        if curr_val && curr_val.up_type !== TYPES.Disabled {
            ShowHideUpVals()
        } else if curr_val && curr_val.gesture_opts {
            ShowHideGestOpts()
        }

        SendMessage(0x1501, true, StrPtr("GUI shortname"), form["Shortname"].Hwnd)
    }

    ; control
    form.Add("Button", "x10 y+10 h20 w160 vCancel", "❌ Cancel").OnEvent("Click", CloseForm)
    form.Add("Button", "x170 yp+0 h20 w160 Default vSave", "✔ Save")
        .OnEvent("Click", (save_type == 2
            ? (chord_as_base ? WriteChord.Bind(current_path[-1][1]) : WriteChord.Bind(0))
            : save_type == 3 ? (gest_as_base ? WriteGesture.Bind(current_path[-1][1])
                : WriteGesture.Bind(0)) : WriteValue.Bind(save_type))
        )
    if save_type == 3 {
        if !selected_gesture {
            form["Save"].Opt("+Disabled")
        } else {
            from_prev := true
        }
    }

    form["TypeDDL"].OnEvent("Change", ChangeFormPlaceholder.Bind(unode, layers, save_type, 0, 0))
    form["TypeDDL"].Text := curr_val ? TYPES_R[curr_val.down_type] : "Text"
    form.Show("w340")
    ChangeFormPlaceholder(unode, layers, save_type, (save_type > 1 ? 0 : 2), 0)
}


ShowHideUpVals(*) {
    if form["UpTypeDDL"].Visible {
        form["UpTypeDDL"].Visible := false
        form["UpValInp"].Visible := false
    } else {
        form["UpTypeDDL"].Visible := true
        form["UpValInp"].Visible := true

        form["LiveHint"].Visible := false
        form["LHText"].Visible := false
        for btn in form.color_buttons {
            btn.Visible := false
        }
        for arr in form.colors {
            for elem in arr {
                elem.Visible := false
            }
        }
    }
}


ShowHideGestOpts(*) {
    form["UpTypeDDL"].Visible := false
    form["UpValInp"].Visible := false

    if form.color_buttons[1].Visible {
        form["LiveHint"].Visible := false
        form["LHText"].Visible := false
        for btn in form.color_buttons {
            btn.Visible := false
        }
        for arr in form.colors {
            for elem in arr {
                elem.Visible := false
            }
        }
    } else {
        form["LiveHint"].Visible := true
        form["LHText"].Visible := true
        for btn in form.color_buttons {
            btn.Visible := true
        }
        for i, btn in form.color_buttons {
            if !btn.Enabled {
                for elem in form.colors[i] {
                    elem.Visible := true
                }
                break
            }
        }
    }
}


_FormToggleColors(trg, *) {
    for i, arr in form.colors {
        for elem in arr {
            elem.Visible := i == trg
        }
        form.color_buttons[i].Opt((i == trg ? "+" : "-") . "Disabled")
    }
}


SetGesture(*) {
    global init_drawing, from_prev

    from_prev := false
    form["SetGesture"].Text := "Draw a gesture while holding RBM"
    init_drawing := true
    form["Phase"].Opt("Disabled")
    form["Phase"].Value := 1
    form["Save"].Opt("Disabled")
}


WriteGesture(as_base:=false, *) {
    global form

    try {
        scal := form["Scaling"].Text == "" ? CONF.scale_impact : Float(form["Scaling"].Text)
    } catch {
        MsgBox("Scale value should be float or empty.", "Wrong scale value", "Icon!")
        return
    }
    rot := form["Rotate"].Value == 1 ? CONF.gest_rotate : (form["Rotate"].Value - 1)
    dirs := form["Direction"].Value - 1
    phase := form["Phase"].Value - 1

    if !from_prev {
        gest_str := GestureToStr(points, rot, scal, dirs, phase)
    } else {
        gest := gui_entries.ubase.GetBaseHoldMod(selected_gesture, gui_mod_val, false, true).ubase
        vals := StrSplit(gest.fin.gesture_opts, ";")
        if scal != 0 && vals[-1] = 1 {
            MsgBox("To enable the scale impact, the gesture must be redrawn.",
                "Old pattern", "Icon!")
            return
        }
        opts := vals[1] . ";" . rot - 1 . ";" . scal . ";" . dirs . ";" . phase . ";" . vals[-1]
        if StrLen(StrSplit(selected_gesture, " ")[1]) !== 1 {
            gest_str := [vals[1] . " " . selected_gesture, opts]
        } else {
            gest_str := [selected_gesture, opts]
        }
    }

    layers := GetLayerList()
    temp_layer := layer_editing ? selected_layer
        : (layers.Length == 1 ? layers[1] : form["LayersDDL"].Text)
    json_root := DeserializeMap(temp_layer)
    if !json_root.Has(gui_lang) {
        json_root[gui_lang] := ["", Map(), Map(), Map()]
    }
    if as_base {
        path := current_path.Clone()
        path.Length -= 1
        res := current_path.Length > 1 ? _WalkJson(json_root[gui_lang], path)
            : json_root[gui_lang]
    } else {
        res := current_path.Length ? _WalkJson(json_root[gui_lang], current_path)
            : json_root[gui_lang]
    }
    json_gestures := res[-1]

    if json_gestures.Has(gest_str[1]) && MsgBox("Same gesture already exists on this layer. "
        . "Do you want to overwrite it?", "Confirmation", "YesNo Icon?") == "No" {
        return
    }

    try sc_mp := json_gestures[gest_str[1]][gui_mod_val][-3]
    try ch_mp := json_gestures[gest_str[1]][gui_mod_val][-2]

    if selected_gesture {
        if json_gestures[selected_gesture].Count !== 1 {
            json_gestures[selected_gesture].Delete(gui_mod_val)
        } else {
            json_gestures.Delete(selected_gesture)
        }
    }

    if !json_gestures.Has(gest_str[1]) {
        json_gestures[gest_str[1]] := Map()
    }
    json_gestures[gest_str[1]][gui_mod_val] := [
        TYPES.%form["TypeDDL"].Text%, form["ValInp"].Text . "", TYPES.Disabled, "",
        Integer(form["CBInstant"].Value), Integer(form["CBIrrevocable"].Value),
        0, Integer(form["CustomNK"].Text), Integer(form["ChildBehaviorDDL"].Value),
        form["Shortname"].Text || form["ValInp"].Text,
        gest_str[2], sc_mp ?? Map(), ch_mp ?? Map(), Map(),
    ]

    SerializeMap(json_root, temp_layer)

    FillRoots()
    if layer_editing {
         AllLayers.map[selected_layer] := true
        _MergeLayer(selected_layer)
    }
    UpdLayers()
    ChangePath()
    CloseForm()
}


ChangeFormPlaceholder(unode, layers, save_type:=0, is_up:=0, is_layer_editing:=0, *) {
    static placeholders:=[
        "Disabled",
        "Default key value",
        "Value (just raw text)",
        "Key simulation in ahk syntax like '+{SC010}', '{Volume_up}'",
        "Function name",
        "Modifier number"
    ]

    layer := layers.Length > 1 ? form["LayersDDL"].Text : layers[1]
    name := [" value ", " value ", " chord ", " gesture "][save_type + 1]

    is_type := false
    try is_type := form["TypeDDL"]
    if !is_type {  ; sysmod
        form["ValInp"].Text := ""
        form["Shortname"].Text := ""
        try form["ValInp"].Text := unode.layers[layer][0].down_val
        try form["Shortname"].Text := unode.layers[layer][0].gui_shortname
        form["ValInp"].Focus()
        return
    }

    inp := is_up ? form["UpValInp"] : form["ValInp"]
    type_field := is_up ? form["UpTypeDDL"] : form["TypeDDL"]
    curr_type := type_field.Text

    SendMessage(0x1501, true, StrPtr(placeholders[TYPES.%curr_type%]), inp.Hwnd)

    if unode && unode.layers.Length && unode.layers.Has(layer) && unode.layers[layer][0] {
        val := unode.layers[layer][0]
        irrevoc := val.is_irrevocable
        instant := val.is_instant
        child_behavior := val.child_behavior
        gui_name := val.gui_shortname
        lp := val.custom_lp_time
        nk := val.custom_nk_time

        if is_layer_editing {
            curr_type := TYPES_R[(is_up ? val.up_type : val.down_type)]
            form["TypeDDL"].Text := curr_type
        }
        if TYPES.%curr_type% == (is_up ? val.up_type : val.down_type) {
            inp.Text := is_up ? val.up_val : val.down_val
        }

        if val.HasOwnProp("opts") {  ; gesture
            form["Scaling"].Text := Round(val.opts.scaling, 2)
            form["Rotate"].Value := val.opts.rotate + 2
            form["Direction"].Value := val.opts.dirs + 1
            if val.opts.closed {
                form["Phase"].Value := val.opts.closed + 1
                form["Phase"].Opt("-Disabled")
            }
        } else if val.gesture_opts {
            opts := StrSplit(val.gesture_opts, ";")
            for i, name in [
                "LiveHint", "ColorInp", "GradLenInp", "GradCycle",
                "ColorInpEdges", "GradLenInpEdges", "GradCycleEdges",
                "ColorInpCorners", "GradLenInpCorners", "GradCycleCorners",
            ] {
                if i > opts.Length {
                    break
                }
                if !opts[i] {
                    continue
                }
                form[name].Value := opts[i]
            }
        }
        title := "Existing" . name . "on layer '" . layer . "'"
    }

    form.Title := title ?? "New" . name . "for layer '" . layer . "'"

    if save_type {
        try form["CustomLP"].Visible := 0
        try form["BtnLP"].Visible := 0
    } else {
        form["CustomLP"].Text := lp ?? 0
        form["BtnLP"].Visible := !(lp ?? 0)
        form["CustomLP"].Visible := lp ?? 0
    }

    form["CustomNK"].Text := nk ?? 0
    form["BtnNK"].Visible := !(nk ?? 0)
    form["CustomNK"].Visible := nk ?? 0

    if save_type !== 2 {
        if IsSet(gui_name) {
            form["Shortname"].Text := gui_name
        }
    }
    if save_type < 2 {
        form["ChildBehaviorDDL"].Value := child_behavior
            ?? (4 + (form["TypeDDL"].Text == "Modifier"))
    }

    form["CBIrrevocable"].Value := irrevoc ?? 0
    form["CBInstant"].Value := instant ?? 0

    curr_type == "Function" ? SetUpFunction(is_up) : inp.Focus()
    if curr_type == "Default" || curr_type == "Disabled" {
        inp.Text := ""
        inp.Visible := false
    } else {
        inp.Visible := true
    }

    if is_up && curr_type !== "Disabled" && !form["UpTypeDDL"].Visible {
        ShowHideUpVals()
    }

    if is_up == 2 {
        ChangeFormPlaceholder(unode, layers, save_type, 0, is_layer_editing)
    }
}


SetUpFunction(is_up) {
    global func_form, func_fields, func_params

    if func_form {
        return
    }

    func_fields := []
    func_params := []

    args := false
    name := false
    func_str := is_up ? form["UpValInp"].Text : form["ValInp"].Text
    try {
        if func_str && RegExMatch(func_str, "^(?<name>\w+)(?:\((?<args>.*)\))?$", &m) {
            name := m["name"]
            args := _ParseFuncArgs(m["args"])
            arg_fields := custom_funcs[name]
            if arg_fields[2] is Array {
                l := arg_fields[2].Length
                for arg in args {
                    idx := A_Index // l + 1
                    if func_params.Length < idx {
                        func_params.Push([])
                    }
                    func_params[idx].Push(arg)
                }
            } else {
                func_params.Push(args)
            }
        }
    }

    func_form := Gui(, "Function Selector (" . (is_up ? "up" : "down") . ")")
    func_form.OnEvent("Close", FuncFormClose)

    func_form.Add("Button", "x10 y10 w160 h19 vBtnPrev", "-")
        .OnEvent("Click", PrevFields.Bind(is_up))
    func_form.Add("Button", "x170 yp+0 w160 h19 vBtnNext", "+")
        .OnEvent("Click", NextFields.Bind(is_up))

    func_form.Add("DropDownList", "x10 y40 w240 vFuncDDL Choose1", custom_func_keys)
        .OnEvent("Change", ChangeFields)

    func_form.Add("Button", "x250 yp+0 w80 h19 vSave", "✔ Assign")
        .OnEvent("Click", SaveAssignedFunction.Bind(is_up))
    func_form.Add("Text", "x10 y+10 w320 h42 vDescription +0x1000", "")
    WinGetPos(&x, &y, &w, &h, "ahk_id " . form.Hwnd)
    if name {
        try func_form["FuncDDL"].Text := name
    }
    func_form.Show("w340 h" . 291 + (layer_editing ? 0 : 28) . " x" . x + w . " y" . y)
    RefreshFields()
}


ChangeFields(*) {
    global func_params

    func_params := []
    RefreshFields()
}


PrevFields(is_up, *) {
    global func_params

    func_params.Length -= 1

    PasteToInput(is_up)
    RefreshFields()
}


NextFields(is_up, *) {
    global func_params

    if func_fields.Length == 1 {
        func_params.Push(func_fields[1].Text)
    } else {
        func_params.Push([])
        for elem in func_fields {
            func_params[-1].Push(elem.Text)
        }
    }

    PasteToInput(is_up)
    RefreshFields()
}


RefreshFields(*) {
    global func_fields

    additional_field := false
    name := func_form["FuncDDL"].Text
    arg_fields := custom_funcs[name]

    for elem in func_fields {
        elem.Visible := false
    }
    func_fields := []

    func_form["BtnPrev"].Visible := false
    func_form["BtnNext"].Visible := false

    y := 130

    for arg in arg_fields {
        if A_Index == 1 {
            func_form["Description"].Text := arg
            continue
        }

        if arg is Array {
            for elem in arg {
                func_fields.Push(func_form.Add("Edit", "w320 x10 y" . y))
                SendMessage(0x1501, true, StrPtr(elem), func_fields[-1].Hwnd)
                try func_fields[-1].Text := func_params[-1][A_Index]
                y += 30
            }
            func_form["BtnPrev"].Visible := true
            func_form["BtnNext"].Visible := true
        } else if arg is Integer {
            func_fields.Push(
                func_form.Add("DDL", "w320 x10 y" . y . " Choose1", custom_func_ddls[arg])
            )
            try func_fields[-1].Text := func_params[-1][A_Index-1]
            if arg == 2 {  ; outputs
                func_fields[-1].OnEvent("Change", OutputChange)
                additional_field := func_fields[-1].Value == 3 ? 2 : 1
            }
            y += 30
        } else {
            func_fields.Push(func_form.Add("Edit", "w320 x10 y" . y))
            SendMessage(0x1501, true, StrPtr(arg), func_fields[-1].Hwnd)
            try func_fields[-1].Text := func_params[-1][A_Index-1]
            y += 30
        }
    }
    if additional_field {
        func_fields.Push(func_form.Add("Edit", "w320 x10 y" . y))
        SendMessage(0x1501, true, StrPtr("Tooltip show time (default 3000 ms)"),
            func_fields[-1].Hwnd)
        if func_params.Length && func_params[-1].Length == arg_fields.Length {
            try func_fields[-1].Text := func_params[-1][-1]
        }
        if additional_field == 1 {
            func_fields[-1].Visible := false
        }
    }
    func_form["BtnPrev"].Opt((func_params.Length ? "-" : "+") . "Disabled")
    func_form.Show()
}


OutputChange(ddl_obj, *) {
    func_fields[-1].Visible := ddl_obj.Value == 3
}


PasteToInput(is_up:=false) {
    global func_form

    form[is_up ? "UpTypeDDL" : "TypeDDL"].Text := "Function"
    inp := form[is_up ? "UpValInp" : "ValInp"]
    inp.Opt("-Disabled")
    if !func_params.Length {
        inp.Text := func_form["FuncDDL"].Text
    } else {
        str_val := "("
        for val in func_params {
            if val is Array {
                if val.Length == 1 {
                    str_val .= val[1] . ", "
                    continue
                }
                arr_val := "["
                for elem in val {
                    arr_val .= elem . ", "
                }
                str_val .= SubStr(arr_val, 1, -2) . "], "
            } else {
                str_val .= val . ", "
            }
        }
        str_val := RegExReplace(str_val, "[,\s]+$") . ")"
        inp.Text := func_form["FuncDDL"].Text . (str_val !== "()" ? str_val : "")
    }
}


SaveAssignedFunction(is_up:=false, *) {
    global func_params

    additional_field := false
    func_name := func_form["FuncDDL"].Text
    args := custom_funcs[func_name]
    if args.Length > 1 && !(args[2] is Array) {
        func_params := []
    }

    idx := 1
    for i, arg in args {
        if i == 1 {
            continue
        }
        if arg is Array {
            func_params.Push([])
            for elem in arg {
                func_params[-1].Push(func_fields[idx].Text)
                idx += 1
            }
        } else {
            func_params.Push(func_fields[idx].Text)
            if arg == 2 && func_fields[idx].Value == 3 {
                additional_field := true
            }
            idx += 1
        }
    }
    if additional_field {
        func_params.Push(func_fields[-1].Text)
    }

    PasteToInput(is_up)
    FuncFormClose()
}


FuncFormClose(*) {
    global func_form

    func_form.Destroy()
    func_form := false
}


WriteValue(is_hold, *) {
    vals := Map()
    for name in [
        "LayersDDL", "TypeDDL", "ValInp", "UpTypeDDL", "UpValInp", "CustomLP", "CustomNK",
        "Shortname", "ColorInp", "ColorInpEdges", "ColorInpCorners",
        "GradLenInp", "GradLenInpEdges", "GradLenInpCorners",
    ] {
        vals[name] := false
        try vals[name] := form[name].Text
    }
    for name in [
        "CBIrrevocable", "CBInstant", "ChildBehaviorDDL", "LiveHint",
        "GradCycle", "GradCycleEdges", "GradCycleCorners",
    ] {
        vals[name] := false
        try vals[name] := form[name].Value
    }
    vals["TypeDDL"] := vals["TypeDDL"] || "Modifier"
    vals["LiveHint"] := vals["LiveHint"] == 1 ? "" : vals["LiveHint"]

    if !StrLen(vals["ValInp"]) && vals["TypeDDL"] !== "Default" && vals["TypeDDL"] !== "Disabled" {
        MsgBox("Write any value. For empty behavior use the 'Disabled' type.",
            "Wrong value", "Icon!")
        return
    }
    if vals["TypeDDL"] == "Modifier" {
        try {
            int := Integer(form["ValInp"].Text)
            if 0 > int || int > 60 {
                throw
            }
        } catch {
            MsgBox("The modifier value must be a number up to 60.", "Wrong value", "Icon!")
            return
        }
    }
    layers := GetLayerList()
    gest_opts := ""
    for name in [
        "LiveHint", "ColorInp", "GradLenInp", "GradCycle",
        "ColorInpEdges", "GradLenInpEdges", "GradCycleEdges",
        "ColorInpCorners", "GradLenInpCorners", "GradCycleCorners",
    ] {
        gest_opts .= (vals[name] || "") . ";"
    }
    SaveValue(
        is_hold,
        (layer_editing ? selected_layer : (layers.Length == 1 ? layers[1] : vals["LayersDDL"])),
        TYPES.%vals["TypeDDL"]%, vals["ValInp"],
        TYPES.%vals["UpTypeDDL"] || "Disabled"%, vals["UpValInp"],
        vals["CBInstant"], vals["CBIrrevocable"],
        (vals["CustomLP"] != CONF.MS_LP ? vals["CustomLP"] : false),
        (vals["CustomNK"] != CONF.MS_NK ? vals["CustomNK"] : false),
        vals["ChildBehaviorDDL"], vals["Shortname"],
        RTrim(gest_opts, ";")
    )
    CloseForm()
}


CloseForm(*) {
    global form, func_form, init_drawing

    try form.Destroy()
    try func_form.Destroy()
    form := false
    func_form := false
    init_drawing := false
}