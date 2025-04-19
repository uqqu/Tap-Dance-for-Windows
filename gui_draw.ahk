value_types := ["V", "S", "F", "M", "C"]

USER_DPI := DllCall("user32\GetDpiForSystem", "uint") / 96


Scale(x?, y?, w?, h?) {
    return (IsSet(x) ? " x" . Round(x * CONF["gui_scale"]) : "") . (IsSet(y) ? " y" . Round(y * CONF["gui_scale"]) : "")
        . (IsSet(w) ? " w" . Round(w * CONF["gui_scale"]) : "") . (IsSet(h) ? " h" . Round(h * CONF["gui_scale"]) : "")
}


DrawLayout() {
    global keyboard_gui

    try {
        keyboard_gui.Destroy()
    }

    keyboard_gui := Gui(, "TapDance for Windows")
    keyboard_gui.Opt("-DPIScale")
    keyboard_gui.OnEvent("Close", CloseEvent)
    keyboard_gui.Add("Edit", "x-999 y-999 w0 h0 vHidden")
    keyboard_gui.path := []
    keyboard_gui.current_values := []
    keyboard_gui.buttons := Map()

    keyboard_gui.SetFont("Italic s" . Round(7 * CONF["font_scale"]), "Segoe UI")
    keyboard_gui.Add("DropDownList", "vLangs " . Scale(CONF["wide_mode"] ? 1150 : 895, 195, 50), LANG_NAMES)
    for i, code in LANG_CODES {
        if code == gui_lang {
            keyboard_gui["Langs"].Value := i
        }
    }
    keyboard_gui["Langs"].OnEvent("Change", (*) => ChangeLang(keyboard_gui["Langs"].Value))
    keyboard_gui.SetFont("Norm s" . Round(8 * CONF["font_scale"]))

    keyboard_gui.Add("Text", "vSettings " . Scale(CONF["wide_mode"] ? 1470 : 1215, 317), "🔧")
    keyboard_gui["Settings"].OnEvent("Click", ShowSettings)

    _DrawKeys()
    _DrawLV()
    _DrawHelp()
    _DrawCurrentValues()

    keyboard_gui.SetFont("Norm")
    keyboard_gui.Show(CONF["wide_mode"] ? Scale(,, 1745, 335) : Scale(,, 1240, 675))

    Init()
}


_DrawKeys() {
    global ALL_SCANCODES
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

    ALL_SCANCODES := []
    len := keyboard_layouts[CONF["layout_format"]].Length
    x_offset := CONF["wide_mode"] ? 263 : 10
    y_offset := 50 * CONF["gui_scale"]
    spacing := 5
    height := (314 * CONF["gui_scale"] - (spacing * (len - 1)) - y_offset) / len  ; 314 – LVs height

    for row_idx, row in keyboard_layouts[CONF["layout_format"]] {
        y := y_offset + (row_idx - 1) * (height + spacing)
        x := x_offset * 1.0

        for data in row {
            logical_w := data[1]
            w := logical_w * CONF["gui_scale"]

            if data.Length > 1 {
                sc := data[2]
                ALL_SCANCODES.Push(sc)
                if sc == 0x11D {
                    keyboard_gui[CONF["layout_format"] == "ISO" ? "54" : "310"].GetPos(&shx, , &shw)
                    w := shx + shw - x * CONF["gui_scale"] + 1
                }

                h := height + (sc == 0x11C || sc == 0x4E || sc == 0x1C && CONF["layout_format"] == "ISO"
                    ? height + spacing : 0)

                btn := keyboard_gui.Add("Button",
                    "v" . sc . " x" . x * CONF["gui_scale"] . " y" . y . " w" . w . " h" . h 
                    . " +BackgroundSilver +0x8000",
                    _GetKeyName(sc)
                )
                keyboard_gui.buttons[sc] := btn
                btn.OnEvent("Click", ButtonLBM.Bind(sc))
                btn.OnEvent("ContextMenu", ButtonRBM.Bind(sc))
            }

            x += logical_w + spacing
        }
    }
}


_DrawLV() {
    ; layers
    keyboard_gui.AddListView(
        "vLV_layers " . (CONF["wide_mode"] ? Scale(0, 0, 255, 314) : Scale(10, 340, 610, 314)) . " Checked",
        ["?", "P", "Layer", "Base", "→", "Hold", "→"]
    )
    keyboard_gui["LV_layers"].OnEvent("DoubleClick", LVLayerDoubleClick)
    keyboard_gui["LV_layers"].OnEvent("Click", LVLayerClick)
    keyboard_gui["LV_layers"].OnEvent("ItemCheck", LVLayerCheck)
    cols := CONF["wide_mode"] 
        ? [15, 15, 75, 40, 21, 40, 21]
        : [24, 30, 200, 135, 30, 135, 30]
    for i, w in cols {
        keyboard_gui["LV_layers"].ModifyCol(i, Max(w * CONF["gui_scale"], 16 * USER_DPI))
    }
    btns_wh := "w" . ((CONF["wide_mode"] ? 256 : 610) * CONF["gui_scale"] / 6) . " h" . (20 * CONF["gui_scale"])
    keyboard_gui.Add("Button", "vBtnAddNewLayer xp-1 y+0 " . btns_wh, CONF["wide_mode"] ? "✨" : "✨ New layer")
    keyboard_gui.Add("Button", "vBtnViewSelectedLayer x+0 yp0 " . btns_wh, CONF["wide_mode"] ? "🔍" : "🔍 View")
    keyboard_gui.Add("Button", "vBtnRenameSelectedLayer x+0 yp0 " . btns_wh, CONF["wide_mode"] ? "✏️" : "✏️ Rename")
    keyboard_gui.Add("Button", "vBtnDeleteSelectedLayer x+0 yp0 " . btns_wh, CONF["wide_mode"] ? "🗑️" : "🗑️ Delete")
    keyboard_gui.Add("Button", "vBtnMoveUpSelectedLayer x+0 yp0 " . btns_wh, CONF["wide_mode"] ? "🔼" : "🔼 Move up")
    keyboard_gui.Add("Button", "vBtnMoveDownSelectedLayer x+0 yp0 " . btns_wh, CONF["wide_mode"] ? "🔽" : "🔽 Move down")
    keyboard_gui.Add("Button", "vBtnBackToRoot "
        . (CONF["wide_mode"] ? Scale(0, 314, 256, 20)
        : ("x" . (10 * CONF["gui_scale"]) . " yp0"
            . " w" . (610 * CONF["gui_scale"]) . " h" . (20 * CONF["gui_scale"]))
        ),
        (CONF["wide_mode"] ? "🔙" : "🔙 Back to all active layers")
    )

    ; chords
    keyboard_gui.AddListView(
        "vLV_chords " . (CONF["wide_mode"] ? Scale(1490, 0, 255, 314) : Scale(619, 340, 610, 314)),
        ["Chord", "T", "Value", "Layer", ""]
    )
    keyboard_gui["LV_chords"].OnEvent("DoubleClick", LVChordDoubleClick)
    keyboard_gui["LV_chords"].OnEvent("Click", LVChordClick)
    cols := CONF["wide_mode"]
        ? [100, 17, 63, 70, 0]
        : [200, 24, 260, 100, 0]
    for i, w in cols {
        keyboard_gui["LV_chords"].ModifyCol(i, w * CONF["gui_scale"])
    }

    btns_wh := "w" . ((CONF["wide_mode"] ? 256 : 610) * CONF["gui_scale"] / 3) . " h" . (20 * CONF["gui_scale"])
    keyboard_gui.Add("Button", "vBtnAddNewChord xp0 y+0 " . btns_wh, "✨ New")
    keyboard_gui.Add("Button", "vBtnChangeSelectedChord x+0 yp0 " . btns_wh, "✏️ Change")
    keyboard_gui.Add("Button", "vBtnDeleteSelectedChord x+0 yp0 " . btns_wh, "🗑️ Delete")
    keyboard_gui.Add("Button",
        "vBtnSaveEditedChord xp-" . ((CONF["wide_mode"] ? 256 : 610) * CONF["gui_scale"] / 3 * 2) . " yp0 " . btns_wh,
        "✔ Save"
    )
    keyboard_gui.Add("Button", "vBtnDiscardChordEditing x+0 yp0 " . btns_wh, "↩ Discard")
    keyboard_gui.Add("Button", "vBtnCancelChordEditing x+0 yp0 " . btns_wh, "❌ Cancel")

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
    sh := CONF["wide_mode"] ? 0 : 255
    keyboard_gui.current_values.Push(keyboard_gui.Add("Text", Scale(1370 - sh, 6, 45) . " vTextBase"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Text", Scale(1370 - sh, 28, 45) . " vTextHold"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", Scale(1420 - sh, 0, 45) . " vBtnBase"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", Scale(1420 - sh, 22, 45) . " vBtnHold"))
    keyboard_gui.SetFont("Norm")
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", Scale(1465 - sh, 0, 20) . " vBtnBaseClear", "✕"))
    keyboard_gui.current_values.Push(keyboard_gui.Add("Button", Scale(1465 - sh, 22, 20) . " vBtnHoldClear", "✕"))
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
    if !CONF["help_texts"] {
        return
    }
    _AddHelpText("Italic c888888", Scale(CONF["wide_mode"] ? 265 : 10, 317), "Borders (hold behavior): ")
    _AddHelpText("Italic Bold c7777AA", "x+3 yp0", "modifier;")
    _AddHelpText("Italic Bold c222222", "x+3 yp0", "active modifier;")
    _AddHelpText("Italic Bold cAAAA11", "x+3 yp0", "chord part;")
    _AddHelpText("Italic Bold cGreen", "x+3 yp0", "next map.")

    _AddHelpText("Italic c888888", "x+" . 100 / USER_DPI . " yp0", "Font: ")
    _AddHelpText("Italic Underline", "x+3 yp0", "with next map from base tap;")

    _AddHelpText("Italic", "x+" . 100 / USER_DPI . " yp0",
        "LBM – base next map, RBM – hold next map/activate modifier."
    )

    _AddHelpText("Italic c888888", Scale(CONF["wide_mode"] ? 265 : 11, 31),
        "The arrows indicate the type of transition: ➤ – base, ▲ – hold, ▼ – chord; "
        . "if it's with a number, that's the used modifier's designation."
    )
}


_FillPathline() {
    static dirs := ["▼", "➤", "▲"]

    keyboard_gui.SetFont("Italic", "Segoe UI")
    root := keyboard_gui.Add("Button", Scale(CONF["wide_mode"] ? 265 : 10, 5), root_text)
    for elem in keyboard_gui.path {
        elem.Visible := false
    }
    keyboard_gui.path.Push(root)
    root.OnEvent("Click", ChangePath.Bind(0))

    keyboard_gui.SetFont("Norm", "Segoe UI")
    if current_path.Length {
        prev := keyboard_gui.path[1]
        for i, val in current_path {
            pref := val[2] > 1 ? String(val[2] - Mod(val[2], 2)) : ""
            dir_text := keyboard_gui.Add("Text", "x+3 yp" . (6 * CONF["gui_scale"]),
                pref . (val[3] ? "▼" : ["➤", "▲"][Mod(val[2], 2) + 1])
            )
            prev := keyboard_gui.Add("Button", "x+3 yp-" . (6 * CONF["gui_scale"]),
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
            if base_type == 2 {
                keyboard_gui["BtnBase"].Text := _GetKeyName(false, 1, _GetVal(current_base))
            } else {
                keyboard_gui["BtnBase"].Text := _GetVal(current_base)
            }
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
                case 2:
                    keyboard_gui["BtnHold"].Text := _GetKeyName(false, 1, _GetVal(current_hold))
                case 4:
                    keyboard_gui["BtnHold"].Text := "Mod " . _GetVal(current_hold)
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
                btn.Text := _GetKeyName(sc, 0, bv)
            } else {
                btn.Text := bv
            }

            hv := _GetVal(key_hold)
            if hv {
                btn.Text .= _GetType(key_hold) == 2 ? "`n" . _GetKeyName(hv, 0, hv) : "`n" . hv
            }
        } else {
            btn.SetFont("Norm")
            btn.Text := _GetKeyName(sc)
        }
        if btn.Text == "" {
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
                        txt[i] := _GetKeyName(false, 1, vals[i][k][2])
                    case 3:
                        txt[i] := "(" . vals[i][k][2] . ")"
                    case 4:
                        txt[i] := "{M" . vals[i][k][2] . "}"
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


_GetKeyName(sc, to_short:=false, from_sc_str:=false) {
    static fixed_names := Map("PrintScreen", "Print`nScreen", "ScrollLock", "Scroll`nLock", "Numlock", "Num`nLock")
    static short_names := Map("PrintScreen", "PrtSc", "ScrollLock", "ScrLk", "Numlock", "NumLk",
        "Backspace", "BS", "LControl", "LCtrl", "RControl", "RCtrl", "AppsKey", "Menu")

    if CONF["keyname_type"] != 1 {
        return sc
    }
    
    if from_sc_str {
        res := GetKeyName(SubStr(from_sc_str, 2, StrLen(from_sc_str) - 2))
        if !res {
            if !sc || GetKeyName(SC_STR[sc]) {
                return from_sc_str
            }
            res := GetKeyName(SC_STR[sc])
        }
    } else {
        res := GetKeyName(SC_STR[sc])
    }

    if to_short && short_names.Has(res) {
        return short_names[res]
    }
    if fixed_names.Has(res) {
        return fixed_names[res]
    }

    return InStr(res, "Numpad") ? "n" . SubStr(res, 7) : res
}