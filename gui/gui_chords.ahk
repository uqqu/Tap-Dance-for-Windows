LVChordClick(lv, row) {
    global selected_chord

    ToggleEnabled(0, UI.layer_move_btns, UI.layer_ctrl_btns)
    if start_temp_chord {
        return
    }

    if lv.GetText(row, 1) !== "Chord" {
        selected_chord := lv.GetText(row, 5)
        ToggleEnabled(1, UI.chs_toggles)
    } else {
        selected_chord := ""
        ToggleEnabled(0, UI.chs_toggles)
    }
}


LVChordDoubleClick(lv, row, from_selected:=false) {
    if lv.GetText(row, 1) !== "Chord" {
        OneNodeDeeper(lv.GetText(row, 5), gui_mod_val, lv.GetText(row, 1))
    }
}


_CheckUnsavedChord() {
    equal := true
    if temp_chord.Count == start_temp_chord.Count {
        for key, value in temp_chord {
            if !start_temp_chord.Has(key) {
                equal := false
                break
            }
        }
    } else {
        equal := false
    }

    if !equal && MsgBox(
        "The chord has been changed. Do you really want to undo the changes?",
        "Confirmation", "YesNo Icon?"
    ) == "No"{
        return false
    }
    return true
}


AddNewChord(*) {
    ChordEditing(true)
}


ChangeSelectedChord(*) {
    ChordEditing(false)
}


ChordEditing(new:=true) {
    global temp_chord, start_temp_chord, selected_chord

    if start_temp_chord && !_CheckUnsavedChord() {
        return
    }

    temp_chord := Map()
    start_temp_chord := Map()
    if new {
        UI.Title := "Adding a new chord"
        selected_chord := ""
    } else {
        UI.Title := "Editing a chord"
        for sc in HexToScancodes(selected_chord) {
            temp_chord[sc] := true
            start_temp_chord[sc] := true
        }
    }

    ToggleVisibility(2, UI.chs_back, UI.chs_front)
    UpdateKeys()
}


DeleteSelectedChord(_, without_confirmation:=false) {
    global selected_chord

    if !without_confirmation && MsgBox(
        "Do you really want to delete that chord?",
        "Confirmation", "YesNo Icon?"
    ) == "No" {
        return
    }

    layers := []
    checked_layers := layer_editing ? [selected_layer] : ActiveLayers.GetAll()
    ubase := gui_entries.ubase.GetBaseHoldMod(selected_chord, gui_mod_val, true).ubase
    child_node := _GetFirst(ubase)
    for layer in checked_layers {
        if _EqualNodes(child_node, _GetFirst(ubase, layer)) {
            layers.Push(layer)
        }
    }

    if layers.Length > 1 {
    	selected_layers := []
    	for idx in ChooseLayers(layers) {
    		selected_layers.Push(layers[idx])
    	}
    	layers := selected_layers
    }

    for layer in layers {
	    json_root := DeserializeMap(layer)
        res := current_path.Length ? _WalkJson(json_root[gui_lang], current_path, false)
            : json_root[gui_lang]
        json_scancodes := res[-2]
        json_chords := res[-1]
        if json_chords[selected_chord].Count !== 1 {
            json_chords[selected_chord].Delete(gui_mod_val)
        } else {
            json_chords.Delete(selected_chord)
        }
        if !json_chords.Count {
            scancodes := HexToScancodes(selected_chord)
        } else {
            bufs := []
            for buf, mods in json_chords {
                if mods.Has(gui_mod_val) {
                    bufs.Push(BufferFromHex(buf))
                }
            }
            main_buf := BufferFromHex(selected_chord)
            RemoveBits(main_buf, bufs)
            scancodes := BufferToScancodes(main_buf)
        }

        for sc in scancodes {
            sc_node := json_scancodes[sc][gui_mod_val+1]
            sc_node[1] := TYPES.Disabled
            sc_node[2] := ""
        }
	    SerializeMap(json_root, layer)
    }
    selected_chord := ""
    UpdLayers()
    ChangePath()
}


CancelChordEditing(_, without_confirmation:=false) {
    global temp_chord, start_temp_chord

    if !without_confirmation && !_CheckUnsavedChord() {
        return
    }

    temp_chord := 0
    start_temp_chord := 0

    ToggleVisibility(2, UI.chs_back, UI.chs_front)
    UI.Title := "TapDance for Windows"

    UpdateKeys()
}


DiscardChordEditing(*) {
    global temp_chord

    temp_chord := Map()
    for key, _ in start_temp_chord {
        temp_chord[key] := true
    }

    UpdateKeys()
}


SaveEditedChord(*) {
    if temp_chord.Count < 2 {
        MsgBox("Chord must include at least 2 keys.", "Not enough keys")
        return
    }
    if layer_editing || ActiveLayers.order.Length == 1 {
        layer := layer_editing ? selected_layer : ActiveLayers.order[1]
        temp_buf := Buffer(BUFFER_SIZE, 0)
        for sc, _ in temp_chord {
            SetBit(sc, temp_buf)
        }
        hex := BufferToHex(temp_buf)
        if gui_entries.ubase.chords.Has(hex) && gui_entries.ubase.chords[hex].Has(gui_mod_val)
            && gui_entries.ubase.chords[hex][gui_mod_val].layers.Has(layer) && MsgBox(
            "Chord with these keys already exists on this layer. "
            . "Do you want to overwrite it?",
            "Confirmation", "YesNo Icon?"
        ) == "No" {
            return
        }
    }
    OpenForm(2)
}


WriteChord(*) {
    global form

    temp_buf := Buffer(BUFFER_SIZE, 0)
    for sc, _ in temp_chord {
        SetBit(sc, temp_buf)
    }

    hex := BufferToHex(temp_buf)

    layers := GetLayerList()
    temp_layer := layer_editing ? selected_layer
        : (layers.Length == 1 ? layers[1] : form["LayersDDL"].Text)
    json_root := DeserializeMap(temp_layer)
    if !json_root.Has(gui_lang) {
        json_root[gui_lang] := [Map(), Map()]
    }
    res := current_path.Length ? _WalkJson(json_root[gui_lang], current_path, false)
        : json_root[gui_lang]
    json_scancodes := res[-2]
    json_chords := res[-1]
    if json_chords.Has(hex) && json_chords[hex].Has(gui_mod_val) && MsgBox(
            "Chord with these keys already exists on the selected layer. "
            . "Do you want to overwrite it?",
            "Confirmation", "YesNo Icon?"
        ) == "No" {
        return
    }

    for sc, _ in temp_chord {
        if !json_scancodes.Has(sc) {
            json_scancodes[sc] := Map()
        }
        if json_scancodes[sc].Has(gui_mod_val+1) {
            json_scancodes[sc][gui_mod_val+1][1] := TYPES.Chord
            json_scancodes[sc][gui_mod_val+1][2] := ""
        } else {
            json_scancodes[sc][gui_mod_val+1] := [
                TYPES.Chord, "", TYPES.Disabled, "", 0, 0, 0, 0, "", Map(), Map()
            ]
        }
    }

    if !json_chords.Has(hex) {
        json_chords[hex] := Map()
    }
    json_chords[hex][gui_mod_val] := [
        TYPES.%form["DDL"].Text%, form["Input"].Text . "", TYPES.Disabled, "",
        form["CBInstant"].Value, form["CBIrrevocable"].Value,
        hex, gui_mod_val, form["Shortname"].Text, Map(), Map()
    ]

    SerializeMap(json_root, temp_layer)

    equal := true
    if temp_chord && start_temp_chord && temp_chord.Count == start_temp_chord.Count {
        for key, value in temp_chord {
            if !start_temp_chord.Has(key) {
                equal := false
                break
            }
        }
    } else {
        equal := false
    }

    if selected_chord !== "" && !equal {
        DeleteSelectedChord(0, true)
    }
    CancelChordEditing(0, true)

    FillRoots()
    if layer_editing {
         AllLayers.map[selected_layer] := true
        _MergeLayer(selected_layer)
    }
    UpdLayers()
    ChangePath()

    form.Destroy()
    form := false
}