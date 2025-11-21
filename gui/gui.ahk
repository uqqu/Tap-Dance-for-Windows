#Include "gui_draw.ahk"
#Include "gui_fill.ahk"
#Include "gui_layers.ahk"
#Include "gui_gestures.ahk"
#Include "gui_chords.ahk"
#Include "gui_forms.ahk"


current_path := []
selected_chord := ""
selected_gesture := ""
root_text := "root"

selected_layer := ""
selected_layer_priority := 0
layer_editing := 0

gui_mod_val := 0
gui_lang := 0
gui_entries := {ubase: ROOTS[gui_lang], uhold: false, umod: false}

temp_chord := 0
start_temp_chord := 0

overlay := false

is_drag_mode := false
init_obj := false
drag_map := Map()

A_TrayMenu.Click := TrayClick
A_TrayMenu.Add("tdfw", TrayClick)
A_TrayMenu.Default := "tdfw"
A_TrayMenu.ClickCount := 1

DrawLayout(true)


_GetFirst(node, certain_layer:="") {
    if !node {
        return false
    }
    if layer_editing || certain_layer {
        layer := certain_layer || selected_layer
        if node.layers[layer] && node.layers[layer][0] {
            return node.layers[layer][0]
        }
        return false
    }

    def := false
    for layer in ActiveLayers.order {
        if node.layers.map.Has(layer) && node.layers[layer][0] {
            if node.layers[layer][0].down_type == TYPES.Default {
                if !def {
                    def := node.layers[layer][0]
                }
            } else {
                return node.layers[layer][0]
            }
        }
    }
    return def
}


OneNodeDeeper(schex, md:=-1, is_chord:=false, is_gesture:=false) {
    global current_path, gui_entries, gui_mod_val

    if md == -1 {
        md := gui_mod_val
    }
    current_path.Push([schex, md, is_chord, is_gesture])
    gui_mod_val := 0
    gui_entries := gui_entries.ubase.GetBaseHoldMod(schex, md, is_chord, is_gesture)
    CloseForm()
    UpdateKeys()
}


ChangePath(len:=-1, discard_md:=true, *) {
    global gui_mod_val, gui_entries

    UI["Hidden"].Focus()
    if temp_chord || is_updating {
        return
    }

    if len == -1 {
        len := current_path.Length
    } else {
        CloseForm()
    }

    ToggleVisibility(0, UI.path)
    UI.path := []

    gui_entries := {ubase: ROOTS[gui_lang], uhold: false, umod: false}
    gui_mod_val := len < current_path.Length ? current_path[len + 1][2] & ~1
        : discard_md ? 0 : gui_mod_val
    current_path.Length := len

    for arr in current_path {
        gui_entries := gui_entries.ubase.GetBaseHoldMod(arr*)
    }

    UpdateKeys()
}


_DecomposeMods(n) {
    res := []
    bit := 0
    while n {
        if n & 1 {
            res.Push(bit)
        }
        n >>= 1
        bit++
    }
    return res
}


UpdateKeys() {
    prev_lang := false
    if gui_lang {
        prev_lang := GetCurrentLayout()
        if gui_lang !== prev_lang {
            DllCall("ActivateKeyboardLayout", "ptr", gui_lang, "uint", 0)
        } else {
            prev_lang := false
        }
    }

    ToggleEnabled(1, UI.layer_ctrl_btns, UI.layer_move_btns)
    ToggleEnabled(0, UI.layer_ctrl_btns, UI.chs_toggles, UI.gest_toggles)

    _CreateOverlay()
    _FillPathline()
    _FillSetButtons()
    _FillKeyboard()
    _FillLayers()
    _FillGestures()
    _FillChords()

    if gui_mod_val && UI.path[-1].Text != "²" {
        txt := ""
        for n in _DecomposeMods(gui_mod_val) {
            txt .= n . "+"
        }
        UI.SetFont("c808080")
        UI.path.Push(UI.Add("Text", "x+7 yp" . (6 * CONF.gui_scale.v), RTrim(txt, "+")))
        UI.SetFont("cD3D3D3")
        UI.path.Push(UI.Add("Text", "xp-5 yp+13", "²"))
        UI.SetFont("cBlack")
    }

    if prev_lang {
        DllCall("ActivateKeyboardLayout", "ptr", prev_lang, "uint", 0)
    }
}


HandleKeyPress(sc) {
    global temp_chord

    if sc == 0x038 || sc == 0x138 {  ; unfocus hidden menubar
        Send("{Alt}")
    }

    if is_drag_mode || is_updating {
        return
    }

    name := _GetKeyName(sc)
    if name == CONF.gui_back_sc.v && current_path.Length {
        ChangePath(current_path.Length - 1)
    } else if name == CONF.gui_set_sc.v && UI["BtnBase"].Enabled && UI["BtnBase"].Visible {
        OpenForm(0)
    } else if name == CONF.gui_set_hold_sc.v && UI["BtnHold"].Enabled && UI["BtnHold"].Visible {
        OpenForm(1)
    } else if temp_chord {
        str_sc := String(sc)
        btn := UI.buttons[sc]
        if !btn.Enabled {
            return
        }
        if temp_chord.Has(str_sc) {
            temp_chord.Delete(str_sc)
            btn.Opt("+BackgroundSilver")
        } else {
            temp_chord[str_sc] := true
            btn.Opt("+BackgroundBBBB22")
        }
        btn.Text := btn.Text
    } else if CONF.gui_alt_ignore.v && (sc == 0x038 || sc == 0x138) {
        return
    } else if SubStr(sc, 1, 5) == "Wheel" {
        ButtonLMB(sc)
    } else {
        bnode := _GetFirst(gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val).ubase)
        is_hold := KeyWait(SC_STR[sc],
            (bnode && bnode.custom_lp_time ? "T" . bnode.custom_lp_time / 1000 : CONF.T))
        if WinActive("A") == UI.Hwnd {  ; with postcheck
            is_hold ? ButtonLMB(sc) : ButtonRMB(sc)
        }
    }
}


ButtonLMB(sc, *) {
    UI["Hidden"].Focus()

    if !is_updating {
        _Move(sc, 0)
    }
}


ButtonRMB(sc, *) {
    global gui_mod_val

    UI["Hidden"].Focus()

    if ONLY_BASE_SCS.Has(sc) || is_updating {
        return
    }

    res := gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val, false, false, false, false)

    h_node := _GetFirst(res.uhold)
    if h_node && h_node.down_type == TYPES.Chord {
        return
    }

    m_node := _GetFirst(res.umod)
    md := h_node && h_node.down_type == TYPES.Modifier ? h_node
        : m_node && m_node.down_type == TYPES.Modifier ? m_node : false
    if md {
        gui_mod_val ^= 1 << md.down_val
        UpdateKeys()
        return
    }

    _Move(sc, 1)
}


_Move(sc, is_hold) {
    global gui_mod_val

    if temp_chord {
        HandleKeyPress(sc)
        return
    }
    if SYS_MODIFIERS.Has(sc) {
        _current_path := current_path.Clone()
        _current_path.Push([sc, 0, 0, 0])
        _gui_entries := gui_entries.ubase.GetBaseHoldMod(sc, 0, 0, 0)
        OpenForm(1, _current_path, 0, _gui_entries)
        return
    }
    OneNodeDeeper(sc, gui_mod_val + is_hold)
}


SaveValue(
    is_hold, layer, down_type, down_val:="", up_type:=false, up_val:="",
    is_instant:=false, is_irrevocable:=false, custom_lp_time:=false, custom_nk_time:=false,
    child_behavior:=false, shortname:="", gest_opts:=""
) {
    json_root := DeserializeMap(layer)

    if !json_root.Has(gui_lang) {
        json_root[gui_lang] := ["", Map(), Map(), Map()]
    }
    json_node := _WalkJson(json_root[gui_lang], current_path, is_hold)
    json_node[1] := down_type
    json_node[2] := down_type == TYPES.Default || down_type == TYPES.Disabled ? "" : down_val . ""
    json_node[3] := up_type || TYPES.Disabled
    json_node[4] := up_type == TYPES.Default || json_node[3] == TYPES.Disabled ? "" : up_val . ""
    json_node[5] := Integer(is_instant)
    json_node[6] := Integer(is_irrevocable)
    json_node[7] := Integer(custom_lp_time)
    json_node[8] := Integer(custom_nk_time)
    json_node[9] := Integer(child_behavior)
    json_node[10] := shortname
    json_node[11] := gest_opts
    SerializeMap(json_root, layer)

    FillRoots()
    if layer_editing {
         AllLayers.map[selected_layer] := true
        _MergeLayer(selected_layer)
    }
    UpdLayers()
    ChangePath()
}


ClearCurrentValue(is_hold, layer:="", *) {
    new_dtype := !current_path[-1][2] && !is_hold ? TYPES.Default : TYPES.Disabled
    if layer_editing {
        SaveValue(is_hold, selected_layer, new_dtype)
        return
    }

    if ActiveLayers.Length == 1 {
        selected_layers := ActiveLayers.order
    } else {
        layers := []
        checked_node := _GetFirst(is_hold ? gui_entries.uhold : gui_entries.ubase)
        for comb_node in (is_hold ? gui_entries.uhold : gui_entries.ubase).layers.GetAll() {
            if _EqualNodes(comb_node[0], checked_node) {
                layers.Push(comb_node[0].layer_name)
            }
        }
        if !layers.Length {
            return
        }
        selected_layers := layers.Length == 1 ? layers : ChooseLayers(layers)
    }

    for layer in selected_layers {
        SaveValue(is_hold, layer, new_dtype)
    }
}


ClearNested(is_hold, layer:="", *) {
    if MsgBox("Do you want to delete all nested assignments?",
        "Confirmation", "YesNo Icon?") == "No" {
        return
    }

    if layer_editing {
        selected_layers := [selected_layer]
    } else if ActiveLayers.Length == 1 {
        selected_layers := ActiveLayers.GetAll()
    } else {
        layers := []
        checked_node := _GetFirst(is_hold ? gui_entries.uhold : gui_entries.ubase)
        for comb_node in (is_hold ? gui_entries.uhold : gui_entries.ubase).layers.GetAll() {
            if _EqualNodes(comb_node[0], checked_node) {
                layers.Push(comb_node[0].layer_name)
            }
        }
        if !layers.Length {
            return
        }
        selected_layers := layers.Length == 1 ? layers : ChooseLayers(layers)
    }

    for layer in selected_layers {
        json_root := DeserializeMap(layer)

        if !json_root.Has(gui_lang) {
            json_root[gui_lang] := ["", Map(), Map(), Map()]
        }
        json_node := _WalkJson(json_root[gui_lang], current_path, is_hold)
        json_node[-3] := Map()
        json_node[-2] := Map()
        json_node[-1] := Map()
        SerializeMap(json_root, layer)
    }

    FillRoots()
    if layer_editing {
        AllLayers.map[selected_layer] := true
        _MergeLayer(selected_layer)
    }
    UpdLayers()
    ChangePath()
}


ChangeLang(lang, *) {
    global gui_lang

    UI["Hidden"].Focus()
    gui_lang := LANGS.order[lang]
    ChangePath()
}


TrayClick(*) {
    if !DllCall("IsWindowVisible", "ptr", UI.Hwnd) {
        UI.Show()
        ChangePath()
        if !overlay {
            _CreateOverlay()
        }
        overlay.Show()
        SetTimer(UpdateOverlayPos, 100)
    } else {
        UI.Hide()
        SetTimer(UpdateOverlayPos, 0)
        if overlay {
            overlay.Hide()
        }
    }
}


CloseEvent(*) {
    global overlay

    SetTimer(UpdateOverlayPos, 0)
    overlay.Hide()
}


HideHelp(*) {
    IniWrite(0, "config.ini", "Main", "HelpTexts")
    CONF.help_texts.v := false
    for txt in UI.help_texts {
        txt.Visible := false
    }
    UI.help_texts := []
}


ToggleEnabled(state, arrs*) {
    for arr in arrs {
        if !(arr is Array) {
            arr.Enabled := state == 2 ? !arr.Enabled : state
            continue
        }
        for elem in arr {
            elem.Enabled := state == 2 ? !elem.Enabled : state
        }
    }
}


ToggleVisibility(state, arrs*) {
    for arr in arrs {
        if !(arr is Array) {
            arr.Visible := state == 2 ? !arr.Visible : state
            continue
        }
        for elem in arr {
            elem.Visible := state == 2 ? !elem.Visible : state
        }
    }
}


UpdateOverlayPos(*) {
    global overlay, overlay_x, overlay_y

    if !UI || !UI.Hwnd || !WinExist("ahk_id " . UI.Hwnd)
        || WinActive("A") !== UI.Hwnd && WinActive("A") !== overlay.Hwnd {
        overlay.Hide()
        return
    }

    try {  ; TODO
        pt := Buffer(8, 0)
        DllCall("ClientToScreen", "ptr", UI.Hwnd, "ptr", pt)
        x := NumGet(pt, 0, "int")
        y := NumGet(pt, 4, "int")
        if overlay_x !== x || overlay_y !== y
            || !DllCall("IsWindowVisible", "Ptr", overlay.Hwnd) {
            overlay.Show("x" . x . " y" . y)
            overlay_x := x
            overlay_y := y
        }
    }
    WinActivate("ahk_id " . UI.Hwnd)
}


EnableDragMode(*) {
    global drag_map, is_drag_mode

    drag_map := Map()
    is_drag_mode := true
    for sc in ALL_SCANCODES {
        drag_map[sc] := sc
    }

    UI.Title := "Drag mode"
    ToggleEnabled(0, UI.path, UI.current_values)
    ToggleVisibility(2, UI.drag_btns)
}


SaveDrag(*) {
    global drag_map, is_drag_mode

    _ClearEquals(drag_map)

    if !drag_map.Count {
        _EndDragMode()
        return
    }

    if !layer_editing && ActiveLayers.order.Length !== 1 {
        inp := MsgBox("You're not in single layer editing mode. "
            . "Do you want to apply the changes to all of them? "
            . "(press “no” to manually select layers)",
            "Confirmation", "YesNoCancel Icon?")
        if inp == "Cancel" {
            return
        } else if inp == "No" {
            layers := ChooseLayers(ActiveLayers.order)
            if !layers.Length {
                return
            }
        } else {
            layers := ActiveLayers.order
        }
    } else {
        layers := layer_editing ? [selected_layer] : ActiveLayers.order
    }

    ToggleEnabled(0, UI.drag_btns)
    ToggleFreeze(1)

    is_changed := false
    for layer in layers {
        is_changed := _ApplyDragsToLayer(layer, drag_map) || is_changed
    }

    if is_changed {
        FillRoots()
        if layer_editing {
            AllLayers.map[selected_layer] := true
            _MergeLayer(selected_layer)
        }
        UpdLayers()
        ChangePath(-1, false)
    }

    _EndDragMode()
}


_ClearEquals(mp) {
    to_del := []
    for k in mp {
        if k == mp[k] {
            to_del.Push(k)
        }
    }
    for k in to_del {
        mp.Delete(k)
    }
}


_ApplyDragsToLayer(layer, mp) {
    json_root := DeserializeMap(layer)

    if !json_root.Has(gui_lang) {
        return false
    }

    if current_path.Length {
        res := _WalkJson(json_root[gui_lang], current_path, false, true)
        if !res {
            return false
        }
        scs_map := res[12]
        chs_map := res[13]
    } else {
        scs_map := json_root[gui_lang][2]
        chs_map := json_root[gui_lang][3]
    }

    seen := Map()
    is_changed := false
    for a_sc, b_sc in mp {
        if seen.Has(a_sc) {
            continue
        }

        a := scs_map.Get(a_sc, Map())
        b := scs_map.Get(b_sc, Map())
        a_base := a.Get(gui_mod_val, false)
        a_hold := a.Get(gui_mod_val + 1, false)
        b_base := b.Get(gui_mod_val, false)
        b_hold := b.Get(gui_mod_val + 1, false)

        if !a_base && !a_hold && !b_base && !b_hold {
            continue
        }

        is_changed := true
        seen[b_sc] := true

        if !a.Count {
            scs_map[a_sc] := Map()
        }
        if b_base {
            scs_map[a_sc][gui_mod_val] := b_base
        } else {
            try scs_map[a_sc].Delete(gui_mod_val)
        }
        if b_hold {
            scs_map[a_sc][gui_mod_val+1] := b_hold
        } else {
            try scs_map[a_sc].Delete(gui_mod_val+1)
        }

        if !b.Count {
            scs_map[b_sc] := Map()
        }
        if a_base {
            scs_map[b_sc][gui_mod_val] := a_base
        } else {
            try scs_map[b_sc].Delete(gui_mod_val)
        }
        if a_hold {
            scs_map[b_sc][gui_mod_val+1] := a_hold
        } else {
            try scs_map[b_sc].Delete(gui_mod_val+1)
        }
    }

    new_chords := Map()
    for chord_str, mds in chs_map {
        if !mds.Has(gui_mod_val) {
            new_chords[chord_str] := _MapUnion(new_chords.Get(chord_str, Map()), mds)
            continue
        }

        new_chords[chord_str] := new_chords.Get(chord_str, Map())
        for md, vals in mds {
            if md !== gui_mod_val {
                new_chords[chord_str][md] := vals
            } else {
                is_changed := true
            }
        }

        new_scs := []
        for sc in StrSplit(chord_str, "-") {
            try sc := Integer(sc)
            new_scs.Push(mp.Has(sc) ? mp[sc] : sc)
        }

        new_chord_str := ChordToStr(new_scs)
        new_chords[new_chord_str] := _MapUnion(
            new_chords.Get(new_chord_str, Map()),
            Map(gui_mod_val, mds[gui_mod_val])
        )
    }

    try {
        res[13] := new_chords
    } catch {
        json_root[gui_lang][3] := new_chords
    }

    if is_changed {
        SerializeMap(json_root, layer)
        return true
    }
    return false
}


_MapUnion(a, b) {
    res := Map()

    for k, v in a {
        res[k] := v
    }
    for k, v in b {
        res[k] := v
    }

    return res
}


CancelDrag(*) {
    _ClearEquals(drag_map)

    if drag_map.Count {
        if MsgBox("Do you want to undo the changes?", "Confirmation", "YesNo Icon?") == "No" {
            return
        } else {
            ChangePath(-1, false)
        }
    }

    _EndDragMode()
}


_EndDragMode() {
    global drag_map, is_drag_mode

    drag_map := Map()
    is_drag_mode := false
    UI.Title := "TapDance for Windows"
    ToggleVisibility(2, UI.drag_btns)
    ToggleEnabled(1, UI.drag_btns, UI.current_values, UI.path)
}


StartDragButtons(obj) {
    global init_obj, curr_obj

    init_obj := obj
    sc := obj.Name
    try sc := Integer(sc)

    if SYS_MODIFIERS.Has(sc) {
        for name, btn in UI.buttons {
            res := gui_entries.ubase.GetBaseHoldMod(name, gui_mod_val, false, false, false, false)
            b_node := _GetFirst(res.ubase)
            h_node := _GetFirst(res.uhold)
            m_node := _GetFirst(res.umod)
            btn.Opt(b_node || (h_node && !m_node) ? "+Disabled" : "-Disabled")
        }
    } else if ONLY_BASE_SCS.Has(sc) {
        for name, btn in UI.buttons {
            res := gui_entries.ubase.GetBaseHoldMod(name, gui_mod_val, false, false, false, false)
            b_node := _GetFirst(res.ubase)
            h_node := _GetFirst(res.uhold)
            m_node := _GetFirst(res.umod)
            btn.Opt(h_node || m_node ? "+Disabled" : "-Disabled")
        }
    } else {
        res := gui_entries.ubase.GetBaseHoldMod(sc, gui_mod_val, false, false, false, false)
        b_node := _GetFirst(res.ubase)
        h_node := _GetFirst(res.uhold)
        m_node := _GetFirst(res.umod)

        if h_node || m_node {
            for name in ONLY_BASE_SCS {
                try UI[String(name)].Opt("+Disabled")
            }
        } else {
            for name in ONLY_BASE_SCS {
                try UI[String(name)].Opt("-Disabled")
            }
        }
        if b_node || (h_node && !m_node) {
            for name in SYS_MODIFIERS {
                try UI[String(name)].Opt("+Disabled")
            }
        } else {
            for name in SYS_MODIFIERS {
                try UI[String(name)].Opt("-Disabled")
            }
        }
    }

    curr_obj := false
    SetTimer(TrackDrag, 8)
}


TrackDrag() {
    global curr_obj

    MouseGetPos(,, &win_id, &ctrl_hwnd, 2)
    if ctrl_hwnd && win_id == UI.Hwnd {
        obj := GuiCtrlFromHwnd(ctrl_hwnd)
        is_btn := UI.buttons.Has(obj.Name)
        try is_btn := UI.buttons.Has(Integer(obj.Name))
        if is_btn && obj.Enabled && obj !== curr_obj {
            if curr_obj {  ; return prev moved
                _SwapButtons(curr_obj, init_obj)
            }
            if obj !== init_obj {
                _SwapButtons(obj, init_obj)
                curr_obj := obj
            } else {
                curr_obj := false
            }
        }
    }
}


_SwapButtons(a, b) {
    for ind in a.indicators {
        try ind.Visible := false
    }
    for ind in b.indicators {
        try ind.Visible := false
    }
    a.indicators := []
    b.indicators := []
    an := a.dragged_sc
    bn := b.dragged_sc
    a.dragged_sc := bn
    b.dragged_sc := an
    _FillOneButton(a.Name, a, bn)
    _FillOneButton(b.Name, b, an)
}


StopDragButtons(*) {
    global init_obj, curr_obj, drag_map

    SetTimer(TrackDrag, 0)
    if curr_obj {
        dn := init_obj.dragged_sc
        mn := curr_obj.dragged_sc
        t := drag_map[dn]
        drag_map[dn] := drag_map[mn]
        drag_map[mn] := t
        curr_obj := false
    }
    init_obj := false
    for name, btn in UI.buttons {
        if name !== "CurrMod" {
            try btn.Opt("-Disabled")
        }
    }
}


ToggleFreeze(state:=2) {
    global is_updating
    static prev_path_txt:="", prev_title:=""

    if state == 0 || state == 2 && is_updating {
        is_updating := false
        try {
            UI.path[1].Text := prev_path_txt
            UI.Title := prev_title
        }
    } else if !is_updating {
        is_updating := true
        try {
            prev_path_txt := UI.path[1].Text
            prev_title := UI.Title
            UI.path[1].Text := "⟳"
            UI.Title := "⟳ Applying changes…"
        }
    }
}