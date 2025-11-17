class OrderedMap {
    __New() {
        this.map := Map()
        this.order := []
        this.Length := 0
    }

    __Item[name] {
        get => this.map.Get(name, false)
    }

    Add(name, data?, pos_?) {
        if !this.map.Has(name) {
            this.Length += 1
            this.map[name] := data ?? this.Length
            IsSet(pos_) ? this.order.InsertAt(pos_, name) : this.order.Push(name)
        }
    }

    GetAll() {
        result := []
        for name in this.order {
            result.Push(this.map[name])
        }
        return result
    }

    Has(name) {
        return this.map.Has(name)
    }

    Remove(name) {
        if this.map.Has(name) {
            this.Length -= 1
            this.map.Delete(name)
            for i, existing in this.order {
                if existing == name {
                    this.order.RemoveAt(i)
                    break
                }
            }
        }
    }
}


class CombNode {
    __New() {
        this.global_obj := false
        this.specific_obj := false
    }

    __Item[field] {
        get => (!field ? this.global_obj
            : (field == 1 || this.specific_obj ? this.specific_obj
            : this.global_obj))
    }

    Add(data, is_global:=false) {
        if is_global {
            this.global_obj := data
        } else {
            this.specific_obj := data
        }
    }
}


class UnifiedNode {
    __New() {
        this.layers := OrderedMap()
        this.fin := false

        this.scancodes := Map()
        this.chords := Map()
        this.gestures := Map()

        this.active_scancodes := Map()
        this.active_chords := Map()
        this.active_gestures := Map()
    }

    ToArray() {
        res := []
        res.Push([])
        for c_node in this.layers.GetAll() {
            res[-1].Push([__NodeToArray(c_node[1]), __NodeToArray(c_node[0])])
        }
        for t in [this.scancodes, this.chords, this.gestures,
            this.active_scancodes, this.active_chords, this.active_gestures] {
            res.Push(Map())
            for sc, mods in t {
                res[-1][sc] := Map()
                for md, nested_unode in mods {
                    res[-1][sc][md] := nested_unode.ToArray()
                }
            }
        }
        res.Push(__NodeToArray(this.fin))
        return res
    }

    GetNode(schex, md:=0, is_chord:=false, is_gesture:=false, is_active:=false) {
        mp := is_chord
            ? is_active ? this.active_chords : this.chords
            : is_gesture
                ? is_active ? this.active_gestures : this.gestures
                : is_active ? this.active_scancodes : this.scancodes
        return mp.Has(schex) ? mp[schex].Get(md, false) : false
    }

    GetBaseHoldMod(
        schex, md:=0, is_chord:=false, is_gesture:=false, is_active:=false, is_fin:=true
    ) {
        res := {}

        if !is_chord && !is_gesture && !is_active {
            if !this.scancodes.Has(schex) {
                this.scancodes[schex] := Map()
            }
            if !this.scancodes[schex].Has(md) {
                this.scancodes[schex][md] := UnifiedNode()
                this.scancodes[schex][md].fin := GetDefaultNode(schex, md)
            }
        }

        res.ubase := this.GetNode(schex, md, is_chord, is_gesture, is_active)
        res.uhold := this.GetNode(schex, md+1, is_chord, is_gesture, is_active)
        mod_unode := md ? this.GetNode(schex, 1, is_chord, is_gesture, is_active) : res.uhold

        if is_fin {
            res.umod := mod_unode && mod_unode.fin && mod_unode.fin.down_type == TYPES.Modifier
                ? mod_unode : false
        } else {
            res.umod := false
            try res.umod := _GetFirst(mod_unode).down_type == TYPES.Modifier ? mod_unode : false
        }

        return res
    }

    GetModFin(sc) {
        md := this.GetNode(sc, 1)
        return md && md.fin && md.fin.down_type == TYPES.Modifier ? md.fin : false
    }

    MergeNodeRecursive(raw_node, sc, md, layer_name, is_g:=false) {
        node_obj := _BuildNode(raw_node, sc, md)
        node_obj.layer_name := layer_name

        if this.layers.Has(layer_name) {
            this.layers[layer_name].Add(_RepairValue(node_obj), !is_g)
        } else {
            c_node := CombNode()
            c_node.Add(_RepairValue(node_obj), !is_g)
            this.layers.Add(layer_name, c_node)
        }

        for i, mp in [this.gestures, this.chords, this.scancodes] {
            for c_sc, mods in raw_node[-i] {
                if !mp.Has(c_sc) {
                    mp[c_sc] := Map()
                }
                for c_md, child in mods {
                    if !mp[c_sc].Has(c_md) {
                        mp[c_sc][c_md] := UnifiedNode()
                    }
                    mp[c_sc][c_md].MergeNodeRecursive(child, c_sc, c_md, layer_name, is_g)
                }
            }
        }
    }

    BuildActives(prior_layers, sc:=0, md:=0) {
        this.active_scancodes := Map()
        this.active_chords := Map()
        this.active_gestures := Map()
        this.fin := false

        next_priors := []
        for layer in prior_layers {
            if this.layers.Has(layer) {
                node := this.layers[layer][0] || this.layers[layer][1]
                if !this.fin {
                    this.fin := node
                    next_priors.Push(layer)
                    continue
                }
                n_def := (node.down_type == TYPES.Default)
                t_def := (this.fin.down_type == TYPES.Default)

                if t_def && !n_def {
                    this.fin := node
                    next_priors.Push(layer)
                } else if !t_def && n_def || _EqualNodes(this.fin, node) {
                    next_priors.Push(layer)
                }
            }
        }

        for arr in [
            [this.scancodes, this.active_scancodes],
            [this.chords, this.active_chords],
            [this.gestures, this.active_gestures]
        ] {
            for schex, mods in arr[1] {
                for md, next_unode in mods {
                    for layer in next_priors {
                        if next_unode.layers.Has(layer) {
                            if next_unode.BuildActives(next_priors, schex, md) {
                                if !arr[2].Has(schex) {
                                    arr[2][schex] := Map()
                                }
                                arr[2][schex][md] := next_unode
                            }
                            break
                        }
                    }
                }
            }
        }

        return this.active_scancodes.Count || this.active_chords.Count
            || this.active_gestures.Count  || this.fin
    }
}


__NodeToArray(node) {
    if !node {
        return []
    }

    res := []
    for name in [
        "down_type", "down_val", "up_type", "up_val", "is_instant", "is_irrevocable",
        "custom_lp_time", "custom_nk_time", "child_behavior",
        "gui_shortname", "gesture_opts", "sc", "md", "layer_name",
    ] {
        try res.Push(node.%name%)
    }
    return res
}


_BuildNode(raw_node, sc, md, down_type:=false) {
    static default_opts:={pool: 5, rotate: 0, scaling: 0, dirs: 0, closed: 0, len: 1}  ; temp

    b := raw_node.Length == 4  ; root
    node_obj := {sc: sc, md: md}
    for i, name in [
        "down_type", "down_val", "up_type", "up_val", "is_instant", "is_irrevocable",
        "custom_lp_time", "custom_nk_time", "child_behavior", "gui_shortname", "gesture_opts",
    ] {
        node_obj.%name% := b ? 0 : raw_node[i]
    }

    if StrLen(sc) > 256 {  ; gesture ^^'
        node_obj.opts := {}
        vals := StrSplit(node_obj.gesture_opts, ";")
        for i, name in ["pool", "rotate", "scaling", "dirs", "closed", "len"] {
            try {
                node_obj.opts.%name% := name == "scaling" ? Float(vals[i]) : Integer(vals[i])
            } catch {
                node_obj.opts.%name% := default_opts.%name%
            }
        }
        vals := StrSplit(sc, " ")
        node_obj.vec := []
        for v in vals {
            if A_Index == 1 && StrLen(v) == 1 {
                continue
            }
            if v !== "" {
                node_obj.vec.Push(Float(v))
            }
        }
    }

    if down_type {
        node_obj.down_type := down_type
    }
    return _RepairValue(node_obj)
}


GetDefaultNode(sc, md) {
    node_obj := {
        down_type: TYPES.Default,
        down_val: (sc is Number ? "{Blind}" . SC_STR_BR[sc] : "{Blind}{" . sc . "}"),
        up_type: TYPES.Disabled, up_val: "",
        is_instant: 0, is_irrevocable: 0,
        custom_lp_time: 0, custom_nk_time: 0,
        child_behavior: 4, gui_shortname: "", gesture_opts: "",
        sc: sc, md: md
    }
    return node_obj
}


_RepairValue(node_obj) {
    for arr in [["down_type", "down_val"], ["up_type", "up_val"]] {
        node_obj.%arr[2]% := node_obj.%arr[1]% == TYPES.Default
            ? (node_obj.sc is Number
                ? "{Blind}" . SC_STR_BR[node_obj.sc]
                : "{Blind}{" . node_obj.sc . "}")
            : StrReplace(StrReplace(node_obj.%arr[2]%, "%md%", node_obj.md), "%sc%", node_obj.sc)
    }
    return node_obj
}


_EqualNodes(f_node, s_node) {
    return f_node is Object && s_node is Object
        && f_node.down_type == s_node.down_type
        && f_node.down_val == s_node.down_val
        && f_node.up_type == s_node.up_type
        && f_node.up_val == s_node.up_val
        && f_node.is_instant == s_node.is_instant
        && f_node.is_irrevocable == s_node.is_irrevocable
        && f_node.custom_lp_time == s_node.custom_lp_time
        && f_node.custom_nk_time == s_node.custom_nk_time
        && f_node.child_behavior == s_node.child_behavior
}


ReadLayers() {
    global AllLayers, ActiveLayers

    AllLayers := OrderedMap()
    ActiveLayers := OrderedMap()

    loop Files, "layers\*.json" {
        AllLayers.Add(SubStr(A_LoopFileName, 1, -5))
    }
    if !AllLayers.Length {
        AllLayers.Add("default_layer")
        SerializeMap(Map(), "default_layer")
    }

    conf_layers := IniRead("config.ini", "Main", "ActiveLayers")
    str_value := ""
    for layer in StrSplit(conf_layers, ",") {
        if layer && FileExist("layers/" . layer . ".json") {
            ActiveLayers.Add(layer)
            str_value .= layer . ","
        }
    }

    ; rewrite active layers w/o missing
    str_value := SubStr(str_value, 1, -1)
    if str_value != conf_layers {
        IniWrite(SubStr(str_value, 1, -1), "config.ini", "Main", "ActiveLayers")
    }
}


UpdLayers() {
    global curr_unode, version

    curr_unode := ROOTS[CurrentLayout]
    version += 1
    for lang, root in ROOTS {
        root.BuildActives(ActiveLayers.order)
    }
    SetSysModHotkeys()
}


GetLayerList() {
    return ActiveLayers.Length ? ActiveLayers.order : AllLayers.order
}


FillRoots() {
    global ROOTS  ; bloody roots

    ROOTS := Map(0, UnifiedNode())
    for lang in LANGS.map {
        ROOTS[lang] := UnifiedNode()
    }

    for arr in (CONF.ignore_inactive.v
        ? [[ActiveLayers, Map()]] : [[ActiveLayers, Map()], [AllLayers, ActiveLayers]]) {
        for layer in arr[1].map {
            if !arr[2].Has(layer) {
                _MergeLayer(layer)
            }
        }
    }
}

_MergeLayer(layer) {
    raw_roots := DeserializeMap(layer)
    AllLayers.map[layer] := _CountLangMappings(raw_roots)
    for lang, root in raw_roots {
        if !LANGS.Has(lang) {
            if !CONF.unfam_layouts.v {
                continue
            }
            LANGS.Add(lang, "Layout: " . GetLayoutNameFromHKL(lang))
            ROOTS[lang] := UnifiedNode()
        }
        ROOTS[lang].MergeNodeRecursive(root, 0, 0, layer)
    }
    global_raw_root := raw_roots.Get(0, false)
    for lang in LANGS.map {
        if global_raw_root && lang {
            ROOTS[lang].MergeNodeRecursive(global_raw_root, 0, 0, layer, true)
        }
    }
}

_CountLangMappings(raw_roots) {
    res := Map()
    for lang, root in raw_roots {
        stack := [root[-3], root[-2], root[-1]]
        cnt := 0
        while stack.Length {
            mp := stack.Pop()
            for sc, mods in mp {
                for md, node in mods {
                    if node[1] !== TYPES.Chord || node[3] !== TYPES.Disabled {
                        cnt += 1
                    }
                    stack.Push(node[-3], node[-2], node[-1])
                }
            }
        }
        res[lang] := cnt
    }
    return res
}


_WalkJson(json_node, path, is_hold:=false) {
    if !(path[1] is Array) {
        path := [path]
    }

    last_i := path.Length
    for i, arr in path {
        sc := arr[1]
        md := arr[2] + (i == last_i ? is_hold : 0)
        is_chord := arr[3]
        is_gesture := arr[4]
        curr_map := json_node[-3 + (is_chord is String) + (is_gesture is String) * 2]

        if !curr_map.Has(sc) {
            curr_map[sc] := Map()
        }
        entry := curr_map[sc]
        if !entry.Has(md) {
            d_type := md || is_chord ? TYPES.Disabled : TYPES.Default
            entry[md] := [
                d_type, "", TYPES.Disabled, "", 0, 0, 0, 0, 4, "", "", Map(), Map(), Map(),
            ]
        }

        json_node := entry[md]
    }
    return json_node
}