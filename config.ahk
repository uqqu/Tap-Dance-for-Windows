SYS_MODIFIERS := Map(
    0x02A, "<+",
    0x136, ">+",
    0x036, ">+",
    0x01D, "<^",
    0x11D, ">^",
    0x038, "<!",
    0x138, ">!",
    0x15B, "<#",
    0x15C, ">#"
)

SC_STR := []
SC_STR_BR := []
SC_MAP := Map()
loop 511 {
    cur := Format("SC{:03X}", A_Index)
    SC_STR.Push(cur)
    SC_STR_BR.Push("{" . cur . "}")
    SC_MAP[cur] := A_Index
}

SEEN_LANGS := Map(0, true)
LANG_CODES := [0]
LANG_NAMES := ["Global"]

current_lang := GetCurrentLayout()

CheckConfig()
ReadLayers()


CheckConfig() {
    global MS, T, CONF
    if !FileExist("config.ini") {
        FileAppend(
            "[Main]`n"
            . "LayoutFormat=ANSI`n"
            . "HelpTexts=1`n"
            . "GuiScale=1.25`n"
            . "FontScale=1`n"
            . "KeynameType=1`n"
            . "ActiveLayers=`n"
            . "LongPressDuration=150`n"
            . "UserLayouts=",
            "config.ini"
        )
    }

    MS := Integer(IniRead("config.ini", "Main", "LongPressDuration", 150))
    T := "T" . MS / 1000

    CONF := Map()
    CONF["layout_format"] := IniRead("config.ini", "Main", "LayoutFormat", "ANSI")
    CONF["help_texts"] := Integer(IniRead("config.ini", "Main", "HelpTexts", 1))
    CONF["font_scale"] := Float(IniRead("config.ini", "Main", "FontScale", 1))
    CONF["keyname_type"] := Integer(IniRead("config.ini", "Main", "KeynameType", 1))
    if A_ScreenWidth < 1920 {
        CONF["wide_mode"] := Integer(IniRead("config.ini", "Main", "WideMode", 0))
    } else {
        CONF["wide_mode"] := Integer(IniRead("config.ini", "Main", "WideMode", 1))
    }

    switch A_ScreenWidth {
        case 1366, 1920:
            CONF["gui_scale"] := Float(IniRead("config.ini", "Main", "GuiScale", 1.1))
        case 1440:
            CONF["gui_scale"] := Float(IniRead("config.ini", "Main", "GuiScale", 1.15))
        case 1536:
            CONF["gui_scale"] := Float(IniRead("config.ini", "Main", "GuiScale", 1.2))
        case 1600, 2560:
            CONF["gui_scale"] := Float(IniRead("config.ini", "Main", "GuiScale", 1.25))
        case 3840:
            CONF["gui_scale"] := Float(IniRead("config.ini", "Main", "GuiScale", 1.5))
        default:
            CONF["gui_scale"] := Float(IniRead("config.ini", "Main", "GuiScale", 1.0))
    }

    if !IniRead("config.ini", "Main", "UserLayouts") {
        TrackLayouts()
        WinWaitClose(layout_gui.hwnd)
    } else {
        for lang in StrSplit(IniRead("config.ini", "Main", "UserLayouts"), ",") {
            lang := Integer(lang)
            if SEEN_LANGS.Has(lang) {
                continue
            }
            SEEN_LANGS[lang] := true
            LANG_CODES.Push(lang)
            LANG_NAMES.Push(GetLayoutNameFromHKL(lang))
        }
    }
}


ReadLayers() {
    global LANG_KEYS, ALL_LAYERS_LANG_KEYS,  ; all mappings from all langs from active/all layers
        KEYS, glob,  ; prioritized mappings
        ALL_LAYERS, ACTIVE_LAYERS

    LANG_KEYS := Map(0, Map())
    combined_keys := Map(0, Map())
    for lang in LANG_CODES {
        LANG_KEYS[lang] := Map()
        combined_keys[lang] := Map()
    }

    ALL_LAYERS := []
    loop Files, "layers\*.json" {
        if A_LoopFileName != "c_test.json" {
            ALL_LAYERS.Push(SubStr(A_LoopFileName, 1, -5))
        }
    }

    seen_layers := Map()
    ACTIVE_LAYERS := []
    conf_layers := IniRead("config.ini", "Main", "ActiveLayers")
    str_value := ""
    for layer in StrSplit(conf_layers, ",") {
        if !layer || !FileExist("layers/" . layer . ".json") {
            continue
        }

        _AppendLayerMappings(DeserializeMap(layer), layer, combined_keys)
        ACTIVE_LAYERS.Push(layer)
        str_value .= layer . ","
        seen_layers[layer] := true
    }

    IniWrite(SubStr(str_value, 1, -1), "config.ini", "Main", "ActiveLayers")  ; rewrite active layers w/o missing

    ALL_LAYERS_LANG_KEYS := DeepCopy(LANG_KEYS)

    for layer in ALL_LAYERS {
        if !seen_layers.Has(layer) {
            _AppendLayerMappings(DeserializeMap(layer), layer, false)
        }
    }

    KEYS := Map()
    for lang, mp in combined_keys {
        KEYS[lang] := GetPriorKeys(mp)
    }
    SerializeMap(KEYS, "c_test", true)
    glob := KEYS[current_lang]
    SetSysModHotkeys()
}


_AppendLayerMappings(layer_maps, name, combined_keys) {
    for lang, mp in layer_maps {
        if combined_keys && !lang {
            continue
        }
        lang := Integer(lang)
        if !LANG_KEYS.Has(lang) {
            LANG_KEYS[lang] := Map()
        }
        if combined_keys && !combined_keys.Has(lang) {
            combined_keys[lang] := Map()
        } else if !combined_keys && !ALL_LAYERS_LANG_KEYS.Has(lang) {
            ALL_LAYERS_LANG_KEYS[lang] := Map()
        }

        if !SEEN_LANGS.Has(lang) {
            lang_name := GetLayoutNameFromHKL(lang)
            SEEN_LANGS[lang] := true
            LANG_NAMES.Push(lang_name)
            LANG_CODES.Push(lang)
        }

        if combined_keys {
            _DeepMergePreserveVariants(LANG_KEYS[lang], mp, name)
            _DeepMergePreserveVariants(combined_keys[lang], mp, name)
        } else {
            _DeepMergePreserveVariants(ALL_LAYERS_LANG_KEYS[lang], mp, name)
        }
    }
    if combined_keys && layer_maps.Has(0) {
        _DeepMergePreserveVariants(LANG_KEYS[0], layer_maps[0], name)
        for lang in LANG_KEYS {
            _DeepMergePreserveVariants(combined_keys[lang], layer_maps[0], name)
        }
    }
}


TrackLayouts(*) {
    global start_hkl, last_hkl, layout_gui
    layout_gui := Gui("+AlwaysOnTop -SysMenu", "Layout Detector")
    layout_gui.SetFont("s10")
    layout_gui.Add("Text", "Center w400", "Initial setup. Switch between all your language layouts.")
    layout_gui.Add("Text", "Center w400 vCnt", "Found: 0")
    layout_gui.Show("AutoSize")

    start_hkl := GetCurrentLayout()
    last_hkl := 0

    SetTimer(Watch, 100)
}


Watch() {
    global last_hkl

    hkl := GetCurrentLayout()
    if hkl != last_hkl {
        last_hkl := hkl
        if !SEEN_LANGS.Has(hkl) {
            SEEN_LANGS[hkl] := true
            LANG_CODES.Push(hkl)
            LANG_NAMES.Push(GetLayoutNameFromHKL(hkl))
            layout_gui["Cnt"].Text := "Found: " . LANG_CODES.Length - 1
        } else if hkl == start_hkl && LANG_CODES.Length > 1 {
            layout_gui["Cnt"].Text := "Great! Enjoy using it."
            SetTimer(Watch, 0)
            str_value := ""
            for lang in LANG_CODES {
                str_value .= lang . ","
            }
            IniWrite(SubStr(str_value, 3, -1), "config.ini", "Main", "UserLayouts")
            Sleep(1000)
            layout_gui.Destroy()
        }
    }
}


ShowSettings(*) {
    global settings_gui
    try {
        settings_gui.Destroy()
    }

    settings_gui := Gui(, "Settings")
    settings_gui.SetFont("s10")
    settings_gui.Add("CheckBox", "x20 y15 w140 vHelpTexts", "Show help texts").Value := CONF["help_texts"]
    settings_gui.Add("CheckBox", "x+30 yp-2 w140 vWideMode", "Enable wide mode").Value := CONF["wide_mode"]

    settings_gui.Add("Text", "xp-170 y+10 w160", "Layout format:")
    settings_gui.Add("DropDownList", "Center x+10 yp-2 w160 vLayoutFormat", ["ANSI", "ISO"])
    settings_gui["LayoutFormat"].Text := CONF["layout_format"]

    settings_gui.Add("Text", "xp-170 y+10 w160", "Longpress duration (ms):")
    settings_gui.Add("Edit", "Center x+10 yp-2 w160 vLongPressDuration", MS)

    settings_gui.Add("Text", "xp-170 y+10 w160", "Gui scale:")
    settings_gui.Add("Edit", "Center x+10 yp-2 w160 vGuiScale", Round(CONF["gui_scale"], 2))

    settings_gui.Add("Text", "xp-170 y+10 w160", "Font scale:")
    settings_gui.Add("Edit", "Center x+10 yp-2 w160 vFontScale", Round(CONF["font_scale"], 2))

    settings_gui.Add("Button", "Center x20 y+15 w320 h20", "Re-read langs").OnEvent("Click", TrackLayouts)

    settings_gui.Add("Button", "Center x20 y+10 w320 h20 Default vApply", "✔ Apply").OnEvent("Click", SaveConfig)

    settings_gui.Show()
}


SaveConfig(*) {
    IniWrite(settings_gui["HelpTexts"].Value, "config.ini", "Main", "HelpTexts")
    IniWrite(settings_gui["LayoutFormat"].Text, "config.ini", "Main", "LayoutFormat")
    IniWrite(settings_gui["LongPressDuration"].Text, "config.ini", "Main", "LongPressDuration")
    IniWrite(settings_gui["GuiScale"].Text, "config.ini", "Main", "GuiScale")
    IniWrite(settings_gui["FontScale"].Text, "config.ini", "Main", "FontScale")
    IniWrite(settings_gui["WideMode"].Value, "config.ini", "Main", "WideMode")
    settings_gui.Destroy()
    CheckConfig()
    DrawLayout()
}