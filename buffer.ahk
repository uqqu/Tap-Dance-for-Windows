SetBit(sc, buffer) {
    idx := sc // 8
    NumPut("UChar", NumGet(buffer, idx, "UChar") | (1 << Mod(sc, 8)), buffer, idx)
}


ClearBit(sc, buffer) {
    idx := sc // 8
    NumPut("UChar", NumGet(buffer, idx, "UChar") & ~(1 << Mod(sc, 8)), buffer, idx)
}


CheckBit(sc, buffer) {
    idx := sc // 8
    return (NumGet(buffer, idx, "UChar") & (1 << Mod(sc, 8))) != 0
}


RemoveBits(main, buffers) {
    loop main.Size {
        i := A_Index - 1
        union := 0
        for b in buffers {
            union |= NumGet(b, i, "UChar")
        }
        current := NumGet(main, i, "UChar")
        NumPut("UChar", current & ~union, main, i)
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
    if Mod(len, 2) != 0 {
        return false
    }
    buf := Buffer(len // 2, 0)
    loop len // 2 {
        byte := Integer("0x" . SubStr(hex, 2 * A_Index - 1, 2))
        NumPut("UChar", byte, buf, A_Index - 1)
    }
    return buf
}


HexToScancodes(hex) {
    return BufferToScancodes(BufferFromHex(hex))
}


BufferToScancodes(buf) {
    scs := []
    loop buf.Size {
        i := A_Index - 1
        loop 8 {
            if (NumGet(buf, i, "UChar") & (1 << (A_Index - 1))) {
                scs.Push(i * 8 + (A_Index - 1))
            }
        }
    }
    return scs
}


CopyBuffer(buf) {
    copy := Buffer(buf.Size)
    DllCall("RtlMoveMemory", "ptr", copy.Ptr, "ptr", buf.Ptr, "uptr", buf.Size)
    return copy
}