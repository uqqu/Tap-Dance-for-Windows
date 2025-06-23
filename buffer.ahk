SetBit(sc, buffer) {
    if MOUSE_SCS.Has(sc) {
        if sc == "WheelUp" || sc == "WheelDown" {
            return
        }
        sc := MOUSE_SCS[sc]
    }
    NumPut("UChar", NumGet(buffer, sc // 8, "UChar") | (1 << (sc & 7)), buffer, sc // 8)
}


ClearBit(sc, buffer) {
    if MOUSE_SCS.Has(sc) {
        sc := MOUSE_SCS[sc]
    }
    NumPut("UChar", NumGet(buffer, sc // 8, "UChar") & ~(1 << (sc & 7)), buffer, sc // 8)
}


CheckBit(sc, buffer) {
    if MOUSE_SCS.Has(sc) {
        sc := MOUSE_SCS[sc]
    }
    return (NumGet(buffer, sc // 8, "UChar") & (1 << (sc & 7))) !== 0
}


RemoveBits(main, buffers) {
    loop main.Size {
        i := A_Index - 1
        union := 0
        for b in buffers {
            union |= NumGet(b, i, "UChar")
        }
        NumPut("UChar", NumGet(main, i, "UChar") & ~union, main, i)
    }
}


BufferToHex(buf) {
    hex := ""
    loop buf.Size {
        hex .= Format("{:02X}", NumGet(buf, A_Index - 1, "UChar"))
    }
    return hex
}


BufferFromHex(hex) {
    len := StrLen(hex)
    if (len & 1) !== 0 {
        return false
    }
    buf := Buffer(len // 2, 0)
    loop len // 2 {
        NumPut("UChar", Integer("0x" . SubStr(hex, 2 * A_Index - 1, 2)), buf, A_Index - 1)
    }
    return buf
}


HexToScancodes(hex) {
    return BufferToScancodes(BufferFromHex(hex))
}


BufferToScancodes(buf) {
    scs := []
    loop buf.Size {
        byte := NumGet(buf, A_Index - 1, "UChar")
        base := (A_Index - 1) * 8
        if byte {
            loop 8 {
                if byte & (1 << (A_Index - 1)) {
                    scs.Push(base + A_Index - 1)
                }
            }
        }
    }
    return scs
}