_FillPathline() {
    UI.SetFont("Italic")
    root := UI.Add("Button", "+0x80 -Wrap" . Scale(10, 5, 50), root_text)
    ToggleVisibility(0, UI.path)
    UI.path := []
    UI.path.Push(root)
    root.OnEvent("Click", ChangePath.Bind(0))
    UI.SetFont("Norm")

    if !current_path.Length {
        ToggleVisibility(0, UI.current_values)
        return
    }

    ToggleVisibility(1, UI.current_values)

    for i, val in current_path {
        dir_text := UI.Add("Text", "x+3 yp" . (6 * CONF.gui_scale),
            (val[2] > 1 ? val[2] : "")
            . (val[4] ? "•" : val[3] ? "▼" : ["➤", "▲"][(val[2] & 1) + 1])
        )
        UI.path.Push(dir_text)

        UI.path.Push(UI.Add("Button", "x+3 yp-"
            . (6 * CONF.gui_scale), val[3] || val[4] || _GetKeyName(val[1], true, true)))
        UI.path[-1].OnEvent("Click", ChangePath.Bind(i))
    }

    ToggleEnabled(!SYS_MODIFIERS.Has(current_path[-1][1]),
        UI["BtnBase"], UI["BtnBaseClear"], UI["BtnBaseClearNest"])
    ToggleEnabled(current_path[-1][3] == false && current_path[-1][4] == false,
        UI["BtnHold"], UI["BtnHoldClear"], UI["BtnHoldClearNest"])
}


_FillSetButtons() {
    if !current_path.Length {
        return
    }
    for arr in [["Base", gui_entries.ubase], ["Hold", gui_entries.uhold]] {
        txt := arr[1]
        curr_node := _GetFirst(arr[2])
        UI["Text" . txt].Text := txt
        UI["Btn" . txt].Text := ""
        if txt == "Hold" && current_path.Length
            && (!(current_path[-1][1] is Number) && SubStr(current_path[-1][1], 1, 5) == "Wheel"
                || EXTRA_SCS.Has(current_path[-1][1])) {
            UI["Btn" . txt].Opt("+Disabled")
            UI["Btn" . txt . "Clear"].Opt("+Disabled")
            UI["Btn" . txt . "ClearNest"].Opt("+Disabled")
            continue
        }
        if !curr_node {
            UI["Btn" . txt . "Clear"].Opt("+Disabled")
            UI["Btn" . txt . "ClearNest"].Opt("+Disabled")
            continue
        }
        _AddIndicators(arr[2], UI["Btn" . txt])
        if !arr[2].scancodes.Count && !arr[2].chords.Count && !arr[2].gestures.Count {
            UI["Btn" . txt . "ClearNest"].Opt("+Disabled")
        }

        UI["Text" . txt].Text .= " ("
            . ["-", "D", "T", "S", "F", "M", "C"][curr_node.down_type]
            . ")"
        switch curr_node.down_type {
            case TYPES.Default:
                UI["Btn" . txt].Text := _GetKeyName(current_path[-1][1], true, true)
            case TYPES.Text:
                UI["Btn" . txt].Text := _CheckDiacr(curr_node.down_val)
            case TYPES.Function:
                UI["Btn" . txt].Text := curr_node.down_val
            case TYPES.KeySimulation:
                UI["Btn" . txt].Text := _GetKeyName(false, false, true, curr_node.down_val)
            case TYPES.Modifier:
                UI["Btn" . txt].Text := "Mod " . curr_node.down_val
            case TYPES.Chord:
                UI["Btn" . txt].Text := "Chord"
                UI["Btn" . txt].Opt("+Disabled")
                UI["Btn" . txt . "Clear"].Opt("+Disabled")
        }
        if curr_node.gui_shortname {
            UI["Btn" . txt].Text := curr_node.gui_shortname
        }
    }
    UI.SetFont("Norm")
}


_FillKeyboard() {
    for sc, btn in UI.buttons {
        if sc == "CurrMod" {
            btn.SetFont("Italic")
            btn.Opt("Disabled +BackgroundGray")
            btn.Text := "Mod:`n" . gui_mod_val
            continue
        }
        btn.Opt("-Disabled +BackgroundSilver")
        btn.SetFont("Norm")

        res := gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val, false, false, false, false)
        b_node := _GetFirst(res.ubase)
        h_node := _GetFirst(res.uhold)
        m_node := _GetFirst(res.umod)

        if temp_chord {
            if SYS_MODIFIERS.Has(sc) || SubStr(sc, 1, 5) == "Wheel"
                || EXTRA_SCS.Has(sc) || !h_node && m_node && m_node.down_type == TYPES.Modifier {
                btn.Opt("+Disabled")
            }
            btn.Opt(temp_chord.Has(String(sc)) ? "+BackgroundBBBB22" : "+BackgroundSilver")
            btn.Text := _GetKeyName(sc, true)
            continue
        }

        btxt := _GetKeyName(sc, true)
        if b_node {
            if res.ubase.active_gestures.Count {
                t := CONF.gest_color
                _rgb := ((t & 0xFF) << 16) | (t & 0xFF00) | ((t >> 16) & 0xFF)
                btn.Opt("+Background" . Format("{:#06x}", _rgb))
            }
            UI["BtnBaseClear"].Opt("-Disabled")
            _AddIndicators(res.ubase, btn)
            switch b_node.down_type {
                case TYPES.Default:
                    btxt := _GetKeyName(sc, true)
                case TYPES.Disabled:
                    btn.SetFont("Italic")
                    btxt := "{D}"
                case TYPES.KeySimulation:
                    btn.SetFont("Italic")
                    btxt := _GetKeyName(sc, false, false, b_node.down_val)
                default:
                    btxt := _CheckDiacr(b_node.down_val)
            }
            if b_node.gui_shortname {
                btxt := b_node.gui_shortname
            }
        }

        htxt := ""
        if h_node {
            _AddIndicators(res.uhold, btn, true)
            switch h_node.down_type {
                case TYPES.Default:
                    htxt := "`n" . _GetKeyName(sc)
                case TYPES.Text:
                    htxt := "`n" . _CheckDiacr(h_node.down_val)
                case TYPES.KeySimulation:
                    htxt := "`n" . _GetKeyName(sc, false, false, h_node.down_val)
                case TYPES.Function:
                    htxt := "`n" . h_node.down_val
                case TYPES.Modifier:
                    htxt := "`n" . h_node.down_val
                    v := 1 << h_node.down_val
                    b := gui_mod_val && gui_mod_val & v == v
                    btn.Opt("+Background" . (b ? "Black" : "7777AA"))
                case TYPES.Chord:
                    btn.Opt("+BackgroundBBBB22")
            }
            if h_node.gui_shortname {
                htxt := "`n" . h_node.gui_shortname
            }
        } else if m_node && m_node.down_type == TYPES.Modifier {
            v := 1 << m_node.down_val
            if gui_mod_val && gui_mod_val & v == v {
                btn.Opt("+BackgroundBlack")
            } else {
                _AddIndicators(res.umod, btn, true)
                btn.Opt("+Background7777AA")
            }
            htxt := "`n" . (m_node.gui_shortname ? m_node.gui_shortname : m_node.down_val)
        }
        btn.Text := btxt . htxt
    }
}


_AddIndicators(unode, btn, is_hold:=false) {
    if CONF.overlay_type == 1 {
        return
    }
    btn.GetPos(&x, &y, &w, &h)
    x += 1
    y += 1
    w -= 2
    h -= 2
    p := 3 * CONF.gui_scale
    node := _GetFirst(unode)
    if node.down_type == TYPES.Modifier {
        cnt := _CountChild("", 0, gui_mod_val + (1 << node.down_val),
            gui_entries.ubase.scancodes, gui_entries.ubase.chords, gui_entries.ubase.gestures)
    } else {
        cnt := _CountChild("", 0, 0, unode.scancodes, unode.chords, unode.gestures)
    }
    if cnt {
        l := StrLen(String(cnt)) * 5 * CONF.font_scale + 4
        (CONF.overlay_type == 3)
            ? _AddOverlayItem(x + w - l, y + (is_hold ? h - 12 * CONF.font_scale : 0), "", cnt)
            : _AddOverlayItem(x + w - p, y + (is_hold ? h - p : 0), "Red")
    }
    if is_hold {
        y += h - p
    }
    for arr in [
        [node.gui_shortname, "Silver"],
        [node.is_irrevocable, "Gray"],
        [node.is_instant, "Teal"],
        [node.up_type !== TYPES.Disabled, "Blue"],
        [node.custom_lp_time, "Purple"],
        [node.custom_nk_time, "Fuchsia"]
    ] {
        if arr[1] {
            _AddOverlayItem(x + p * (A_Index - 1), y, arr[2])
        }
    }
}


_FillLayers() {
    UI["LV_layers"].Delete()

    temp_all_layers := Map()
    if layer_editing {
        for layer in AllLayers.map {
            temp_all_layers[layer] := false
        }
        temp_all_layers[selected_layer] := "*"
    } else {
        for layer in AllLayers.map {
            temp_all_layers[layer] := ActiveLayers[layer]
        }
    }

    for name, v in temp_all_layers {
        if CONF.ignore_inactive && !v {
            UI["LV_layers"].Add("", "", "", name, "", "", "", "")
            continue
        }
        cnt := [0, 0]
        if !current_path.Length {
            for lang, val in AllLayers.map[name] {
                cnt[2 - (lang == gui_lang)] += val
            }
            for i, val in [UI["Langs"].Text, "", "Other roots", ""] {
                UI["LV_layers"].ModifyCol(3+i, , val)
            }
            UI["LV_layers"].Add(
                v ? "Check" : "", "", v || "", name, cnt[1] || "", "", cnt[2] || "", ""
            )
            continue
        }

        txt := ["", ""]
        for i, unode in [gui_entries.ubase, gui_entries.uhold] {
            if unode {
                cnt[i] := _CountChild(name, 0, 0, unode.scancodes, unode.chords, unode.gestures)
            }
            node := _GetFirst(unode, name)
            if !node {
                continue
            }
            if node.gui_shortname {
                txt[i] := node.gui_shortname
                continue
            }

            val := node.down_val
            switch node.down_type {
                case TYPES.Disabled:
                    txt[i] := "{-}"
                case TYPES.Default:
                    txt[i] := "{D}"
                case TYPES.Text:
                    txt[i] := "'" . _CheckDiacr(val) . "'"
                case TYPES.KeySimulation:
                    txt[i] := val ? _GetKeyName(false, false, true, val) : ""
                case TYPES.Function:
                    txt[i] := "(" . val . ")"
                case TYPES.Modifier:
                    txt[i] := "{M" . val . "}"
                case TYPES.Chord:
                    txt[i] := "{C}"
            }
        }
        for i, val in ["Base", "→", "Hold", "→"] {
            UI["LV_layers"].ModifyCol(3+i, , val)
        }
        UI["LV_layers"].Add(
            v ? "Check" : "", "", v || "", name, txt[1], cnt[1] || "", txt[2], cnt[2] || ""
        )
    }
    ToggleEnabled(0, UI.layer_move_btns, UI.layer_ctrl_btns)
    UI["LV_layers"].ModifyCol(3, "Sort")
}


_CountChild(layer, levels, mod_val, arrs*) {
    cnt := 0
    if !layer && layer_editing {
        layer := selected_layer
    }
    for scs in arrs {
        for sc, mods in scs {
            for md, unode in mods {
                if mod_val && mod_val !== md {
                    continue
                }
                if layer && unode.layers.Has(layer) && _IsCounted(unode.layers[layer][0]) {
                    cnt += 1
                }
                if !layer {
                    for nlayer in unode.layers.map {
                        if ActiveLayers.Has(nlayer) && _IsCounted(unode.layers[nlayer][0]) {
                            cnt += 1
                            break
                        }
                    }
                }
                if levels {
                    cnt += _CountChild(
                        layer, levels-1, mod_val, unode.scancodes, unode.chords, unode.gestures
                    )
                }
            }
        }
    }
    return cnt
}


_IsCounted(node) {
    return node && (node.down_type !== TYPES.Chord || node.up_type !== TYPES.Disabled)
}


_FillGestures() {
    UI["LV_gestures"].Delete()

    if !current_path.Length || current_path[-1][4] || current_path[-1][3]
        || SYS_MODIFIERS.Has(current_path[-1][1]) {
        ToggleEnabled(0, UI["BtnAddNewGesture"], UI.gest_toggles)
        for i, val in ["Has nested gestures", "→", "", ""] {
            UI["LV_gestures"].ModifyCol(i, , val)
        }
        for sc, mods in gui_entries.ubase.active_scancodes {
            for md, node in mods {
                cnt := node.active_gestures.Count
                if cnt {
                    UI["LV_gestures"].Add(
                        "",
                        node.fin.gui_shortname || _GetKeyName(sc, true),
                        cnt,
                        md || "",
                        "", sc
                    )
                }
            }
        }
        return
    }

    for i, val in ["Gesture name", "Value", "→", "Layer", "roll it back"] {
        UI["LV_gestures"].ModifyCol(i, , val)
    }
    ToggleEnabled(1, UI["BtnAddNewGesture"])
    checked_layers := layer_editing ? [selected_layer] : ActiveLayers.order
    for vec_str, mods in gui_entries.ubase.gestures {
        ubase := gui_entries.ubase.GetBaseHoldMod(vec_str, gui_mod_val, false, true).ubase
        child_node := _GetFirst(ubase)
        if !child_node {
            continue
        }

        cnt := ubase ? _CountChild("", 0, 0, ubase.scancodes, ubase.chords, ubase.gestures) : 0
        layer_text := ""
        for layer in checked_layers {
            if _EqualNodes(child_node, _GetFirst(ubase, layer)) {
                layer_text .= " & " . layer
            }
        }
        layer_text := SubStr(layer_text, 4)

        switch child_node.down_type {
            case TYPES.Text:
                val := "'" . _CheckDiacr(child_node.down_val) . "'"
            case TYPES.KeySimulation:
                val := _GetKeyName(false, false, true, child_node.down_val)
            case TYPES.Function:
                val := "(" . child_node.down_val . ")"
        }

        UI["LV_gestures"].Add(
            "",
            child_node.gui_shortname,
            val,
            cnt || "",
            layer_text,
            vec_str
        )
    }
    ToggleEnabled(gui_entries && gui_entries.ubase && gui_entries.ubase !== ROOTS[gui_lang],
        UI["BtnAddNewGesture"])
    UI["LV_gestures"].ModifyCol(1, "Sort")
}


_FillChords() {
    UI["LV_chords"].Delete()
    checked_layers := layer_editing ? [selected_layer] : ActiveLayers.order
    for chord_str, mods in gui_entries.ubase.chords {
        ubase := gui_entries.ubase.GetBaseHoldMod(chord_str, gui_mod_val, true).ubase
        child_node := _GetFirst(ubase)
        if !child_node {
            continue
        }

        hl := start_temp_chord && start_temp_chord.Count && chord_str == selected_chord ? "👉 " : ""
        cnt := ubase ? _CountChild("", 0, 0, ubase.scancodes, ubase.chords, ubase.gestures) : 0

        layer_text := ""
        for layer in checked_layers {
            if _EqualNodes(child_node, _GetFirst(ubase, layer)) {
                layer_text .= " & " . layer
            }
        }
        layer_text := SubStr(layer_text, 4)

        switch child_node.down_type {
            case TYPES.Disabled:
                val := "{D}"
            case TYPES.Text:
                val := "'" . _CheckDiacr(child_node.down_val) . "'"
            case TYPES.KeySimulation:
                val := _GetKeyName(false, false, true, child_node.down_val)
            case TYPES.Function:
                val := "(" . child_node.down_val . ")"
        }

        chord_txt := ""
        for sc in StrSplit(chord_str, "-") {
            try {
                chord_txt .= GetKeyName(SC_STR[Integer(sc)]) . " "
            } catch {
                chord_txt .= GetKeyName(SC_STR[sc]) . " "
            }
        }

        UI["LV_chords"].Add(
            "",
            hl . (child_node.gui_shortname || chord_txt),
            val,
            cnt || "",
            layer_text
        )
    }
    UI["LV_chords"].ModifyCol(1, "Sort")
}


_CheckDiacr(value) {
    if StrLen(value) !== 1 {
        return value
    }
    code := Ord(value)
    if code >= 0x0300 && code <= 0x036F
        || code >= 0x1AB0 && code <= 0x1AFF
        || code >= 0x1DC0 && code <= 0x1DFF
        || code >= 0x20D0 && code <= 0x20FF
        || code >= 0xFE20 && code <= 0xFE2F
    {
        return "◌" . value
    }
    return value == "&" ? "&&" : value
}