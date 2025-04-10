value_types := ["V", "S", "F", "M", "C"]


DrawLayout() {
    global keyboard_gui

    try {
        keyboard_gui.Destroy()
    }
    keyboard_gui := Gui(, "TapDance for Windows")
    keyboard_gui.OnEvent("Close", CloseEvent)
    keyboard_gui.Add("Edit", "x-999 y-999 w0 h0 vHidden")
    keyboard_gui.path := []
    keyboard_gui.current_values := []
    keyboard_gui.buttons := Map()

    keyboard_gui.SetFont("Italic s7", "Segoe UI")
    keyboard_gui.Add("DropDownList", "vLangs x1150 y195 w50", LANG_NAMES)
    keyboard_gui["Langs"].Text := LANG_NAMES[1]
    keyboard_gui["Langs"].OnEvent("Change", (*) => ChangeLang(keyboard_gui["Langs"].Value))
    keyboard_gui.SetFont("Norm s8")

    keyboard_gui.Add("Text", "vSettings x1485 y320", "🔧")
    keyboard_gui["Settings"].OnEvent("Click", ShowSettings)

    _DrawKeys()
    _DrawLV()
    _DrawHelp()
    _DrawCurrentValues()

    keyboard_gui.SetFont("Norm")
    keyboard_gui.Show("w1755 h335")

    Init()
}


_DrawKeys() {
    static keyboard_layouts := Map(
        "ANSI", [
            [[50, 0x01], [30], [50, 0x3B], [50, 0x3C], [50, 0x3D], [50, 0x3E], [30], [50, 0x3F], [50, 0x40],
             [50, 0x41], [50, 0x42], [30], [50, 0x43], [50, 0x44], [50, 0x57], [50, 0x58], [5], [50, 0x137],
             [50, 0x46], [50, 0x45]],
            [[50, 0x29], [50, 0x02], [50, 0x03], [50, 0x04], [50, 0x05], [50, 0x06], [50, 0x07], [50, 0x08],
             [50, 0x09], [50, 0x0A], [50, 0x0B], [50, 0x0C], [50, 0x0D], [100, 0x0E], [5], [50, 0x152],
             [50, 0x147], [50, 0x149], [5], [50, 0x145], [50, 0x135], [50, 0x37], [50, 0x4A]],
            [[75, 0x0F], [50, 0x10], [50, 0x11], [50, 0x12], [50, 0x13], [50, 0x14], [50, 0x15], [50, 0x16],
             [50, 0x17], [50, 0x18], [50, 0x19], [50, 0x1A], [50, 0x1B], [75, 0x2B], [5], [50, 0x153],
             [50, 0x14F], [50, 0x151], [5], [50, 0x47], [50, 0x48], [50, 0x49], [50, 0x4E]],
            [[90, 0x3A], [50, 0x1E], [50, 0x1F], [50, 0x20], [50, 0x21], [50, 0x22], [50, 0x23], [50, 0x24],
             [50, 0x25], [50, 0x26], [50, 0x27], [50, 0x28], [115, 0x1C], [180], [50, 0x4B], [50, 0x4C], [50, 0x4D]],
            [[120, 0x2A], [50, 0x2C], [50, 0x2D], [50, 0x2E], [50, 0x2F], [50, 0x30], [50, 0x31], [50, 0x32],
             [50, 0x33], [50, 0x34], [50, 0x35], [140, 0x136], [60], [50, 0x148], [60], [50, 0x4F], [50, 0x50],
             [50, 0x51], [50, 0x11C]],
            [[70, 0x1D], [70, 0x15B], [70, 0x38], [325, 0x39], [60, 0x138], [60, 0x15C], [60, 0x15D], [65, 0x11D],
             [5], [50, 0x14B], [50, 0x150], [50, 0x14D], [5], [105, 0x52], [50, 0x53]]
        ],
        "ISO", [
            [[50, 0x01], [30], [50, 0x3B], [50, 0x3C], [50, 0x3D], [50, 0x3E], [30], [50, 0x3F], [50, 0x40],
             [50, 0x41], [50, 0x42], [30], [50, 0x43], [50, 0x44], [50, 0x57], [50, 0x58], [5], [50, 0x137],
             [50, 0x46], [50, 0x45]],
            [[50, 0x29], [50, 0x02], [50, 0x03], [50, 0x04], [50, 0x05], [50, 0x06], [50, 0x07], [50, 0x08],
             [50, 0x09], [50, 0x0A], [50, 0x0B], [50, 0x0C], [50, 0x0D], [100, 0x0E], [5], [50, 0x152],
             [50, 0x147], [50, 0x149], [5], [50, 0x145], [50, 0x135], [50, 0x37], [50, 0x4A]],
            [[75, 0x0F], [50, 0x10], [50, 0x11], [50, 0x12], [50, 0x13], [50, 0x14], [50, 0x15], [50, 0x16],
             [50, 0x17], [50, 0x18], [50, 0x19], [50, 0x1A], [50, 0x1B], [10], [60, 0x1C], [5], [50, 0x153],
             [50, 0x14F], [50, 0x151], [5], [50, 0x47], [50, 0x48], [50, 0x49], [50, 0x4E]],
            [[90, 0x3A], [50, 0x1E], [50, 0x1F], [50, 0x20], [50, 0x21], [50, 0x22], [50, 0x23], [50, 0x24],
             [50, 0x25], [50, 0x26], [50, 0x27], [50, 0x28], [50, 0x2B], [245], [50, 0x4B], [50, 0x4C], [50, 0x4D]],
            [[70, 0x2A], [50, 0x56], [50, 0x2C], [50, 0x2D], [50, 0x2E], [50, 0x2F], [50, 0x30], [50, 0x31],
             [50, 0x32], [50, 0x33], [50, 0x34], [50, 0x35], [135, 0x36], [60], [50, 0x148], [60], [50, 0x4F],
             [50, 0x50], [50, 0x51],[50, 0x11C]],
            [[70, 0x1D], [70, 0x15B], [70, 0x38], [325, 0x39], [60, 0x138], [60, 0x15C], [60, 0x15D],
             [65, 0x11D], [5], [50, 0x14B], [50, 0x150], [50, 0x14D], [5], [105, 0x52], [50, 0x53]]
        ]
    )
    current_layout := IniRead("config.ini", "Main", "LayoutFormat")

    x_offset := 265
    y_offset := 50
    spacing := 5
    height := 40

    for row_idx, row in keyboard_layouts[current_layout] {
        y := y_offset + (row_idx - 1) * (height + spacing)
        x := x_offset

        for _, data in row {
            w := data[1]
            if data.Length > 1 {
                sc := data[2]
                h := (height + (sc == 0x11C || sc == 0x4E || sc == 0x1C && current_layout == "ISO" ? 45 : 0))
                btn := keyboard_gui.Add("Button",
                    "v" . sc . " x" . x . " y" . y . " w" . w . " h" . h . " +BackgroundSilver +0x8000",
                    _GetKeyName(sc)
                )
                keyboard_gui.buttons[sc] := btn
                btn.OnEvent("Click", ButtonLBM.Bind(sc))
                btn.OnEvent("ContextMenu", ButtonRBM.Bind(sc))
            }
            x += w + spacing
        }
    }
}


_DrawLV() {
    ; layers
    keyboard_gui.AddListView("vLV_layers x0 y0 w255 h314 Checked", ["?", "P", "Layer", "Base", "→", "Hold", "→"])
    keyboard_gui["LV_layers"].OnEvent("DoubleClick", LVLayerDoubleClick)
    keyboard_gui["LV_layers"].OnEvent("Click", LVLayerClick)
    keyboard_gui["LV_layers"].OnEvent("ItemCheck", LVLayerCheck)
    for i, w in [18, 18, 75 + (ALL_LAYERS.Length < 18 ? 16 : 0), 40, 21, 40, 21] {
        keyboard_gui["LV_layers"].ModifyCol(i, w)
    }

    keyboard_gui.Add("Button", "vBtnAddNewLayer x0 y314 w43 h20", "✨")
    keyboard_gui.Add("Button", "vBtnViewSelectedLayer xp43 y314 w43 h20", "🔍")
    keyboard_gui.Add("Button", "vBtnRenameSelectedLayer xp43 y314 w43 h20", "✏️")
    keyboard_gui.Add("Button", "vBtnDeleteSelectedLayer xp43 y314 w43 h20", "🗑️")
    keyboard_gui.Add("Button", "vBtnMoveUpSelectedLayer xp43 y314 w41 h20", "🔼")
    keyboard_gui.Add("Button", "vBtnMoveDownSelectedLayer xp41 y314 w42 h20", "🔽")
    keyboard_gui.Add("Button", "vBtnBackToRoot x0 y314 w256 h20", "🔙")

    ; chords
    keyboard_gui.AddListView("vLV_chords x1500 y0 w255 h314", ["Chord", "T", "Value", "Layer", ""])
    keyboard_gui["LV_chords"].OnEvent("DoubleClick", LVChordDoubleClick)
    keyboard_gui["LV_chords"].OnEvent("Click", LVChordClick)
    for i, w in [100, 17, 63, 70, 0] {
        keyboard_gui["LV_chords"].ModifyCol(i, w)
    }

    keyboard_gui.Add("Button", "vBtnAddNewChord x1499 y314 w85 h20", "✨ New")
    keyboard_gui.Add("Button", "vBtnChangeSelectedChord x1584 y314 w85 h20", "✏️ Change")
    keyboard_gui.Add("Button", "vBtnDeleteSelectedChord x1669 y314 w85 h20", "🗑️ Delete")
    keyboard_gui.Add("Button", "vBtnSaveEditedChord x1499 y314 w85 h20", "✔ Save")
    keyboard_gui.Add("Button", "vBtnDiscardChordEditing x1584 y314 w85 h20", "↩ Discard")
    keyboard_gui.Add("Button", "vBtnCancelChordEditing x1669 y314 w85 h20", "❌ Cancel")

    for name in [
        "AddNewLayer", "ViewSelectedLayer", "RenameSelectedLayer", "DeleteSelectedLayer", "MoveUpSelectedLayer",
        "MoveDownSelectedLayer", "BackToRoot", "CancelChordEditing", "DiscardChordEditing", "SaveEditedChord",
        "AddNewChord", "ChangeSelectedChord", "DeleteSelectedChord"
    ] {
        keyboard_gui["Btn" . name].OnEvent("Click", %name%)
    }

    for name in ["BtnSaveEditedChord", "BtnBackToRoot", "BtnCancelChordEditing", "BtnDiscardChordEditing"] {
        keyboard_gui[name].Visible := false
    }
}


_DrawCurrentValues() {
    keyboard_gui.current_values.Push(keyboard_gui.Add("Text", "x1370 y6 w45 vTextBase"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Text", "x1370 y28 w45 vTextHold"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", "x1420 y0 w45 vBtnBase"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", "x1420 y22 w45 vBtnHold"))
    keyboard_gui.SetFont("Norm")
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", "x1465 y0 w20 vBtnBaseClear", "✕"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", "x1465 y22 w20 vBtnHoldClear", "✕"))
    keyboard_gui["BtnBase"].OnEvent("Click", OpenForm.Bind(0))
    keyboard_gui["BtnHold"].OnEvent("Click", OpenForm.Bind(1))
    keyboard_gui["BtnBaseClear"].OnEvent("Click", ClearCurrentValue.Bind(0))
    keyboard_gui["BtnHoldClear"].OnEvent("Click", ClearCurrentValue.Bind(1))

    for elem in keyboard_gui.current_values {
        elem.Visible := false
    }
}


_AddHelpText(font_opt, pos, text) {
    keyboard_gui.SetFont("Norm " . font_opt, "Segoe UI")
    keyboard_gui.Add("Text", pos, text)
}


_DrawHelp() {
    if !IniRead("config.ini", "Main", "HelpTexts") {
        return
    }
    _AddHelpText("Italic c888888", "x265 y317", "Borders (hold behavior): ")
    _AddHelpText("Italic Bold c7777AA", "xp111", "modifier;")
    _AddHelpText("Italic Bold c222222", "xp47", "active modifier;")
    _AddHelpText("Italic Bold cAAAA11", "xp81", "chord part;")
    _AddHelpText("Italic Bold cGreen", "xp57", "child transitions.")

    _AddHelpText("Italic c888888", "xp160", "Font: ")
    _AddHelpText("Italic Underline", "xp25", "base child transitions;")
    _AddHelpText("Bold", "xp100 yp1", "¤")
    _AddHelpText("Italic", "xp8 yp-1", "– dummy symbol for empty values.")

    _AddHelpText("Italic", "xp247",
        "Interaction: LBM – base transition map, RBM – hold transition map/activate modifier."
    )
}


_FillPathline() {
    static dirs := ["▼", "➤", "▲"]
    keyboard_gui.SetFont("Norm", "Segoe UI")
    if current_path.Length {
        prev := keyboard_gui.path[1]
        for i, val in current_path {
            prev.GetPos(&x, &y, &w, &h)
            pref := val[2] > 1 ? String(val[2] - Mod(val[2], 2)) : ""
            dir_text := keyboard_gui.Add("Text", "x" . (x + w) . " yp5",
                pref . (val[3] ? "▼" : ["➤", "▲"][Mod(val[2], 2) + 1])
            )
            prev := keyboard_gui.Add("Button", "x" . (x + w + 12 + 5 * StrLen(pref)) . " yp-5",
                val[3] ? val[3] : _GetKeyName(val[1], 1)
            )
            keyboard_gui.path.Push(dir_text)
            keyboard_gui.path.Push(prev)
            prev.OnEvent("Click", ChangePath.Bind(i))
        }

        ;change base/hold value for current active view path
        for elem in keyboard_gui.current_values {
            elem.Visible := true
        }

        base_type := _GetType(current_base)
        hold_type := _GetType(current_hold)

        keyboard_gui["TextBase"].Opt("-Disabled")
        keyboard_gui["BtnBase"].Opt("-Disabled")
        keyboard_gui["BtnBaseClear"].Opt("-Disabled")
        if base_type {
            keyboard_gui["TextBase"].Text := "Base (" . value_types[base_type] . "):"
            keyboard_gui["BtnBase"].Text := _GetVal(current_base)
        } else {
            keyboard_gui["TextBase"].Text := "Base:"
            keyboard_gui["BtnBase"].Text := ""
        }
        if SYS_MODIFIERS.Has(current_path[current_path.Length][1]) {
            keyboard_gui["TextBase"].Opt("+Disabled")
            keyboard_gui["BtnBase"].Opt("+Disabled")
            keyboard_gui["BtnBaseClear"].Opt("+Disabled")
        }

        keyboard_gui["BtnHold"].Opt("-Disabled")
        keyboard_gui["BtnHoldClear"].Opt("-Disabled")
        if hold_type {
            keyboard_gui["TextHold"].Text := "Hold (" . value_types[hold_type] . "):"
            switch hold_type {
                case 4:
                    keyboard_gui["BtnHold"].Text := "Modifier"
                case 5:
                    keyboard_gui["BtnHold"].Text := "Chord"
                    keyboard_gui["BtnHold"].Opt("+Disabled")
                    keyboard_gui["BtnHoldClear"].Opt("+Disabled")
                default:
                    keyboard_gui["BtnHold"].Text := _GetVal(current_hold)
            }
        } else if current_path[current_path.Length][3] {
            keyboard_gui["BtnHold"].Text := "Chord"
            keyboard_gui["BtnHold"].Opt("+Disabled")
            keyboard_gui["BtnHoldClear"].Opt("+Disabled")
        } else {
            keyboard_gui["TextHold"].Text := "Hold:"
            keyboard_gui["BtnHold"].Text := ""
        }
    } else {
        for elem in keyboard_gui.current_values {
            elem.Visible := false
        }
    }
    keyboard_gui.SetFont("Norm")
}


_FillKeyboard() {
    for sc, btn in keyboard_gui.buttons {
        btn.Opt("-Disabled +BackgroundSilver")
        if temp_chord {
            if current_map.Has(sc) && _GetType(_WalkPath(current_map, [sc, cur_mod, false])[3]) == 4
                || SYS_MODIFIERS.Has(sc) {
                btn.Opt("+Disabled")
            }
            btn.Opt(temp_chord.Has(sc) ? "+BackgroundBBBB22" : "+BackgroundSilver")
            btn.Text := btn.Text
        } else if current_map.Has(sc) {
            res := _WalkPath(current_map, [sc, cur_mod, false])
            key_base := res[2]
            key_hold := res[3]
            btn.SetFont("Norm")
            if _GetMap(key_base).Count {
                btn.SetFont("Underline", "Segoe UI")
            }

            mod_hold := _WalkPath(current_map, [sc, 0, false])[3]
            mh_val := _GetVal(mod_hold)
            if cur_mod && _GetType(mod_hold) == 4 && mh_val && cur_mod & (1 << mh_val) == (1 << mh_val) {
                btn.Opt("+BackgroundBlack")
            } else if _GetType(mod_hold) == 4 {
                btn.Opt("+Background7777AA")
            } else if _GetType(key_hold) == 5 {
                btn.Opt("+BackgroundBBBB22")
            } else if key_hold && _GetMap(key_hold).Count {
                btn.Opt("+BackgroundGreen")
            }

            bv := _GetVal(key_base)
            if _GetType(key_base) == 2 && bv {
                btn.SetFont("Italic", "Segoe UI")
                btn.Text := _GetKeyName(bv)
            } else {
                btn.Text := bv != "" ? (InStr(bv, "{Text}") ? SubStr(bv, 7) : bv) : "¤"
            }

            hv := _GetVal(key_hold)
            if hv {
                btn.Text .= "`n" . (InStr(hv, "{Text}") ? SubStr(hv, 7) : hv)
            }
        } else {
            btn.SetFont("Norm")
            btn.Text := _GetKeyName(sc)
        }
    }
}


_FillLV() {
    ; layers
    keyboard_gui["LV_layers"].Delete()

    temp_all_layers := Map()
    for layer in ALL_LAYERS {
        temp_all_layers[layer] := false
    }

    if layer_editing {
        temp_all_layers[selected_layer] := "*"
    } else {
        for i, layer in ACTIVE_LAYERS {
            temp_all_layers[layer] := i
        }
    }

    res := _WalkPath(ALL_LAYERS_LANG_KEYS[gui_lang], current_path)

    vals := [Map(), Map()]
    for i in [1, 2] {
        if res[i + 1] {
            for opt in res[i + 1] {
                for layer in _GetNames(opt) {
                    vals[i][layer] := [_GetType(opt), _GetVal(opt), _GetMap(opt)]
                }
            }
        }
    }

    for k, v in temp_all_layers {
        txt := ["", ""]
        cnt := ["", ""]
        for i in [1, 2] {
            if vals[i].Has(k) {
                switch vals[i][k][1] {
                    case 1:
                        txt[i] := "'" . vals[i][k][2] . "'"
                    case 2:
                        txt[i] := _GetKeyName(vals[i][k][2], 1)
                    case 3:
                        txt[i] := "(" . vals[i][k][2] . ")"
                    case 4:
                        txt[i] := "{M}"
                    case 5:
                        txt[i] := "{C}"
                }
                if vals[i][k][3] && vals[i][k][3].Count {
                    cnt[i] := vals[i][k][3].Count
                }
            }
        }
        keyboard_gui["LV_layers"].Add(v ? "Check" : "", "", v ? v : "", k, txt[1], cnt[1], txt[2], cnt[2])
    }

    ; chords
    keyboard_gui["LV_chords"].Delete()
    if current_map.Has(-1) {
        for buffer, _ in current_map[-1] {
            val := _WalkPath(current_map, [buffer, cur_mod, true])[2]
            if !_GetType(val) {
                continue
            }
            hl := start_temp_chord && start_temp_chord.Count && buffer == selected_chord ? "👉 " : ""
            layer_text := ""
            for layer in _GetNames(val) {
                layer_text .= " & " . layer
            }
            if layer_text {
                layer_text := SubStr(layer_text, 4)
            }
            keyboard_gui["LV_chords"].Add("",
                hl . SC_ArrToString(HexToScancodes(buffer)),
                value_types[_GetType(val)],
                _GetVal(val),
                layer_text,
                buffer
            )
        }
    }
}


_GetKeyName(sc, to_short:=false) {
    static keyname_type := Integer(IniRead("config.ini", "Main", "KeynameType"))
    static fixed_names := Map("PrintScreen", "Print`nScreen", "ScrollLock", "Scroll`nLock", "Numlock", "Num`nLock")
    static short_names := Map("PrintScreen", "PrtSc", "ScrollLock", "ScrLk", "Numlock", "NumLk",
        "Backspace", "BS", "LControl", "LCtrl", "RControl", "RCtrl", "AppsKey", "Menu")

    if keyname_type != 1 {
        return sc
    }

    res := GetKeyName(SC_STR[sc])
    if to_short && short_names.Has(res) {
        return short_names[res]
    }
    if fixed_names.Has(res) {
        return fixed_names[res]
    }

    return InStr(res, "Numpad") ? "n" . SubStr(res, 7) : res
}