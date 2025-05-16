_FillPathline() {
    UI.SetFont("Italic")
    root := UI.Add("Button", Scale(CONF.wide_mode ? 265 : 10, 5), root_text)
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
            (val[2] > 1 ? val[2] : "") . (val[3] ? "▼" : ["➤", "▲"][(val[2] & 1) + 1])
        )
        UI.path.Push(dir_text)

        UI.path.Push(UI.Add("Button", "x+3 yp-"
            . (6 * CONF.gui_scale), val[3] || _GetKeyName(val[1], true, true)))
        UI.path[-1].OnEvent("Click", ChangePath.Bind(i))
    }

    ToggleEnabled(!SYS_MODIFIERS.Has(current_path[-1][1]), UI["BtnBase"], UI["BtnBaseClear"])
    ToggleEnabled(current_path[-1][3] == false, UI["BtnHold"], UI["BtnHoldClear"])
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
        if !curr_node {
            continue
        }
        _AddIndicators(arr[2], UI["Btn" . txt], [54, 54])

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
        btn.Opt("-Disabled +BackgroundSilver")
        btn.SetFont("Norm")

        res := gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val)
        b_node := _GetFirst(res.ubase)
        h_node := _GetFirst(res.uhold)
        m_node := _GetFirst(res.umod)

        if temp_chord {
            if SYS_MODIFIERS.Has(sc) || !h_node && m_node && m_node.down_type == TYPES.Modifier {
                btn.Opt("+Disabled")
            }
            btn.Opt(temp_chord.Has(sc) ? "+BackgroundBBBB22" : "+BackgroundSilver")
            btn.Text := _GetKeyName(sc, true)
            continue
        }

        btxt := _GetKeyName(sc, true)
        if !(btxt is String) {
            msgbox("!!")
        }
        if b_node {
            _AddIndicators(res.ubase, btn, [54, 54])
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
            if !(btxt is String) {
                msgbox("!!v")
            }
            if b_node.gui_shortname {
                btxt := b_node.gui_shortname
            }
            if !(btxt is String) {
                msgbox(type(b_node.gui_shortname))
            }
        }

        htxt := ""
        if h_node {
            _AddIndicators(res.uhold, btn, [28, 43], true)
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
            btn.Opt("+Background" . (gui_mod_val && gui_mod_val & v == v ? "Black" : "7777AA"))
            htxt := "`n" . (m_node.gui_shortname ? m_node.gui_shortname : m_node.down_val)
        }
        btn.Text := btxt . htxt
    }
}


_AddIndicators(unode, btn, ay, ah:=false) {
    btn.GetPos(&x, &y, &w, &h)
    node := _GetFirst(unode)
    if CONF.overlay_type !== 1 {
        cnt := _CountChild("", 0, unode.scancodes, unode.chords)
        if cnt {
            l := (StrLen(String(cnt)) - 1) * 6
            (CONF.overlay_type == 3)
                ? _AddOverlayItem(x + w - 3 - l, y + ay[1] + (ah ? h : 0), "", cnt)
                : _AddOverlayItem(x + w + 3, y + ay[2] + (ah ? h : 0), "Red")
        }
        if node.gui_shortname {
            _AddOverlayItem(x + 14, y + ay[2] + (ah ? h : 0), "Silver")
        }
        if node.is_irrevocable {
            _AddOverlayItem(x + 20, y + ay[2] + (ah ? h : 0), "Gray")
        }
        if node.is_instant {
            _AddOverlayItem(x + 26, y + ay[2] + (ah ? h : 0), "Teal")
        }
        if node.up_type !== TYPES.Disabled {
            _AddOverlayItem(x + 32, y + ay[2] + (ah ? h : 0), "Blue")
        }
        if node.custom_lp_time {
            _AddOverlayItem(x + 38, y + ay[2] + (ah ? h : 0), "Purple")
        }
        if node.custom_nk_time {
            _AddOverlayItem(x + 44, y + ay[2] + (ah ? h : 0), "Fuchsia")
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
                cnt[i] := _CountChild(name, 0, unode.scancodes, unode.chords)
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
}


_CountChild(layer, levels, arrs*) {
    cnt := 0
    if !layer && layer_editing {
        layer := selected_layer
    }
    for scs in arrs {
        for sc, mods in scs {
            for md, unode in mods {
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
                    cnt += _CountChild(layer, levels-1, unode.scancodes, unode.chords)
                }
            }
        }
    }
    return cnt
}


_IsCounted(node) {
    return node && (node.down_type !== TYPES.Chord || node.up_type !== TYPES.Disabled)
}


_FillChords() {
    UI["LV_chords"].Delete()
    checked_layers := layer_editing ? [selected_layer] : ActiveLayers.order
    for hex, mods in gui_entries.ubase.chords {
        ubase := gui_entries.ubase.GetBaseHoldMod(hex, gui_mod_val, true).ubase
        child_node := _GetFirst(ubase)
        if !child_node {
            continue
        }

        hl := start_temp_chord && start_temp_chord.Count && hex == selected_chord ? "👉 " : ""
        cnt := ubase ? _CountChild("", 0, ubase.scancodes, ubase.chords) : 0

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
        UI["LV_chords"].Add(
            "",
            hl . (child_node.gui_shortname || SC_ArrToString(HexToScancodes(hex))),
            val,
            cnt || "",
            layer_text,
            hex
        )
    }
}


SC_ArrToString(arr) {
    result := ""
    for sc in arr {
        if sc {
            result .= _GetKeyName(sc, true) . " "
        }
    }
    return result
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