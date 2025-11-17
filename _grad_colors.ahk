_srgb8_to_lin01(c) {
    v := c / 255
    return v <= 0.04045 ? (v / 12.92) : (((v + 0.055) / 1.055) ** 2.4)
}
_lin01_to_srgb8(v) {
    v := v < 0 ? 0 : (v > 1 ? 1 : v)
    return Round(v <= 0.0031308 ? (v * 12.92*255.0) : ((1.055 * (v ** (1 / 2.4)) - 0.055) * 255))
}

ColorLerp(c1, c2, t) {
    t := t < 0 ? 0 : (t > 1 ? 1 : t)
    r1 := (c1 >> 16) & 0xFF
    g1 := (c1 >> 8) & 0xFF
    b1 :=  c1 & 0xFF
    r2 := (c2 >> 16) & 0xFF
    g2 := (c2 >> 8) & 0xFF
    b2 :=  c2 & 0xFF
    r := Round(r1 + (r2 - r1) * t)
    g := Round(g1 + (g2 - g1) * t)
    b := Round(b1 + (b2 - b1) * t)
    return (r << 16) | (g << 8) | b
}


ColorLerpHsv(c1, c2, t) {
    t := t < 0 ? 0 : (t > 1 ? 1 : t)
    hsv1 := RgbToHsv(c1)
    hsv2 := RgbToHsv(c2)
    h1 := hsv1[1]
    s1 := hsv1[2]
    v1 := hsv1[3]
    h2 := hsv2[1]
    s2 := hsv2[2]
    v2 := hsv2[3]
    d := h2 - h1
    if d > 180 {
        d -= 360
    } else if d < -180 {
        d += 360
    }
    h := h1 + t * d
    s := s1 + t * (s2 - s1)
    v := v1 + t * (v2 - v1)
    return HsvToRgb(h, s, v)
}


ColorLerpLinRgb(c1, c2, t) {
    t := t < 0 ? 0 : (t > 1 ? 1 : t)
    r1 := (c1 >> 16) & 0xFF
    g1 := (c1 >> 8) & 0xFF
    b1 :=  c1 & 0xFF
    r2 := (c2 >> 16) & 0xFF
    g2 := (c2 >> 8) & 0xFF
    b2 :=  c2 & 0xFF

    r1l := _srgb8_to_lin01(r1)
    g1l := _srgb8_to_lin01(g1)
    b1l := _srgb8_to_lin01(b1)
    r2l := _srgb8_to_lin01(r2)
    g2l := _srgb8_to_lin01(g2)
    b2l := _srgb8_to_lin01(b2)

    rl := r1l + (r2l - r1l) * t
    gl := g1l + (g2l - g1l) * t
    bl := b1l + (b2l - b1l) * t

    r := _lin01_to_srgb8(rl)
    g := _lin01_to_srgb8(gl)
    b := _lin01_to_srgb8(bl)

    return (r << 16) | (g << 8) | b
}


ColorAtProgress(t) {
    n := overlay_opts.gest_colors.Length
    if !n {
        return 0xFF0000
    } else if n == 1 {
        return overlay_opts.gest_colors[1]
    }

    lerp := (CONF.gest_color_mode.v == "HSV"
        ? ColorLerpHsv
        : CONF.gest_color_mode.v == "RGB"
            ? ColorLerp
            : ColorLerpLinRgb)

    if !overlay_opts.grad_loop {
        t := t < 0 ? 0 : (t > 1 ? 1 : t)
        seg_count := n - 1
        p := t * seg_count
        seg := Floor(p)
        if seg >= seg_count {
            seg := seg_count - 1
        }
        return lerp(overlay_opts.gest_colors[seg+1], overlay_opts.gest_colors[seg+2], p - seg)
    }

    t := t - Floor(t)
    p := t * n
    i := Floor(p)
    return lerp(
        overlay_opts.gest_colors[i+1],
        overlay_opts.gest_colors[(i + 2 <= n) ? (i + 2) : 1],
        p-i
    )
}


RgbToHsv(colour) {
    r := (colour >> 16) & 0xFF
    g := (colour >> 8) & 0xFF
    b :=  colour & 0xFF
    rf := r / 255
    gf := g / 255
    bf := b / 255
    _max := Max(rf, gf, bf)
    _min := Min(rf, gf, bf)
    d := _max - _min
    v := _max
    if !d {
        h := 0
        s := 0
    } else {
        s := !_max ? 0 : (d / _max)
        if _max == rf {
            t := (gf - bf) / d
            h := 60 * (t < 0 ? t + 6 : t)
        } else if _max == gf {
            h := 60 * (((bf - rf) / d) + 2)
        } else {
            h := 60 * (((rf - gf) / d) + 4)
        }
        if h < 0 {
            h += 360
        } else if h >= 360 {
            h -= 360
        }
    }
    return [h, s, v]
}


HsvToRgb(h, s, v) {
    while h < 0 {
        h += 360
    }
    while h >= 360 {
        h -= 360
    }
    if !s {
        r := g := b := Round(v * 255)
    } else {
        c := v * s
        x := c * (1 - Abs(Mod(h/60, 2) - 1))
        m := v - c
        if h < 60 {
            rf := c, gf := x, bf := 0
        } else if h < 120 {
            rf := x, gf := c, bf := 0
        } else if h < 180 {
            rf := 0, gf := c, bf := x
        } else if h < 240 {
            rf := 0, gf := x, bf := c
        } else if h < 300 {
            rf := x, gf := 0, bf := c
        } else {
            rf := c, gf := 0, bf := x
        }
        r := Round((rf + m) * 255)
        g := Round((gf + m) * 255)
        b := Round((bf + m) * 255)
        r := r < 0 ? 0 : (r > 255 ? 255 : r)
        g := g < 0 ? 0 : (g > 255 ? 255 : g)
        b := b < 0 ? 0 : (b > 255 ? 255 : b)
    }
    return (r << 16) | (g << 8) | b
}