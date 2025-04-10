LVLayerClick(lv, row) {
    global selected_layer, selected_layer_priority

    if layer_editing {
        return
    }

    if lv.GetText(row, 1) != "?" {
        selected_layer := lv.GetText(row, 3)
        ToggleDisabled(["BtnViewSelectedLayer", "BtnRenameSelectedLayer", "BtnDeleteSelectedLayer"])
        if lv.GetText(row, 2) {
            selected_layer_priority := lv.GetText(row, 2)
            ToggleDisabled(["BtnMoveUpSelectedLayer", "BtnMoveDownSelectedLayer"])
        } else {
            selected_layer_priority := 0
            ToggleDisabled(["BtnMoveUpSelectedLayer", "BtnMoveDownSelectedLayer"], 1)
        }
    } else {
        selected_layer := 0
        selected_layer_priority := 0
        ToggleDisabled([
            "BtnViewSelectedLayer", "BtnRenameSelectedLayer", "BtnDeleteSelectedLayer",
            "BtnMoveUpSelectedLayer", "BtnMoveDownSelectedLayer"
        ], 1)
    }
}


LVLayerDoubleClick(lv, row, from_selected:=false) {
    global layer_editing, gui_keys, root_text, selected_layer

    layer_editing := true
    if !from_selected {
        selected_layer := lv.GetText(row, 3)
    }
	gui_keys := Map()
    cur_map := DeserializeMap(selected_layer)
    if cur_map.Has(gui_lang) {
        _DeepMergePreserveVariants(gui_keys, cur_map[gui_lang], selected_layer)
    }
    root_text := selected_layer

    ToggleVisibility(["BtnBackToRoot"], 1)
    ToggleVisibility([
        "BtnAddNewLayer", "BtnViewSelectedLayer", "BtnRenameSelectedLayer",
        "BtnDeleteSelectedLayer", "BtnMoveUpSelectedLayer", "BtnMoveDownSelectedLayer"
    ], 0)

    ChangePath(current_path.Length)
}


LVLayerCheck(lv, row, is_checked) {
    if layer_editing {
        lv.Modify(row, is_checked ? "-Check" : "+Check")
        return false
    }

    layer_name := lv.GetText(row, 3)
    if is_checked {
        ACTIVE_LAYERS.Push(layer_name)
    } else {
        for i, v in ACTIVE_LAYERS {
            if v == layer_name {
                ACTIVE_LAYERS.RemoveAt(i)
                break
            }
        }
    }

    _WriteActiveLayersToConfig()
}


_WriteActiveLayersToConfig() {
    global gui_keys
    str_value := ""
    for layer in ACTIVE_LAYERS {
        str_value .= layer . ","
    }

    IniWrite(SubStr(str_value, 1, -1), "config.ini", "Main", "ActiveLayers")
    ReadLayers()
    gui_keys := DeepCopy(LANG_KEYS[gui_lang])
    ChangePath(current_path.Length)
}


AddNewLayer(*) {
    if FileExist("layers/new layer.json") {
        i := 2
        while FileExist("layers/new layer (" . i . ").json") {
            i++
        }
        SerializeMap(Map(), "new layer (" . i . ")")
    } else {
        SerializeMap(Map(), "new layer")
    }
    ReadLayers()
    gui_keys := DeepCopy(LANG_KEYS[gui_lang])
    UpdateKeys()
}


ViewSelectedLayer(*) {
    LVLayerDoubleClick(keyboard_gui["LV_layers"], 0, true)
}


RenameSelectedLayer(*) {
    input := InputBox("", "Renaming layer '" . selected_layer . "'", "w250 h100", selected_layer)
    if input.Result != "Cancel" {
        new_filepath := "layers/" . input.Value . ".json"
        if FileExist(new_filepath) {
            if MsgBox(
                "File with this name already exists. Do you want to overwrite it?", "Confirmation", "YesNo Icon?"
            ) == "No" {
                RenameSelectedLayer()
                return
            }
        }
        FileMove("layers/" . selected_layer . ".json", new_filepath, true)
        for i, layer in ACTIVE_LAYERS {
        	if layer == selected_layer {
        		ACTIVE_LAYERS[i] := input.Value
    			_WriteActiveLayersToConfig()
    			return
        	}
        }
        ReadLayers()
    	_FillLV()
    }
}


DeleteSelectedLayer(*) {
    global selected_layer_priority, selected_layer

    if MsgBox("Do you really want to delete that layer?", "Confirmation", "YesNo Icon?") == "No" {
        return
    }

    FileDelete("layers/" . selected_layer . ".json")
    if ALL_LAYERS.Length == 1 {
        AddNewLayer()
    }
    if selected_layer_priority {
        for i, layer in ACTIVE_LAYERS {
            if layer == selected_layer {
                ACTIVE_LAYERS.RemoveAt(i)
                break
            }
        }
        _WriteActiveLayersToConfig()
    } else {
        ReadLayers()
    }
    selected_layer := 0
    selected_layer_priority := 0
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

    if selected_layer_priority == (sign == -1 ? 1 : ACTIVE_LAYERS.Length) {
        _FocusLastLayerLV()
        return
    }

    temp := ACTIVE_LAYERS[selected_layer_priority]
    ACTIVE_LAYERS[selected_layer_priority] := ACTIVE_LAYERS[selected_layer_priority + 1 * sign]
    ACTIVE_LAYERS[selected_layer_priority + 1 * sign] := temp
    selected_layer_priority += 1 * sign

    _WriteActiveLayersToConfig()
    _FocusLastLayerLV()
}


_FocusLastLayerLV() {
    lv := keyboard_gui["LV_layers"]
    lv.Focus()
    loop lv.GetCount() {
        if lv.GetText(A_Index, 2) == selected_layer_priority {
            lv.Modify(A_Index, "Select Focus")
            LVLayerClick(keyboard_gui["LV_layers"], A_Index)
            return
        }
    }
}


ChooseLayers(layers) {
    selected := []
    layers_form := Gui()
    checkboxes := []

    for i, val in layers {
        cb := layers_form.Add("CheckBox", "vCB" . i, val)
        checkboxes.Push(cb)
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
    global layer_editing, gui_keys, root_text
    layer_editing := false
    gui_keys := DeepCopy(LANG_KEYS[gui_lang])
    root_text := "root"
    ToggleVisibility([
        "BtnBackToRoot", "BtnAddNewLayer", "BtnViewSelectedLayer", "BtnRenameSelectedLayer",
        "BtnDeleteSelectedLayer", "BtnMoveUpSelectedLayer", "BtnMoveDownSelectedLayer"
    ], 2)

    ChangePath(current_path.Length)
}