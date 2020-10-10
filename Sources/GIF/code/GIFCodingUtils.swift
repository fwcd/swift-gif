func colorTableSizeOf(colorResolution: UInt8) -> Int {
    return 1 << (UInt(colorResolution) + 1) // = 2 ^ (N + 1), see http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html#graphics_control_extension_block
}
