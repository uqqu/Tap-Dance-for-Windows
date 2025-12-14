LVLayerClick(lv, row) {
    global last_selected_layer, selected_layer_priority

    _UnhighlightSelectedChord()
    ToggleEnabled(0, UI.chs_toggles, UI.gest_toggles)

    if _GetColumnAtCursor(lv) == 1 {
        LVLayerCheck(lv, row)
        return
    }

    if layer_editing || _GetRowIconIndex(lv, row) > 1 {
        ToggleEnabled(0, UI.layer_move_btns, UI.layer_ctrl_btns)
        return
    }

    selected_layer_priority := 0
    if row {
        last_selected_layer := ""
        for folder in layer_path {
            last_selected_layer .= folder . "\"
        }
        last_selected_layer .= lv.GetText(row, 3)
        ToggleEnabled(1, UI.layer_ctrl_btns)
        if lv.GetText(row, 2) {
            selected_layer_priority := lv.GetText(row, 2)
            ToggleEnabled(1, UI.layer_move_btns)
        } else {
            ToggleEnabled(0, UI.layer_move_btns)
        }
    } else {
        last_selected_layer := ""
        ToggleEnabled(0, UI.layer_move_btns, UI.layer_ctrl_btns)
    }
}


LVLayerDoubleClick(lv, row, from_selected:=false) {
    global layer_editing, root_text, selected_layer, last_selected_layer, buffer_view, layer_path

    if (!row && !from_selected) || temp_chord {
        return
    }

    i := from_selected || _GetRowIconIndex(lv, row)

    if i == 3 {
        layer_path.Length -= 1
    } else if i == 2 {
        layer_path.Push(lv.GetText(row, 3))
        if layer_path.Length == 1 && layer_path[-1] == "custom layouts" {
            cnt := IniRead("config.ini", "Main", "CustomLayoutWarningsCnt", 0)
            if cnt < 2 {
                MsgBox("It is strongly not recommended to use this program for permanent "
                    . "reassignments at the basic level. But it can be useful for familiarizing "
                    . "yourself with different layouts, or serve as a temporary solution.",
                    "Warning")
            } else if cnt < 4 || cnt == 7 || !Mod(cnt, 10) {
                ToolTip("Do not use for permanent default key reassignments")
                SetTimer(ToolTip, -2222)
            }
            IniWrite(cnt + 1, "config.ini", "Main", "CustomLayoutWarningsCnt")
        }
    } else {
        buffer_view := 0
        layer_editing := true
        if !from_selected {
            last_selected_layer := ""
            for folder in layer_path {
                last_selected_layer .= folder . "\"
            }
            last_selected_layer .= lv.GetText(row, 3)
        }
        selected_layer := last_selected_layer
        root_text := StrSplit(last_selected_layer, "\")[-1]

        ToggleVisibility(1, UI["BtnBackToRoot"])
        ToggleVisibility(0, UI.layer_move_btns, UI.layer_ctrl_btns, UI["BtnAddNewLayer"])

        if AllLayers.map[selected_layer] is Integer {
            _MergeLayer(selected_layer)
        }
    }

    ChangePath(, false)
}


LVLayerCheck(lv, row) {
    i := _GetRowIconIndex(lv, row)
    if i > 1 {
        LVLayerDoubleClick(lv, row)
        return
    } else if layer_editing {
        return false
    }

    layer_name := ""
    for folder in layer_path {
        layer_name .= folder . "\"
    }
    layer_name .= lv.GetText(row, 3)

    if !i {
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


_GetRowIconIndex(lv, row) {
    item := Buffer(64, 0)
    NumPut("uint", 0x0002, item, 0)
    NumPut("int", row - 1, item, 4)
    NumPut("int", 0, item, 8)
    SendMessage(0x104B, 0, item, lv)
    offset := (A_PtrSize = 8) ? 36 : 32
    return NumGet(item, offset, "int")
}


_GetColumnAtCursor(lv, with_row:=false) {
    MouseGetPos(&mx, &my, , &ctrl_hwnd)

    row := 0
    if SubStr(ctrl_hwnd, 1, 9) == "SysHeader" {
        row := -1
    }

    pt := Buffer(8, 0)
    NumPut("int", mx, pt, 0)
    NumPut("int", my, pt, 4)
    DllCall("ScreenToClient", "ptr", lv.Hwnd, "ptr", pt)

    hti := Buffer(48, 0)
    NumPut("int", NumGet(pt, 0, "int"), hti, 0)
    NumPut("int", NumGet(pt, 4, "int"), hti, 4)

    SendMessage(0x1039, 0, hti, lv)

    if with_row {
        row := row || (NumGet(hti, 12, "int") + 1)
        return [NumGet(hti, 16, "int") + 1, row]
    }
    return NumGet(hti, 16, "int") + 1
}


_WriteActiveLayersToConfig() {
    str_value := ""
    for layer in ActiveLayers.order {
        str_value .= layer . ", "
    }

    IniWrite(SubStr(str_value, 1, -2), "config.ini", "Main", "ActiveLayers")
    UpdLayers()
    ChangePath()
}


AddNewLayer(*) {
    name := "new layer"
    layer_str := "layers\"
    for folder in layer_path {
        layer_str .= folder . "\"
    }
    if FileExist(layer_str . "new layer.json") {
        i := 2
        while FileExist(layer_str . "new layer (" . i . ").json") {
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
    inp := InputBox("",
        "Renaming layer '" . last_selected_layer . "'", "w250 h100", last_selected_layer)
    if inp.Result == "Cancel" {
        return
    }

    new_filepath := "layers/" . inp.Value . ".json"
    if FileExist(new_filepath) && MsgBox(
        "File with this name already exists. Do you want to overwrite it?",
        "Confirmation", "YesNo Icon?") == "No" {
        RenameSelectedLayer()
        return
    }
    FileMove("layers/" . last_selected_layer . ".json", new_filepath, true)
    if ActiveLayers.Has(last_selected_layer) {
        p := ActiveLayers[last_selected_layer]
        ActiveLayers.Add(inp.Value, , p)
        ActiveLayers.Remove(last_selected_layer)
		_WriteActiveLayersToConfig()
    }
    ReadLayers()
    FillRoots()
    UpdLayers()
	_FillLayers()
}


DeleteSelectedLayer(*) {
    global selected_layer_priority, last_selected_layer

    if MsgBox("Do you really want to delete that layer?", "Confirmation", "YesNo Icon?") == "No" {
        return
    }

    FileDelete("layers/" . last_selected_layer . ".json")
    AllLayers.Remove(last_selected_layer)
    if selected_layer_priority {
        ActiveLayers.Remove(last_selected_layer)
        _WriteActiveLayersToConfig()
        selected_layer_priority := 0
    }
    if !AllLayers.Length {
        AddNewLayer()
    }
    last_selected_layer := ""
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
    layers_form := Gui("+AlwaysOnTop", "")
    checkboxes := []

    for i, val in layers {
        checkboxes.Push(layers_form.Add("CheckBox", "vCB" . i, val))
    }

    layers_form.Add("Button", "Default w80", "OK").OnEvent("Click", (*) => layers_form.Submit())
    layers_form.Show("w200")

    WinWaitClose(layers_form.Hwnd)

    for i, cb in checkboxes {
        if cb.Value {
            selected.Push(cb.Text)
        }
    }

    return selected
}


BackToRoot(*) {
    global layer_editing, selected_layer, root_text, buffer_view

    if buffer_view {
        buffer_view := 0
    }
    layer_editing := false
    selected_layer := ""
    root_text := "root"
    uncat := [UI["BtnBackToRoot"], UI["BtnAddNewLayer"]]
    ToggleVisibility(2, UI.layer_move_btns, UI.layer_ctrl_btns, uncat)

    ChangePath(, false)
}


ToggleLayersTag(tag, *) {
    if !CONF.tags.Has(tag) || ((tag == "Active" || tag == "Inactive") && !CONF.tags[tag]) {
        CONF.tags[tag] := true
        UI["LayerTag" . tag].Opt("cGreen")
        UI["LayerTag" . tag].Text .= ""
    } else if CONF.tags[tag] {
        CONF.tags[tag] := false
        UI["LayerTag" . tag].Opt("cRed")
        UI["LayerTag" . tag].Text .= ""
    } else {
        CONF.tags.Delete(tag)
        UI["LayerTag" . tag].Opt("cGray")
        UI["LayerTag" . tag].Text .= ""
    }

    str_val := ""
    for chosen_tag, v in CONF.tags {
        if chosen_tag {
            str_val .= (v ? "" : "-") . chosen_tag . ", "
        }
    }
    IniWrite(SubStr(str_val, 1, -2), "config.ini", "Main", "ChosenTags")
    _FillLayers()
}


ExpandTags(*) {
    static expanded:=-1

    UI["LV_layers"].GetPos(&x, &y, &w, &h)
    UI["LV_layers"].Move(
        x, y - (extra_tags_height * expanded), w, h + (extra_tags_height * expanded)
    )
    ToggleVisibility(2, UI.extra_tags)
    expanded *= -1
}