USER_DPI := DllCall("user32\GetDpiForSystem", "uint") / 96


Scale(x?, y?, w?, h?) {
    return (IsSet(x) ? " x" . Round(x * CONF.gui_scale) : "")
         . (IsSet(y) ? " y" . Round(y * CONF.gui_scale) : "")
         . (IsSet(w) ? " w" . Round(w * CONF.gui_scale) : "")
         . (IsSet(h) ? " h" . Round(h * CONF.gui_scale) : "")
}


DrawLayout() {
    global UI

    SetTimer(UpdateOverlayPos, 0)
    try UI.Destroy()

    UI := Gui(, "TapDance for Windows")
    UI.Opt("-DPIScale")
    UI.OnEvent("Close", CloseEvent)
    UI.Add("Edit", "x-999 y-999 w0 h0 vHidden")
    UI.path := []
    UI.current_values := []
    UI.help_texts := []
    UI.buttons := Map()

    UI.SetFont("s" . Round(7 * CONF.font_scale), CONF.font_name)
    UI.Add("DropDownList", "vLangs " . Scale(CONF.wide_mode ? 1370 : 1125, CONF.ref_height + 3, 105), LANGS.GetAll())
    for code, val in LANGS.map {
        if code == gui_lang {
            UI["Langs"].Text := val
        }
    }
    SendMessage(0x1701, 0, 0xFFFFFF, UI["Langs"].Hwnd)
    UI["Langs"].OnEvent("Change", (*) => ChangeLang(UI["Langs"].Value))
    UI.SetFont("Norm s" . Round(8 * CONF.font_scale))

    UI.Add("Text", "vSettings " . Scale(CONF.wide_mode ? 1470 : 1252, CONF.ref_height + 3), "🔧")
    UI["Settings"].OnEvent("Click", ShowSettings)

    _DrawKeys()
    _DrawLayersLV()
    _DrawChordsLV()
    _DrawHelp()
    _DrawCurrentValues()

    uncat := [UI["BtnAddNewLayer"], UI["BtnBackToRoot"]]
    for arr in [UI.layer_ctrl_btns, UI.layer_move_btns, UI.chs_back, UI.chs_front, uncat] {
        for btn in arr {
            f := SubStr(btn.Name, 4)
            btn.OnEvent("Click", %f%)
        }
    }

    ToggleVisibility(0, UI.chs_back, UI["BtnBackToRoot"])

    UI.SetFont("Norm")
    UI.Show(CONF.wide_mode ? Scale(,, 1745) : Scale(,, 1294))

    ChangePath()
}


_DrawKeys() {
    global ALL_SCANCODES
    static keyboard_layouts := Map("ANSI", _BuildLayout("ANSI"), "ISO", _BuildLayout("ISO"))

    ALL_SCANCODES := []
    len := keyboard_layouts[CONF.layout_format].Length
    x_offset := CONF.wide_mode ? 263 : 10
    y_offset := 50 * CONF.gui_scale
    spacing := 5
    height := (CONF.ref_height * CONF.gui_scale - (spacing * (len - 1)) - y_offset)
        / (CONF.extra_k_row ? len - 0.3 : len)

    for row_idx, row in keyboard_layouts[CONF.layout_format] {
        y := y_offset + (row_idx - (row_idx > 1 && CONF.extra_k_row ? 1.3 : 1)) * (height + spacing)
        x := x_offset * 1.0

        for data in row {
            logical_w := data[1]
            w := logical_w * CONF.gui_scale

            if data.Length > 1 {
                sc := data[2]
                if sc !== "CurrMod" {
                    ALL_SCANCODES.Push(sc)
                }
                if sc == 0x11D {
                    UI[CONF.layout_format == "ISO" ? "54" : "310"].GetPos(&shx, , &shw)
                    w := shx + shw - x * CONF.gui_scale + 1
                }

                h := height + (
                    sc == 0x11C || sc == 0x4E || sc == 0x1C && CONF.layout_format == "ISO"
                    ? height + spacing : 0
                )
                if row_idx == 1 && CONF.extra_k_row {
                    h /= 1.5
                }

                btn := UI.Add("Button",
                    "v" . sc . " x" . x * CONF.gui_scale . " y" . y . " w" . w . " h" . h
                    . " +BackgroundSilver +0x8000"
                )
                UI.buttons[sc] := btn
                btn.OnEvent("Click", ButtonLBM.Bind(sc))
                btn.OnEvent("ContextMenu", ButtonRBM.Bind(sc))
            }

            x += logical_w + spacing
        }
    }
}


_DrawLayersLV() {
    p := CONF.wide_mode
        ? Scale(0, 0, 255, CONF.ref_height)
        : Scale(10, CONF.ref_height + 27, 638, CONF.ref_height)
    UI.AddListView("vLV_layers " . p . " Checked", ["?", "P", "Layer", "Base", "→", "Hold", "→"])
    UI["LV_layers"].OnEvent("DoubleClick", LVLayerDoubleClick)
    UI["LV_layers"].OnEvent("Click", LVLayerClick)
    UI["LV_layers"].OnEvent("ItemCheck", LVLayerCheck)
    for i, w in (CONF.wide_mode ? [15, 15, 75, 40, 21, 40, 21] : [25, 30, 230, 135, 40, 135, 40]) {
        UI["LV_layers"].ModifyCol(i, Max(w * CONF.gui_scale, 16 * USER_DPI))
    }
    btns_wh := "w" . ((CONF.wide_mode ? 256 : 635) * CONF.gui_scale / 6)
            . " h" . (20 * CONF.gui_scale)

    for i, arr in [
        ["vBtnAddNewLayer", "✨ New layer"],
        ["vBtnViewSelectedLayer", "🔍 View"],
        ["vBtnRenameSelectedLayer", "✏️ Rename"],
        ["vBtnDeleteSelectedLayer", "🗑️ Delete"],
        ["vBtnMoveUpSelectedLayer", "🔼 Move up"],
        ["vBtnMoveDownSelectedLayer", "🔽 Move down"]]
    {
        p := i == 1 ? " xp-1 y+0 " : " x+0 yp0 "
        UI.Add("Button", arr[1] . p . btns_wh, CONF.wide_mode ? SubStr(arr[2], 1, 2) : arr[2])
    }
    UI.Add("Button", "vBtnBackToRoot " . (CONF.wide_mode ? Scale(0, CONF.ref_height, 256, 20)
        : ("x" . (10 * CONF.gui_scale) . " yp0"
        . " w" . (635 * CONF.gui_scale)
        . " h" . (20 * CONF.gui_scale))
        ),
        CONF.wide_mode ? "🔙" : "🔙 Back to all active layers"
    )

    UI.layer_move_btns := [UI["BtnMoveUpSelectedLayer"], UI["BtnMoveDownSelectedLayer"]]
    UI.layer_ctrl_btns := [
        UI["BtnViewSelectedLayer"], UI["BtnRenameSelectedLayer"], UI["BtnDeleteSelectedLayer"]
    ]
}


_DrawChordsLV() {
    p := CONF.wide_mode
        ? Scale(1490, 0, 255, CONF.ref_height)
        : Scale(647, CONF.ref_height + 27, 638, CONF.ref_height)
    UI.AddListView("vLV_chords " . p, ["Chord", "Value", "→", "Layer", ""])
    UI["LV_chords"].OnEvent("DoubleClick", LVChordDoubleClick)
    UI["LV_chords"].OnEvent("Click", LVChordClick)
    for i, w in (CONF.wide_mode ? [90, 60, 25, 75, 0] : [200, 270, 35, 120, 0]) {
        UI["LV_chords"].ModifyCol(i, w * CONF.gui_scale)
    }

    btns_wh := "w" . ((CONF.wide_mode ? 256 : 635) * CONF.gui_scale / 3)
            . " h" . (20 * CONF.gui_scale)
    UI.chs_front := []
    UI.chs_front.Push(
        UI.Add("Button", "vBtnAddNewChord xp0 y+0 " . btns_wh, "✨ New"),
        UI.Add("Button", "vBtnChangeSelectedChord x+0 yp0 " . btns_wh, "✏️ Change"),
        UI.Add("Button", "vBtnDeleteSelectedChord x+0 yp0 " . btns_wh, "🗑️ Delete")
    )
    x := "xp-" . ((CONF.wide_mode ? 256 : 635) * CONF.gui_scale / 3 * 2)
    UI.chs_back := []
    UI.chs_back.Push(
        UI.Add("Button", "vBtnSaveEditedChord " . x . " yp0 " . btns_wh, "✔ Save"),
        UI.Add("Button", "vBtnDiscardChordEditing x+0 yp0 " . btns_wh, "↩ Discard"),
        UI.Add("Button", "vBtnCancelChordEditing x+0 yp0 " . btns_wh, "❌ Cancel")
    )
    UI.chs_toggles := [UI["BtnChangeSelectedChord"], UI["BtnDeleteSelectedChord"]]
}


_DrawCurrentValues() {
    UI.SetFont("Norm")
    sh := CONF.wide_mode ? 0 : 255
    UI.current_values.Push(
        UI.Add("Text", Scale(1270 - sh, 0, 50, 23) . " +0x200 Center vTextBase"),
        UI.Add("Text", Scale(1270 - sh, 23, 50, 23) . " +0x200 Center vTextHold"),
        UI.Add("Button", Scale(1325 - sh, 0, 160, 23) . " vBtnBase"),
        UI.Add("Button", Scale(1325 - sh, 23, 160, 23) . " vBtnHold"),
        UI.Add("Button", Scale(1490 - sh, 0, 25, 23) . " vBtnBaseClear", "✕"),
        UI.Add("Button", Scale(1490 - sh, 23, 25, 23) . " vBtnHoldClear", "✕"),
        UI.Add("Button", Scale(1515 - sh, 0, 25, 23) . " vBtnBaseClearNest", "🕳"),
        UI.Add("Button", Scale(1515 - sh, 23, 25, 23) . " vBtnHoldClearNest", "🕳")
    )
    UI["BtnBase"].OnEvent("Click", OpenForm.Bind(0))
    UI["BtnHold"].OnEvent("Click", OpenForm.Bind(1))
    UI["BtnBaseClear"].OnEvent("Click", ClearCurrentValue.Bind(0))
    UI["BtnHoldClear"].OnEvent("Click", ClearCurrentValue.Bind(1))
    UI["BtnBaseClearNest"].OnEvent("Click", ClearNested.Bind(0))
    UI["BtnHoldClearNest"].OnEvent("Click", ClearNested.Bind(1))

    ToggleVisibility(0, UI.current_values)
}


_AddHelpText(font_opt, p, txt) {
    UI.SetFont("Norm " . font_opt)
    UI.help_texts.Push(UI.Add("Text", p, txt))
    UI.help_texts[-1].OnEvent("DoubleClick", HideHelp)
}


_DrawHelp() {
    if !CONF.help_texts {
        return
    }
    _AddHelpText("Italic cGray", Scale(CONF.wide_mode ? 265 : 9, CONF.ref_height + 3), "Borders (hold behavior):")
    _AddHelpText("Italic Bold c7777AA", "x+5 yp0", "modifier;")
    _AddHelpText("Italic Bold c222222", "x+5 yp0", "active modifier;")
    _AddHelpText("Italic Bold cAAAA11", "x+5 yp0", "chord part.")

    _AddHelpText("Italic cGray", "x+" . 60 / USER_DPI . " yp0", "Indicators: ")
    _AddHelpText("Italic Bold cGray", "x+5 yp0", "irrevocable;")
    _AddHelpText("Italic Bold cTeal", "x+5 yp0", "instant;")
    _AddHelpText("Italic Bold cBlue", "x+5 yp0", "with up value;")
    _AddHelpText("Italic Bold cRed", "x+5 yp0", "has next map;")
    _AddHelpText("Italic Bold cPurple", "x+5 yp0", "custom long press time;")
    _AddHelpText("Italic Bold cFuchsia", "x+5 yp0", "custom next key waiting time.")

    _AddHelpText("Italic cGray", Scale(CONF.wide_mode ? 265 : 11, 31),
        "The arrows indicate the type of transition: ➤ – base, ▲ – hold, ▼ – chord; "
        . "if it's with a number – the used modifier's designation."
    )

    _AddHelpText("Italic cGray", "x+" . 30 / USER_DPI . " yp0",
        "LBM – base next map, RBM – hold next map/activate mod."
    )
    UI.SetFont("Norm cBlack")
}


_CreateOverlay() {
    global overlay, overlay_x, overlay_y

    if CONF.overlay_type == 1 || !UI.Hwnd
        || !WinExist("ahk_id " . UI.Hwnd) || WinActive("A") !== UI.Hwnd {
        return
    }

    try overlay.Destroy()

    overlay_x := 0
    overlay_y := 0

    overlay := Gui("+AlwaysOnTop +E0x20 -Caption +ToolWindow")
    WinSetTransColor("FFFFFF", overlay.Hwnd)
    overlay.Opt("-DPIScale")
    overlay.BackColor := "FFFFFF"
    overlay.SetFont("s" . 5 * CONF.font_scale . " cGreen")
    overlay.Show(CONF.wide_mode ? Scale(,, 1745, 335) : Scale(,, 1240, 675))
    DllCall("SetWindowLongPtr", "Ptr", overlay.Hwnd, "Int", -8, "Ptr", UI.Hwnd)
    WinActivate("ahk_id " . UI.Hwnd)
    SetTimer(UpdateOverlayPos, 100)
}


_AddOverlayItem(x, y, colour, txt:="") {
    if CONF.overlay_type == 1 {
        return
    }

    if !txt {
        overlay.AddText("x" . x . " y" . y . " " . Scale(,, 3, 3) . " Background" . colour)
    } else {
        overlay.AddText("x" . x . " y" . y, txt)
    }
}


_GetKeyName(sc, with_keytype:=false, to_short:=false, from_sc_str:=false) {
    static fixed_names := Map(
        "PrintScreen", "Print`nScreen", "ScrollLock", "Scroll`nLock", "Numlock", "Num`nLock",
        "Volume_Mute", "Mute", "Volume_Down", "VolD", "Volume_Up", "VolU", "Media_Next", "Next",
        "Media_Prev", "Prev", "Media_Stop", "Stop", "Media_Play_Pause", "Play",
        "Browser_Back", "Back", "Browser_Forward", "Forw", "Browser_Refresh", "Refr",
        "Browser_Stop", "Stop", "Browser_Search", "Srch", "Browser_Favorites", "Fav",
        "Browser_Home", "Home", "Launch_Mail", "Mail", "Launch_Media", "Media",
        "Launch_App1", "App1", "Launch_App2", "App2", "LButton", "LBM", "RButton", "RBM",
        "MButton", "Wheel`nClick", "XButton1", "XBM1", "XButton2", "XBM2", "WheelLeft", "Wheel`n🡐",
        "WheelDown", "Wheel`n🡓", "WheelUp", "Wheel`n🡑", "WheelRight", "Wheel`n🡒"
    )
    static short_names := Map(
        "PrintScreen", "PrtSc", "ScrollLock", "ScrLk", "Numlock", "NumLk",
        "Backspace", "BS", "LControl", "LCtrl", "RControl", "RCtrl", "AppsKey", "Menu",
        "WheelLeft", "WhLeft", "WheelDown", "WhDown", "WheelUp", "WhUp", "WheelRight", "WhRight",
        "MButton", "WhClick"
    )

    if with_keytype && CONF.keyname_type == 2 {
        return "&" . sc
    }

    res := sc
    if from_sc_str {
        res := GetKeyName(SubStr(from_sc_str, 2, -1))
        if !res {
            return from_sc_str
        }
    } else if sc is Number {
        res := GetKeyName(SC_STR[sc])
    }

    return to_short && short_names.Has(res) ? short_names[res]
        : fixed_names.Has(res) ? fixed_names[res]
        : InStr(res, "Numpad") ? "n" . SubStr(res, 7)
        : with_keytype && CONF.keyname_type == 3 && !res ? "&" . sc
        : res
}


_BuildLayout(layout) {
    w := 42
    res := []
    if CONF.extra_k_row {
        res.Push(R(
            [85], [w, GetKeySC("Volume_Mute")], [w, GetKeySC("Volume_Down")],
            [w, GetKeySC("Volume_Up")], [w, GetKeySC("Media_Next")], [w, GetKeySC("Media_Prev")],
            [w, GetKeySC("Media_Stop")], [w, GetKeySC("Media_Play_Pause")],
            [25], [w, GetKeySC("Browser_Back")], [w, GetKeySC("Browser_Forward")],
            [w, GetKeySC("Browser_Refresh")], [w, GetKeySC("Browser_Stop")],
            [w, GetKeySC("Browser_Search")], [w, GetKeySC("Browser_Favorites")],
            [w, GetKeySC("Browser_Home")],
            [24], [w, GetKeySC("Launch_Mail")], [w, GetKeySC("Launch_Media")],
            [w, GetKeySC("Launch_App1")], [w, GetKeySC("Launch_App2")]
        ))
    }
    if CONF.extra_f_row {  ; f13-f24
        res.Push(R([85], 100, 101, 102, 103, [30], 104, 105, 106, 107, [30], 108, 109, 110, 118))
    }

    res.Push(  ; f-row, numrow
        R(1, [30], 59, 60, 61, 62, [30], 63, 64, 65, 66, [30], 67, 68, 87, 88, [5], 311, 70, 69,
            [5], "LButton", "RButton", "XButton1", "XButton2", "CurrMod"),
        R(41, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, [100, 14], [5], 338, 327, 329,
            [5], 325, 309, 55, 74, "WheelRight")
    )

    if layout == "ANSI" {  ; tab…, caps…, shift…
        res.Push(
            R([75, 15], 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, [75, 43],[5], 339, 335, 337,[5], 71, 72, 73, 78, "WheelUp"),
            R([90, 58], 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, [115, 28], [180], 75, 76, 77, [50], "MButton"),
            R([120, 42], 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, [140, 310], [60], 328, [60], 79, 80, 81, 284, "WheelDown")
        )
    } else {
        res.Push(
            R([75, 15], 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, [10], [60, 28], [5], 339, 335, 337, [5], 71, 72, 73, 78, "WheelUp"),
            R([90, 58], 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 43, [245], 75, 76, 77, [50], "MButton"),
            R([70, 42], 86, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, [135, 54], [60], 328, [60], 79, 80, 81, 284, "WheelDown")
        )
    }

    res.Push(  ; ctrl…
        R([70, 29], [70, 347], [70, 56], [325, 57], [60, 312], [60, 348], [60, 349], [65, 285], [5], 331, 336, 333, [5], [105, 82], 83, [50], "WheelLeft")
    )

    return res
}


R(args*) {
    res := []
    for arg in args {
        if arg is Array {
            res.Push(arg)
            try empty_scs.Delete(arg[2])
        } else {
            res.Push([50, arg])
            try empty_scs.Delete(arg)
        }
    }
    return res
}