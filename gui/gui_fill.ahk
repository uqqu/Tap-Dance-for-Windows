_FillPathline() {
    UI.SetFont("Italic")
    root := UI.Add("Button", "+0x80 -Wrap" . Scale(10, 5), root_text)
    ToggleVisibility(0, UI.path)
    UI.path := []
    UI.path.Push(root)
    root.OnEvent("Click", ChangePath.Bind(0))
    UI.SetFont("Norm")

    path := buffer_view ? buffer_path : current_path

    if !path.Length {
        return
    }

    for i, val in path {
        dir_text := UI.Add("Text", "x+3 yp" . (6 * CONF.gui_scale.v),
            (val[2] > 1 ? val[2] : "")
            . (val[4] ? "•" : val[3] ? "▼" : ["➤", "▲"][(val[2] & 1) + 1])
        )
        UI.path.Push(dir_text)

        UI.path.Push(UI.Add("Button", "x+3 yp-"
            . (6 * CONF.gui_scale.v), val[3] || val[4] || _GetKeyName(val[1], true, true)))
        UI.path[-1].OnEvent("Click", ChangePath.Bind(i))
    }
}


_FillSetButtons() {
    UI["SwapBufferView"].Visible := false
    if !current_path.Length && !buffer_view {
        ToggleVisibility(0, UI.current_values)
        return
    }


    if buffer_view {
        ToggleVisibility(0, UI.current_values)
        ToggleEnabled(0, UI["BtnBase"], UI["BtnHold"])
        if buffer_path.Length {
            ToggleVisibility(1, UI["TextBase"], UI["BtnBase"], UI["TextHold"], UI["BtnHold"])
        } else if saved_level[1] == 1 {
            ToggleVisibility(1, UI["TextBase"], UI["BtnBase"])
        } else if saved_level[1] == 2 {
            ToggleVisibility(1, UI["TextBase"], UI["BtnBase"], UI["TextHold"], UI["BtnHold"])
        }
        if saved_level[1] == 2 {
            UI["SwapBufferView"].Visible := true
        }
    } else {
        ToggleVisibility(1, UI.current_values)
        ToggleEnabled(!SYS_MODIFIERS.Has(current_path[-1][1]),
            UI["BtnBase"], UI["BtnBaseClear"], UI["BtnBaseClearNest"])
        ToggleEnabled(current_path[-1][3] == false && current_path[-1][4] == false,
            UI["BtnHold"], UI["BtnHoldClear"], UI["BtnHoldClearNest"])
    }

    path := (buffer_view ? buffer_path : current_path).Clone()
    hnode := _GetFirst(gui_entries.uhold)
    ignore_hold_count := buffer_view && !path.Length && hnode && hnode.down_type == TYPES.Modifier

    if !buffer_view || saved_level[1] || path.Length {
        for arr in [["Base", gui_entries.ubase], ["Hold", gui_entries.uhold]] {
            txt := arr[1]
            curr_node := _GetFirst(arr[2])
            UI["Text" . txt].Text := txt
            UI["Btn" . txt].Text := ""
            if txt == "Hold" && path.Length && ONLY_BASE_SCS.Has(path[-1][1]) {
                UI["Btn" . txt].Opt("+Disabled")
                UI["Btn" . txt . "Clear"].Opt("+Disabled")
                UI["Btn" . txt . "ClearNest"].Opt("+Disabled")
                continue
            }
            if !curr_node {
                UI["Btn" . txt . "Clear"].Opt("+Disabled")
                UI["Btn" . txt . "ClearNest"].Opt("+Disabled")
                continue
            } else if !curr_node.down_type {
                UI["Text" . txt].Visible := false
                UI["Btn" . txt].Visible := false
                continue
            }
            _AddIndicators(arr[2], UI["Btn" . txt], false, ignore_hold_count)
            if !arr[2].scancodes.Count && !arr[2].chords.Count && !arr[2].gestures.Count {
                UI["Btn" . txt . "ClearNest"].Opt("+Disabled")
            }

            UI["Text" . txt].Text .= " ("
                . ["-", "D", "T", "S", "F", "M", "C"][curr_node.down_type]
                . ")"
            switch curr_node.down_type {
                case TYPES.Default:
                    UI["Btn" . txt].Text := "{Default}"
                    try UI["Btn" . txt].Text := _GetKeyName(path[-1][1], true, true)
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
    }
    UI.SetFont("Norm")
}


_FillKeyboard() {
    for sc, btn in UI.buttons {
        if sc == "CurrMod" {
            btn.SetFont("Italic")
            btn.Opt(gui_mod_val ? "+BackgroundRed -Disabled" : "+BackgroundSilver +Disabled")
            btn.Text := "Mod:`n" . gui_mod_val
            continue
        }
        btn.dragged_sc := sc
        try btn.dragged_sc := Integer(sc)
        _FillOneButton(sc, btn, sc)
    }
}


_FillOneButton(sc, btn, d_sc) {
    backgr := "Silver"
    btn.Opt("-Disabled")
    btn.SetFont("Norm")

    res := gui_entries.ubase.GetBaseHoldMod(d_sc, gui_mod_val, false, false, false, false)
    b_node := _GetFirst(res.ubase)
    h_node := _GetFirst(res.uhold)
    m_node := _GetFirst(res.umod)

    btxt := _GetKeyName(sc, true)
    if b_node {
        if res.ubase.active_gestures.Count {
            opts := StrSplit(b_node.gesture_opts, ";")
            backgr := "Red"
            try backgr := Format("{:#06x}", Integer("0x"
                . Trim(StrSplit(CONF.gest_colors[1].v, ",")[1])))
            try backgr := Format("{:#06x}", Integer("0x" . opts[8]))
            try backgr := Format("{:#06x}", Integer("0x" . opts[5]))
            try backgr := Format("{:#06x}", Integer("0x" . opts[2]))
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
                btxt := _GetKeyName(d_sc, false, false, b_node.down_val)
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
                htxt := "`n" . _GetKeyName(d_sc, false, false, h_node.down_val)
            case TYPES.Function:
                htxt := "`n" . h_node.down_val
            case TYPES.Modifier:
                htxt := "`n" . h_node.down_val
                v := 1 << h_node.down_val
                b := gui_mod_val && gui_mod_val & v == v
                backgr := b ? "Black" : "7777AA"
            case TYPES.Chord:
                backgr := "BBBB22"
        }
        if h_node.gui_shortname {
            htxt := "`n" . h_node.gui_shortname
        }
    } else if m_node && m_node.down_type == TYPES.Modifier {
        v := 1 << m_node.down_val
        if gui_mod_val && gui_mod_val & v == v {
            backgr := "Black"
        } else {
            _AddIndicators(res.umod, btn, true)
            backgr := "7777AA"
        }
        htxt := "`n" . (m_node.gui_shortname ? m_node.gui_shortname : m_node.down_val)
    }
    if CONF.empty_border_unassigned.v && backgr == "Silver"
        && ((btxt . htxt) == _GetKeyName(sc, true)) {
        backgr := "White"
    }
    btn.Opt("+Background" . backgr)
    btn.Text := btxt . htxt
}


_AddIndicators(unode, btn, is_hold:=false, ignore_hold_count:=false) {
    if CONF.overlay_type.v == 1 {
        return
    }
    btn.GetPos(&x, &y, &w, &h)
    x += 1
    y += 1
    w -= 2
    h -= 2
    p := Integer(3 * CONF.gui_scale.v)
    node := _GetFirst(unode)
    if node.down_type == TYPES.Modifier {
        cnt := ignore_hold_count ? 0 : _CountChild("", 0, gui_mod_val + (1 << node.down_val),
            gui_entries.ubase.scancodes, gui_entries.ubase.chords, gui_entries.ubase.gestures)
    } else {
        cnt := _CountChild("", 0, 0, unode.scancodes, unode.chords, unode.gestures)
    }
    if cnt {
        l := StrLen(String(cnt)) * 5 * CONF.font_scale.v + 4
        res := (CONF.overlay_type.v == 3)
            ? _AddOverlayItem(x + w - l, y + (is_hold ? h - 12 * CONF.font_scale.v : 0), "", cnt)
            : _AddOverlayItem(x + w - p, y + (is_hold ? h - p : 0), "Red")
        btn.indicators.Push(res)
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
            res := _AddOverlayItem(x + p * (A_Index - 1), y, arr[2])
            btn.indicators.Push(res)
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
        if !buffer_view {
            temp_all_layers[selected_layer] := "*"
        }
    } else {
        for layer in AllLayers.map {
            temp_all_layers[layer] := ActiveLayers[layer]
        }
    }

    for name, v in temp_all_layers {
        if CONF.ignore_inactive.v && !v {
            UI["LV_layers"].Add("", "", "", name, "", "", "", "")
            continue
        }
        cnt := [0, 0]
        if buffer_view || !current_path.Length {
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


_CountChild(layer, levels, mod_val, scs, chs, gsts) {
    cnt := 0
    if !layer && layer_editing && !buffer_view {
        layer := selected_layer
    }
    for scs in [scs, chs, gsts] {
        for sc, mods in scs {
            for md, unode in mods {
                if mod_val && mod_val !== (md & ~1) {
                    continue
                }
                if layer && unode.layers.Has(layer) && _IsCounted(unode.layers[layer][0]) {
                    cnt += 1
                }
                if !layer {
                    for nlayer in unode.layers.map {
                        if buffer_view || ActiveLayers.Has(nlayer)
                            && _IsCounted(unode.layers[nlayer][0]) {
                            cnt += 1
                            break
                        }
                    }
                }
                if levels {
                    cnt += _CountChild(layer, levels-1, mod_val, scs, chs, gsts)
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
        for i, val in ["Has nested gestures", "→", "", "", ""] {
            UI["LV_gestures"].ModifyCol(i, , val)
        }
        for sc, mods in gui_entries.ubase.active_scancodes {
            for md, node in mods {
                if selected_layer {
                    cnt := 0
                    for _, g_mods in node.active_gestures {
                        for _, g_node in g_mods {
                            if g_node.layers.Has(selected_layer) {
                                cnt += 1
                            }
                        }
                    }
                } else {
                    cnt := node.active_gestures.Count
                }
                if cnt {
                    UI["LV_gestures"].Add(
                        "",
                        node.fin.gui_shortname || _GetKeyName(sc, true),
                        cnt,
                        md || "",
                        "", "", sc
                    )
                }
            }
        }
        return
    }

    for i, val in ["Gesture name", "Value", "Options", "→", "Layer", "roll it back"] {
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
            _GestOptsToText(child_node.gesture_opts),
            cnt || "",
            layer_text,
            vec_str
        )
    }
    ToggleEnabled(gui_entries && gui_entries.ubase && gui_entries.ubase !== ROOTS[gui_lang],
        UI["BtnAddNewGesture"])
    UI["LV_gestures"].ModifyCol(1, "Sort")
}


_GestOptsToText(opts) {
    vals := StrSplit(opts, ";")
    str := ["LT", "T", "RT", "L", "C", "R", "LB", "B", "RB"][Integer(vals[1])]
    if vals[2] + 1 != CONF.gest_rotate.v {
        str .= ", rotate: " . ["no", "de-noise", "invar."][Integer(vals[2]) + 1]
    }
    if Float(vals[3]) != CONF.scale_impact.v {
        str .= ", scale imp.: " . Round(Float(vals[3]), 2)
    }
    if vals[4] !== "0" {
        str .= ", bidir."
    }
    if vals[5] !== "0" {
        str .= ", closed."
    }
    return str
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
            if !buffer_view && _EqualNodes(child_node, _GetFirst(ubase, layer)) {
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


_FillOther() {
    if !current_path.Length {
        UI.copy_options_menu.Disable("3&")
    }

    ToggleEnabled(0, UI.layer_move_btns, UI.layer_ctrl_btns, UI.chs_toggles, UI.gest_toggles)

    ;ToggleVisibility(root_text !== "root", UI.buffer)
    ToggleEnabled(saved_level && !buffer_view && selected_layer
        && (saved_level[1] !== 2 || current_path.Length), UI["BtnShowPasteMenu"])
    ToggleEnabled(!buffer_view && selected_layer, UI["BtnShowCopyMenu"])

    if UI["TextHold"].Text !== "Hold" && current_path.Length {
        UI.copy_options_menu.Enable("3&")
    } else {
        UI.copy_options_menu.Disable("3&")
    }
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