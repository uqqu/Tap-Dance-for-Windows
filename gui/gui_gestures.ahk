LVGestureClick(lv, row) {
    global selected_gesture

    ToggleEnabled(0, UI.layer_move_btns, UI.layer_ctrl_btns)

    if lv.GetText(row, 1) !== "Gesture name" {
        selected_gesture := lv.GetText(row, 5)
        ToggleEnabled(1, UI.gest_toggles)
    } else {
        selected_gesture := ""
        ToggleEnabled(0, UI.gest_toggles)
    }
}


LVGestureDoubleClick(lv, row, from_selected:=false) {
    if lv.GetText(row, 1) !== "Gesture name" {
        OneNodeDeeper(lv.GetText(row, 5), gui_mod_val, false, true)
    }
}


AddNewGesture(*) {
    global selected_gesture

    ToggleEnabled(0, UI.gest_toggles)
    selected_gesture := false
    OpenForm(3)
}


ShowSelectedGesture(*) {
    DrawExisting(selected_gesture)
}


ChangeSelectedGesture(*) {
    if !selected_gesture {
        return
    }
    OpenForm(3)
}


DeleteSelectedGesture(*) {
    global selected_gesture

    if MsgBox("Do you really want to delete this gesture?",
        "Confirmation", "YesNo Icon?") == "No" {
        return
    }

    gest_layer := ""
    checked_layers := layer_editing ? [selected_layer] : ActiveLayers.order
    ubase := gui_entries.ubase.GetBaseHoldMod(selected_gesture, gui_mod_val, false, true).ubase
    child_node := _GetFirst(ubase)
    for layer in checked_layers {
        if _EqualNodes(child_node, _GetFirst(ubase, layer)) {
            gest_layer := layer
            break
        }
    }

    json_root := DeserializeMap(gest_layer)
    res := current_path.Length ? _WalkJson(json_root[gui_lang], current_path) : json_root[gui_lang]
    json_gestures := res[-2]
    if json_gestures[selected_gesture].Count !== 1 {
        json_gestures[selected_gesture].Delete(gui_mod_val)
    } else {
        json_gestures.Delete(selected_gesture)
    }

    SerializeMap(json_root, gest_layer)
    selected_gesture := ""
    ReadLayers()
    FillRoots()
    UpdLayers()
    ChangePath()
}