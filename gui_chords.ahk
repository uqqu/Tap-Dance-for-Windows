LVChordClick(lv, row) {
    global selected_chord
    if start_temp_chord {
        return
    }

    if lv.GetText(row, 1) != "Chord" {
        selected_chord := lv.GetText(row, 5)
        ToggleDisabled(["BtnDeleteSelectedChord", "BtnChangeSelectedChord"])
    } else {
        selected_chord := 0
        ToggleDisabled(["BtnDeleteSelectedChord", "BtnChangeSelectedChord"], 1)
    }
}


LVChordDoubleClick(lv, row, from_selected:=false) {
    global current_map, current_base, current_hold

    res := _WalkPath(current_map, [lv.GetText(row, 5), cur_mod, true])
    current_map := res[1]
    current_base := res[2]
    current_hold := res[3]

    current_path.Push([lv.GetText(row, 5), cur_mod, lv.GetText(row, 1) ? lv.GetText(row, 1) : true])
    UpdateKeys()
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
        "The chord has been changed. Do you really want to undo the changes?","Confirmation", "YesNo Icon?"
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
        keyboard_gui.Title := "Adding a new chord"
        selected_chord := 0
    } else {
        keyboard_gui.Title := "Editing a chord"
        for sc in HexToScancodes(selected_chord) {
            temp_chord[sc] := true
            start_temp_chord[sc] := true
        }
    }

    for name in ["BtnCancelChordEditing", "BtnDiscardChordEditing", "BtnSaveEditedChord"] {
        keyboard_gui[name].Visible := true
    }
    for name in ["BtnAddNewChord", "BtnChangeSelectedChord", "BtnDeleteSelectedChord"] {
        keyboard_gui[name].Visible := false
    }
    UpdateKeys()
}


DeleteSelectedChord(_, without_confirmation:=false) {
    global selected_chord, gui_keys
    if !without_confirmation && MsgBox(
        "Do you really want to delete that chord?", "Confirmation", "YesNo Icon?"
    ) == "No" {
        return
    }

    layers := _GetNames(_WalkPath(current_map, [selected_chord, cur_mod, true])[2])
    if layers.Length > 1 {
    	n_layers := []
    	for idx in ChooseLayers(layers) {
    		n_layers.Push(layers[idx])
    	}
    	layers := n_layers
    }

    for layer in layers {
	    current_temp_keys := DeserializeMap(layer)
	    if !current_temp_keys.Has(gui_lang) {
	        current_temp_keys[gui_lang] := Map()
	    }
	    res := _WalkPath(current_temp_keys[gui_lang], current_path, false)
        if res[1][-1][selected_chord].Count == 2 {
            res[1][-1].Delete(selected_chord)
            if res[1][-1].Count {
                bufs := []
                for buf, mods in res[1][-1] {
                    if mods.Has(cur_mod) {
                        bufs.Push(BufferFromHex(buf))
                    }
                }
                main_buf := BufferFromHex(selected_chord)
                RemoveBits(main_buf, bufs)
                scancodes := BufferToScancodes(main_buf)
            } else {
                scancodes := HexToScancodes(selected_chord)
            }
            for sc in scancodes {
                _SetTypeVal(_WalkPath(res[1], [sc, cur_mod, false], false)[3], 0, "")
            }
        } else {
	       res[1][-1][selected_chord].Delete(cur_mod)
           res[1][-1][selected_chord].Delete(cur_mod + 1)
        }
	    SerializeMap(current_temp_keys, layer)
    }
    selected_chord := 0
    ReadLayers()

    if !layer_editing {
        gui_keys := DeepCopy(LANG_KEYS[gui_lang])
    } else {
        gui_keys := Map()
        _DeepMergePreserveVariants(gui_keys, DeserializeMap(selected_layer)[gui_lang], selected_layer)
    }
    ChangePath(current_path.Length)
}


CancelChordEditing(_, without_confirmation:=false) {
    global temp_chord, start_temp_chord
    
    if !without_confirmation && !_CheckUnsavedChord() {
        return
    }

    temp_chord := 0
    start_temp_chord := 0

    for name in ["BtnCancelChordEditing", "BtnDiscardChordEditing", "BtnSaveEditedChord"] {
        keyboard_gui[name].Visible := false
    }
    for name in ["BtnAddNewChord", "BtnChangeSelectedChord", "BtnDeleteSelectedChord"] {
        keyboard_gui[name].Visible := true
    }
    keyboard_gui.Title := "TapDance for Windows"

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
    OpenForm(2)
}


WriteChord(*) {
    global form, gui_keys

    temp_buf := Buffer(BUFFER_SIZE, 0)
    for sc, _ in temp_chord {
        SetBit(sc, temp_buf)
    }

    hex := BufferToHex(temp_buf)

    temp_layer := layer_editing ? selected_layer
        : (ACTIVE_LAYERS.Length ? ACTIVE_LAYERS : ALL_LAYERS)[form["LayersDDL"].Value]
    current_temp_keys := DeserializeMap(temp_layer)
    if !current_temp_keys.Has(gui_lang) {
        current_temp_keys[gui_lang] := Map()
    }
    res := _WalkPath(current_temp_keys[gui_lang], current_path, false)
    if !res[1].Has(-1) || !res[1][-1].Has(hex) || !res[1][-1][hex].Has(cur_mod) || MsgBox(
            "Chord with these keys already exists. Do you want to overwrite it?", "Confirmation", "YesNo Icon?"
        ) != "No" {
	    for sc, _ in temp_chord {
	    	_SetTypeVal(_WalkPath(res[1], [sc, cur_mod, false], false)[3], 5, "")
	    }

	    res := _WalkPath(res[1], [hex, cur_mod, true], false)
	    _SetTypeVal(res[2], form["DDL"].Value, form["Input"].Text)

	    SerializeMap(current_temp_keys, temp_layer)

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

        if selected_chord != "" && !equal {
            DeleteSelectedChord(0, true)
        } else {
            ReadLayers()
            if !layer_editing {
                gui_keys := DeepCopy(LANG_KEYS[gui_lang])
            } else {
                gui_keys := Map()
                _DeepMergePreserveVariants(gui_keys, current_temp_keys[gui_lang], temp_layer)
            }
        }
        CancelChordEditing(0, true)
        ChangePath(current_path.Length)
    }

    form.Destroy()
    form := 0
}