global is_drawing := false
global prev_x := 0
global prev_y := 0
global points := []
global gest_overlay := false
global track_period := 8
global cum_len := 0.0
global prev_width := 0
global last_gesture_raw := false

global w_min := 2
global w_max := 18


CreateGestOverlay() {
    global gest_overlay

    try gest_overlay.Destroy()
    gest_overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
    gest_overlay.BackColor := "F0F1F2"
    gest_overlay.Show("Hide x0 y0 w" . A_ScreenWidth . " h" . A_ScreenHeight)
    WinSetTransColor("F0F1F2", gest_overlay)
}


DestroyGestOverlay() {
    global gest_overlay

    try gest_overlay.Destroy()
    gest_overlay := false
}


StartDraw(*) {
    global is_drawing, prev_x, prev_y, points, cum_len, prev_width

    if is_drawing {
        return
    }

    CreateGestOverlay()
    last_gesture_raw := false

    is_drawing := true
    gest_overlay.Show("NA")
    MouseGetPos(&prev_x, &prev_y)
    SetTimer(TrackMouse, track_period)
    points := [[prev_x, prev_y]]
    cum_len := 0.0
    prev_width := w_min
}


EndDraw(*) {
    global is_drawing, init_drawing, points, last_gesture_raw

    if !is_drawing {
        return
    }

    SetTimer(TrackMouse, 0)
    is_drawing := false
    DestroyGestOverlay()

    raw_pts := []
    for p in points {
        raw_pts.Push([p[1], p[2]])
    }

    last_gesture_raw := raw_pts

    if init_drawing {
        init_drawing := false
        form["SetGesture"].Text := "Saved!"
        SetTimer(_ReturnButtonText, -2000)
        try form["Save"].Opt("-Disabled")
        WinActivate "ahk_id " . form.Hwnd
    } else {
        SetTimer(() => ProtractorRecognize(raw_pts), -1)
    }

    points := []
}


_ReturnButtonText(*) {
    try form["SetGesture"].Text := "Redraw saved gesture"
}


ProtractorRecognize(raw_pts) {
    global gest_node

    input_vec := NormalizeForProtractor(raw_pts)
    if !(input_vec.Length == 0 || cum_len < CONF.min_gesture_len) {
        best_gesture := ""
        best_score := -1.0
        for name, node in gest_node.active_gestures {
            vals := StrSplit(name, " ")
            out := []
            for v in vals {
                if v !== "" {
                    out.Push(v + 0.0)
                }
            }
            cos := CosineSim(input_vec, out)
            if cos > best_score {
                best_score := cos
                best_gesture := name
            }
        }

        if best_score >= CONF.min_cos_similarity {
            res := gest_node.GetNode(best_gesture, current_mod, false, true)
            gest_node := false
            TransitionProcessing(res)
            DestroyGestOverlay()
            return
        }
    }
    gest_node := false
    if gest_pending {
        gest_pending()
    }
    DestroyGestOverlay()
}


TrackMouse() {
    global is_drawing, prev_x, prev_y, points, cum_len, prev_width

    if !is_drawing {
        SetTimer(TrackMouse, 0)
        return
    }

    MouseGetPos(&x, &y)
    if x !== prev_x || y !== prev_y {
        dx := x - prev_x
        dy := y - prev_y
        d := Sqrt(dx*dx + dy*dy)
        cum_len += d

        target := BrushWidth(cum_len)
        width := target
        if target > prev_width {
            width := Min(target, prev_width + 2)
        }

        DrawLine(prev_x, prev_y, x, y, width)

        prev_x := x
        prev_y := y
        prev_width := width

        points.Push([x, y])
    }
}


BrushWidth(len) {
    global w_min, w_max

    t := 0.012 * (len - 300)
    sigma := (t > 30) ? 1.0 : (t < -30) ? 0.0 : 1.0 / (1.0 + Exp(-t))
    w := w_min + (w_max - w_min) * sigma
    if w < w_min {
        w := w_min
    } else if w > w_max {
        w := w_max
    }
    return Round(w)
}


DrawLine(x1, y1, x2, y2, width:=3) {
    global gest_overlay

    if !gest_overlay {
        return
    }

    hdc := DllCall("GetDC", "ptr", gest_overlay.Hwnd, "ptr")
    if !hdc {
        return
    }

    pen := DllCall("gdi32\CreatePen", "int", 0, "int", width, "uint", CONF.gest_color, "ptr")
    old := DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", pen, "ptr")
    DllCall("gdi32\MoveToEx", "ptr", hdc, "int", x1, "int", y1, "ptr", 0)
    DllCall("gdi32\LineTo",   "ptr", hdc, "int", x2, "int", y2)
    DllCall("gdi32\SelectObject", "ptr", hdc, "ptr", old, "ptr")
    DllCall("gdi32\DeleteObject", "ptr", pen)
    DllCall("ReleaseDC", "ptr", gest_overlay.Hwnd, "ptr", hdc)
}


Resample(pts, dots) {
    if pts.Length == 0 {
        return []
    }
    if dots <= 2 {
        return dots == 1 ? [pts[1]] : [pts[1], pts[pts.Length]]
    }

    total := 0.0
    seg_len := []
    for i, _ in pts {
        if i == pts.Length {
            break
        }
        d := Sqrt((pts[i+1][1]-pts[i][1])**2 + (pts[i+1][2]-pts[i][2])**2)
        seg_len.Push(d)
        total += d
    }

    if total == 0 {
        out := []
        loop dots {
            out.Push([pts[1][1], pts[1][2]])
        }
        return out
    }

    step := total / (dots-1)
    out := [[pts[1][1], pts[1][2]]]

    target := step
    acc := 0.0
    i := 1
    while out.Length < dots-1 {
        while i <= seg_len.Length && seg_len[i] == 0 {
            acc += 0
            i++
        }

        if i > seg_len.Length {
            break
        }

        if acc + seg_len[i] < target - 1e-9 {
            acc += seg_len[i]
            i++
            continue
        }

        p1 := pts[i]
        p2 := pts[i+1]
        d := seg_len[i]
        t := (target - acc) / (d || 1)
        qx := p1[1] + (p2[1]-p1[1]) * t
        qy := p1[2] + (p2[2]-p1[2]) * t
        out.Push([qx, qy])

        target += step
    }

    out.Push([pts[pts.Length][1], pts[pts.Length][2]])

    while out.Length > dots {
        out.Pop()
    }
    while out.Length < dots {
        out.Push([pts[pts.Length][1], pts[pts.Length][2]])
    }

    return out
}


ScaleAndTranslate(pts, target_size:=250, centering:=true) {
    minX := pts[1][1]
    maxX := pts[1][1]
    minY := pts[1][2]
    maxY := pts[1][2]
    for p in pts {
        if p[1] < minX {
            minX := p[1]
        }
        if p[1] > maxX {
            maxX := p[1]
        }
        if p[2] < minY {
            minY := p[2]
        }
        if p[2] > maxY {
            maxY := p[2]
        }
    }

    w := maxX - minX
    h := maxY - minY
    if w == 0 && h == 0 {
        return pts.Clone()
    }

    scale := target_size / (Max(w, h) || 1)

    scaled := []
    for p in pts {
        scaled.Push([(p[1] - minX) * scale, (p[2] - minY) * scale])
    }

    if !centering {
        cx := scaled[1][1]
        cy := scaled[1][2]
    } else {
        sx := 0.0
        sy := 0.0
        for p in scaled {
            sx += p[1]
            sy += p[2]
        }
        cx := sx / scaled.Length
        cy := sy / scaled.Length
    }

    moved := []
    for p in scaled {
        moved.Push([p[1] - cx, p[2] - cy])
    }
    return moved
}


Vectorize(pts) {
    vec := []
    sum2 := 0.0

    for p in pts {
        vec.Push(p[1], p[2])
    }
    for v in vec {
        sum2 += v * v
    }

    len := Sqrt(sum2)
    if len !== 0 {
        for i, v in vec {
            vec[i] := v / len
        }
    }

    return vec
}


CosineSim(vec_a, vec_b) {
    dot := 0.0
    for i, a in vec_a {
        dot += a * vec_b[i]
    }
    return dot
}


NormalizeForProtractor(raw_pts, dots:=64, target_size:=250, centering:=true) {
    if raw_pts.Length < 2 {
        return []
    }

    total := 0.0
    loop raw_pts.Length - 1 {
        dx := raw_pts[A_Index+1][1] - raw_pts[A_Index][1]
        dy := raw_pts[A_Index+1][2] - raw_pts[A_Index][2]
        total += Sqrt(dx*dx + dy*dy)
        if total > 1.0 {
            break
        }
    }
    if total <= 1.0 {
        return []
    }

    pts := Resample(raw_pts, dots)
    pts := ScaleAndTranslate(pts, target_size, centering)
    return Vectorize(pts)
}


DrawExisting(gesture) {
    SetTimer(DestroyGestOverlay, 0)
    CreateGestOverlay()
    gest_overlay.Show("NA")
    vals := StrSplit(gesture, " ")
    len := 0
    out := []
    for v in vals {
        if v !== "" {
            out.Push(v + 0.0)
        }
    }

    hx := A_ScreenWidth // 2
    hy := A_ScreenHeight // 2
    prev_x := out[1] * 1000 + hx
    prev_y := out[2] * 1000 + hy
    prev_w := w_min
    i := 3
    while i < out.Length {
        if !gest_overlay {
            return
        }
        x := out[i] * 1000 + hx
        y := out[i+1] * 1000 + hy
        dx := x - prev_x
        dy := y - prev_y
        d := Sqrt(dx*dx + dy*dy)
        len += d

        target := BrushWidth(len)
        width := target
        if target > prev_w {
            width := Min(target, prev_w + 2)
        }

        try {
            DrawLine(prev_x, prev_y, x, y, width)
        } catch {
            return
        }
        prev_x := x
        prev_y := y
        prev_w := width
        i += 2
        Sleep(1)
    }
    SetTimer(DestroyGestOverlay, -2000)
}