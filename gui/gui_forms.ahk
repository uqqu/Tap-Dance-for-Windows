form := false
func_form := false


OpenForm(save_type, *) {
    ; 0 – base value, 1 – hold value, 2 – chord
    global form

    try form.Destroy()

    form := Gui(, "Set value")
    form.OnEvent("Close", CloseForm)
    form.OnEvent("Escape", CloseForm)

    unode := save_type == 1 ? gui_entries.uhold : save_type == 2
        ? gui_entries.ubase.GetBaseHoldMod(selected_chord, gui_mod_val, true).ubase
        : gui_entries.ubase

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

    display_type := save_type == 0 && current_path.Length && current_path[-1][3] ? 2 : save_type
    if layers.Length > 1 {
        form.Add("DropDownList", "x10 y+10 w320 vLayersDDL Choose1", layers)
        form["LayersDDL"].OnEvent(
            "Change", ChangeFormPlaceholder.Bind(save_type, (display_type == 2 ? 0 : 2), 1)
        )
        try form["LayersDDL"].Text := prior_layer
    }

    if current_path.Length && SYS_MODIFIERS.Has(current_path[-1][1]) {  ; mod
        form.Title := "Set modifier value"
        form.Add("Edit", "y+10 w300 vInput")
        form.Add("Edit", "y+10 w300 vShortname")
        form.Add("Button", "x10 y+10 h20 w160 vCancel", "❌ Cancel")
        form.Add("Button", "x170 yp+0 h20 w160 Default vSave", "✔ Save")
        form["Cancel"].OnEvent("Click", CloseForm)
        form["Save"].OnEvent("Click", WriteValue.Bind(save_type))

        SendMessage(0x1501, true, StrPtr("Modifier number"), form["Input"].Hwnd)
        SendMessage(0x1501, true, StrPtr("GUI shortname"), form["Shortname"].Hwnd)

        form.Show("w340")
        ChangeFormPlaceholder(1)
        form["Input"].Focus()
        return
    }

    ddl_list := [
        ["Disabled", "Default", "Text", "KeySimulation", "Function"],
        ["Disabled", "Default", "Text", "KeySimulation", "Function", "Modifier"],
        ["Disabled", "Text", "KeySimulation", "Function"]
    ][display_type == 1 && current_path[-1][2] ? 1 : display_type + 1]

    form.Add("DropDownList", "x10 y+10 w320 vDDL", ddl_list)
    form.Add("Edit", "y+10 w320 vInput")

    form.Add("CheckBox", "x10 y+10 w160 vCBInstant", "Instant")

    if display_type !== 2 {
        form.Add("Edit", "x170 yp-3 w160 vCustomLP +Center", CONF.MS_LP).Visible := false
        SendMessage(0x1501, true, StrPtr("Your custom lp value (in ms)"), form["CustomLP"].Hwnd)
        form.Add("Button", "x170 yp+0 w160 vBtnLP", "Custom hold waiting")
            .OnEvent("Click", ShowCustomLP)
    }

    form.Add("CheckBox", "x10 y+5 w160 vCBIrrevocable", "Irrevocable")

    form.Add("Edit", "x170 yp-3 w160 vCustomNK +Center", CONF.MS_NK).Visible := false
    SendMessage(0x1501, true, StrPtr("Your custom nk value (in ms)"), form["CustomNK"].Hwnd)
    form.Add("Button", "x170 yp+0 w160 vBtnNK", "Custom next key waiting")
        .OnEvent("Click", ShowCustomNK)

    if !current_path.Length || current_path.Length == 1 && !current_path[-1][3] {
        form["CBIrrevocable"].Value := false
        form["CBIrrevocable"].Opt("+Disabled")
    } else if current_path[-1][2] & ~1 {
        form["CBIrrevocable"].Value := true
    }
    curr_val := prior_layer ? unode.layers[prior_layer][0] : false
    if display_type !== 2 {
        form.Add("Button", "x10 y+20 w320 vUpToggle", "+Additional up action")
        form.Add("DropDownList", "x10 y+10 w320 vUpDDL", ddl_list).Visible := false
        form.Add("Edit", "x10 y+10 w320 vUpInput").Visible := false
        form["UpDDL"].OnEvent("Change", ChangeFormPlaceholder.Bind(save_type, 1, 0))
        form["UpDDL"].Text := curr_val ? TYPES_R[curr_val.up_type] : "Disabled"
        form["UpToggle"].OnEvent("Click", ShowHideUpVals)
        if curr_val && curr_val.up_type !== TYPES.Disabled {
            ShowHideUpVals()
        }
    }
    form.Add("Edit", "x10 y+10 w300 vShortname")
    SendMessage(0x1501, true, StrPtr("GUI shortname"), form["Shortname"].Hwnd)

    form.Add("Button", "x10 y+10 h20 w160 vCancel", "❌ Cancel").OnEvent("Click", CloseForm)
    form.Add("Button", "x170 yp+0 h20 w160 Default vSave", "✔ Save")
        .OnEvent("Click", (save_type == 2 ? WriteChord : WriteValue.Bind(save_type)))

    form["DDL"].OnEvent("Change", ChangeFormPlaceholder.Bind(save_type, 0, 0))
    form["DDL"].Text := curr_val ? TYPES_R[curr_val.down_type] : "Text"
    form.Show("w340")
    ChangeFormPlaceholder(save_type, (display_type == 2 ? 0 : 2))
}


ShowCustomLP(btn, *) {
    btn.Visible := false
    form["CustomLP"].Visible := true
}


ShowCustomNK(btn, *) {
    btn.Visible := false
    form["CustomNK"].Visible := true
}


ShowHideUpVals(*) {
    b := form["UpDDL"].Visible
    form["UpToggle"].Text := (b ? "+" : "-") . "Additional up action"
    form["UpDDL"].Visible := !b
    form["UpInput"].Visible := !b
}


ChangeFormPlaceholder(save_type:=0, is_up:=0, is_layer_editing:=0, *) {
    static placeholders := [
        "Disabled",
        "Default key value",
        "Value (just raw text)",
        "Key simulation in ahk syntax like '+{SC010}', '{Volume_up}'",
        "Function name",
        "Modifier number"
    ]

    is_ddl := false
    is_layers := false
    try is_ddl := form["DDL"]
    try is_layers := form["LayersDDL"]

    unode := save_type == 1 ? gui_entries.uhold : save_type == 2
        ? gui_entries.ubase.GetBaseHoldMod(selected_chord, gui_mod_val, true).ubase
        : gui_entries.ubase
    layer := is_layers ? form["LayersDDL"].Text : selected_layer

    if !is_ddl {  ; sysmod
        if layer {
            form["Input"].Text := ""
            form["Shortname"].Text := ""
            try form["Input"].Text := unode.layers[layer][0].down_val
            try form["Shortname"].Text := unode.layers[layer][0].gui_shortname
            form["Input"].Focus()
        }
        return
    }

    inp := is_up ? form["UpInput"] : form["Input"]
    ddl_field := is_up ? form["UpDDL"] : form["DDL"]
    curr_type := ddl_field.Text

    SendMessage(0x1501, true, StrPtr(placeholders[TYPES.%curr_type%]), inp.Hwnd)

    if unode && unode.layers.Length && unode.layers.Has(layer) && unode.layers[layer][0] {
        val := unode.layers[layer][0]
        irrevoc := val.is_irrevocable
        instant := val.is_instant
        gui_name := val.gui_shortname
        lp := val.custom_lp_time
        nk := val.custom_nk_time

        if is_layer_editing {
            curr_type := TYPES_R[(is_up ? val.up_type : val.down_type)]
            form["DDL"].Text := curr_type
        }
        if TYPES.%curr_type% == (is_up ? val.up_type : val.down_type) {
            inp.Text := is_up ? val.up_val : val.down_val
        }

        title := "Existing value on layer '" . layer . "'"
    }

    form.Title := title ?? "New value for layer '" . layer . "'"
    if save_type !== 2 {
        form["CustomLP"].Text := lp ?? 0
        form["BtnLP"].Visible := !(lp ?? 1)
        form["CustomLP"].Visible := lp ?? 0
    }
    form["CustomNK"].Text := nk ?? 0
    form["BtnNK"].Visible := !(nk ?? 1)
    form["CustomNK"].Visible := nk ?? 0
    form["CBIrrevocable"].Value := irrevoc ?? 0
    form["CBInstant"].Value := instant ?? 0
    form["Shortname"].Text := gui_name ?? ""

    curr_type == "Function" ? SetUpFunction(is_up) : inp.Focus()
    if curr_type == "Default" || curr_type == "Disabled" {
        inp.Text := ""
        inp.Opt("+Disabled")
    } else {
        inp.Opt("-Disabled")
    }

    if is_up && curr_type !== "Disabled" && !form["UpDDL"].Visible {
        ShowHideUpVals()
    }

    if is_up == 2 {
        ChangeFormPlaceholder(save_type, 0, is_layer_editing)
    }
}


SetUpFunction(is_up) {
    global func_form, func_fields, func_params

    if func_form {
        return
    }
    func_form := Gui(, "Function Selector (" . (is_up ? "up" : "down") . ")")

    func_form.Add("Button", "x10 y10 w160 h19 vBtnPrev", "-")
        .OnEvent("Click", PrevFields.Bind(is_up))
    func_form.Add("Button", "x170 yp+0 w160 h19 vBtnNext", "+")
        .OnEvent("Click", NextFields.Bind(is_up))

    func_form.Add("DropDownList", "x10 y40 w240 vFuncDDL Choose1", custom_func_keys)
        .OnEvent("Change", ChangeFields)

    func_fields := []
    func_params := []

    func_form.Add("Button", "x250 yp+0 w80 h19 vSave", "✔ Assign")
        .OnEvent("Click", SaveAssignedFunction.Bind(is_up))
    func_form.Add("Text", "x10 y+10 w320 h42 vDescription +0x1000", "")
    WinGetPos(&x, &y, &w, &h, "ahk_id " . form.Hwnd)
    try _FillFuncFields(is_up ? form["UpInput"].Text : form["Input"].Text)
    func_form.Show("w340 h" . 291 + (layer_editing ? 0 : 28) . " x" . x + w . " y" . y)
    RefreshFields()
}


ChangeFields(*) {
    global func_params

    func_params := []
    RefreshFields()
}


_FillFuncFields(func_str) {
    if !func_str {
        return
    }
    if !RegExMatch(func_str, "^(?<name>\w+)(?:\((?<args>.*)\))?$", &m) {
        throw Error("Wrong function: " . func_str)
    }
    try {
        func_form["FuncDDL"].Text := m["name"]
        args := _ParseFuncArgs(m["args"])
    }
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

    func_name := func_form["FuncDDL"].Text
    args := custom_funcs[func_name]

    for elem in func_fields {
        elem.Visible := false
    }
    func_fields := []

    func_form["BtnPrev"].Visible := false
    func_form["BtnNext"].Visible := false

    y := 130

    for i, arg in args {
        if i == 1 {
            func_form["Description"].Text := arg
            continue
        }
        if arg is Array {
            for elem in arg {
                func_fields.Push(func_form.Add("Edit", "w320 x10 y" . y))
                SendMessage(0x1501, true, StrPtr(elem), func_fields[-1].Hwnd)
                y += 30
            }
            func_form["BtnPrev"].Visible := true
            func_form["BtnNext"].Visible := true
        } else if arg is Integer {
            func_fields.Push(
                func_form.Add("DDL", "w320 x10 y" . y . " Choose1", custom_func_ddls[arg])
            )
            y += 30
        } else {
            func_fields.Push(func_form.Add("Edit", "w320 x10 y" . y))
            SendMessage(0x1501, true, StrPtr(arg), func_fields[-1].Hwnd)
            y += 30
        }
    }
    func_form["BtnPrev"].Opt((func_params.Length ? "-" : "+") . "Disabled")
    func_form.Show()
}


PasteToInput(is_up:=false) {
    global func_form

    form[is_up ? "UpDDL" : "DDL"].Text := "Function"
    inp := form[is_up ? "UpInput" : "Input"]
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
        str_val := SubStr(str_val, 1, -2) . ")"
        inp.Text := func_form["FuncDDL"].Text . (str_val !== "()" ? str_val : "")
    }
}


SaveAssignedFunction(is_up:=false, *) {
    global func_params, func_form

    func_name := func_form["FuncDDL"].Text
    args := custom_funcs[func_name]

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
            idx += 1
        }
    }

    PasteToInput(is_up)

    func_form.Destroy()
    func_form := false
}


WriteValue(is_hold, *) {
    vals := Map()
    names := ["LayersDDL", "DDL", "Input", "UpDDL", "UpInput", "CustomLP", "CustomNK", "Shortname"]
    for name in names {
        vals[name] := false
        try vals[name] := form[name].Text
    }
    vals["DDL"] := vals["DDL"] || "Modifier"
    vals["CBIrrevocable"] := false
    vals["CBInstant"] := false
    try vals["CBIrrevocable"] := form["CBIrrevocable"].Value
    try vals["CBInstant"] := form["CBInstant"].Value


    if !StrLen(vals["Input"]) && vals["DDL"] !== "Default" && vals["DDL"] !== "Disabled" {
        MsgBox("Write any value. For empty behavior use 'Disabled' option.", "Wrong value")
        return
    }
    if vals["DDL"] == "Modifier" {
        try {
            int := Integer(form["Input"].Text)
            if 0 > int || int > 60 {
                throw
            }
        } catch {
            MsgBox("The modifier value must be a number up to 60.", "Wrong value")
            return
        }
    }
    layers := GetLayerList()
    SaveValue(
        is_hold,
        (layer_editing ? selected_layer : (layers.Length == 1 ? layers[1] : vals["LayersDDL"])),
        TYPES.%vals["DDL"]%, vals["Input"],
        TYPES.%vals["UpDDL"] || "Disabled"%, vals["UpInput"],
        vals["CBInstant"], vals["CBIrrevocable"],
        (vals["CustomLP"] != CONF.MS_LP ? vals["CustomLP"] : false),
        (vals["CustomNK"] != CONF.MS_NK ? vals["CustomNK"] : false),
        vals["Shortname"]
    )
    CloseForm()
}


CloseForm(*) {
    global form, func_form

    try form.Destroy()
    try func_form.Destroy()
    form := false
    func_form := false
}