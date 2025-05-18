LVLayerClick(lv, row) {
    global selected_layer, selected_layer_priority

    ToggleEnabled(0, UI.chs_toggles)
    if layer_editing {
        return
    }

    selected_layer_priority := 0
    if lv.GetText(row, 1) !== "?" {
        selected_layer := lv.GetText(row, 3)
        ToggleEnabled(1, UI.layer_ctrl_btns)
        if lv.GetText(row, 2) {
            selected_layer_priority := lv.GetText(row, 2)
            ToggleEnabled(1, UI.layer_move_btns)
        } else {
            ToggleEnabled(0, UI.layer_move_btns)
        }
    } else {
        selected_layer := ""
        ToggleEnabled(0, UI.layer_move_btns, UI.layer_ctrl_btns)
    }
}


LVLayerDoubleClick(lv, row, from_selected:=false) {
    global layer_editing, root_text, selected_layer

    layer_editing := true
    if !from_selected {
        selected_layer := lv.GetText(row, 3)
    }
    root_text := selected_layer

    ToggleVisibility(1, UI["BtnBackToRoot"])
    ToggleVisibility(0, UI.layer_move_btns, UI.layer_ctrl_btns, UI["BtnAddNewLayer"])

    if AllLayers.map[selected_layer] is Integer {
        _MergeLayer(selected_layer)
    }

    ChangePath()
}


LVLayerCheck(lv, row, is_checked) {
    if layer_editing {
        lv.Modify(row, is_checked ? "-Check" : "+Check")
        return false
    }

    layer_name := lv.GetText(row, 3)

    if is_checked {
        ActiveLayers.Add(layer_name)
        if AllLayers.map[layer_name] is Integer {
            _MergeLayer(layer_name)
        }
    } else {
        ActiveLayers.Remove(layer_name)
        for i, name in ActiveLayers.order {
            ActiveLayers.map[name] := i
        }
    }

    _WriteActiveLayersToConfig()
}


_WriteActiveLayersToConfig() {
    str_value := ""
    for layer in ActiveLayers.order {
        str_value .= layer . ","
    }

    IniWrite(SubStr(str_value, 1, -1), "config.ini", "Main", "ActiveLayers")
    UpdLayers()
    ChangePath()
}


AddNewLayer(*) {
    name := "new layer"
    if FileExist("layers/new layer.json") {
        i := 2
        while FileExist("layers/new layer (" . i . ").json") {
            i++
        }
        name := "new layer (" . i . ")"
    }
    SerializeMap(Map(), name)
    AllLayers.Add(name, Map())
    UpdLayers()
    UpdateKeys()
}


ViewSelectedLayer(*) {
    LVLayerDoubleClick(UI["LV_layers"], 0, true)
}


RenameSelectedLayer(*) {
    inp := InputBox("", "Renaming layer '" . selected_layer . "'", "w250 h100", selected_layer)
    if inp.Result == "Cancel" {
        return
    }

    new_filepath := "layers/" . inp.Value . ".json"
    if FileExist(new_filepath) && MsgBox(
        "File with this name already exists. Do you want to overwrite it?",
        "Confirmation", "YesNo Icon?"
    ) == "No" {
        RenameSelectedLayer()
        return
    }
    FileMove("layers/" . selected_layer . ".json", new_filepath, true)
    if ActiveLayers.Has(selected_layer) {
        p := ActiveLayers.Get(selected_layer)
        ActiveLayers.Add(inp.Value, , p)
        ActiveLayers.Remove(selected_layer)
		_WriteActiveLayersToConfig()
		return
    }
    ReadLayers()
    FillRoots()
    UpdLayers()
	_FillLayers()
}


DeleteSelectedLayer(*) {
    global selected_layer_priority, selected_layer

    if MsgBox("Do you really want to delete that layer?", "Confirmation", "YesNo Icon?") == "No" {
        return
    }

    FileDelete("layers/" . selected_layer . ".json")
    AllLayers.Remove(selected_layer)
    if selected_layer_priority {
        ActiveLayers.Remove(selected_layer)
        _WriteActiveLayersToConfig()
        selected_layer_priority := 0
    }
    if !AllLayers.Length {
        AddNewLayer()
    }
    selected_layer := ""
    UpdateKeys()
}


MoveUpSelectedLayer(*) {
    _MoveSelectedLayer(-1)
}


MoveDownSelectedLayer(*) {
    _MoveSelectedLayer(1)
}


_MoveSelectedLayer(sign) {
    global selected_layer_priority

    prior := selected_layer_priority
    if prior == (sign == -1 ? 1 : ActiveLayers.Length) {
        _FocusLastLayerLV()
        return
    }

    from := ActiveLayers.order[prior]
    to := ActiveLayers.order[prior + 1 * sign]
    ActiveLayers.map[from] := prior + 1 * sign
    ActiveLayers.map[to] := prior
    ActiveLayers.order[prior] := ActiveLayers.order[prior + 1 * sign]
    ActiveLayers.order[prior + 1 * sign] := from
    selected_layer_priority += 1 * sign

    _WriteActiveLayersToConfig()
    _FocusLastLayerLV()
}


_FocusLastLayerLV() {
    lv := UI["LV_layers"]
    lv.Focus()
    loop lv.GetCount() {
        if lv.GetText(A_Index, 2) == selected_layer_priority {
            lv.Modify(A_Index, "Select Focus")
            LVLayerClick(UI["LV_layers"], A_Index)
            return
        }
    }
}


ChooseLayers(layers) {
    selected := []
    layers_form := Gui()
    checkboxes := []

    for i, val in layers {
        checkboxes.Push(layers_form.Add("CheckBox", "vCB" . i, val))
    }

    layers_form.Add("Button", "Default w80", "OK").OnEvent("Click", (*) => layers_form.Submit())
    layers_form.Show()

    WinWaitClose(layers_form.Hwnd)

    for i, cb in checkboxes {
        if cb.Value {
            selected.Push(cb.Text)
        }
    }

    return selected
}


BackToRoot(*) {
    global layer_editing, root_text

    layer_editing := false
    root_text := "root"
    uncat := [UI["BtnBackToRoot"], UI["BtnAddNewLayer"]]
    ToggleVisibility(2, UI.layer_move_btns, UI.layer_ctrl_btns, uncat)

    ChangePath()
}