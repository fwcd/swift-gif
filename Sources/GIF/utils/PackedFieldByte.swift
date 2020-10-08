struct PackedFieldByte {
    private(set) var rawValue: UInt8
    private var bitIndex: Int = 0

    init(rawValue: UInt8 = 0) {
        self.rawValue = rawValue
    }

    private subscript(_ bitIndex: Int) -> UInt8 {
        get { return (rawValue >> (7 - bitIndex)) }
        set(newValue) { rawValue = rawValue | (newValue << (7 - bitIndex)) }
    }

    /// Appends a value to the bitfield
    /// by converting it to little-endian
    /// and masking it.
    mutating func append(_ appended: UInt8, bits: Int) {
        assert(bitIndex < 8)
        let mask: UInt8 = (1 << UInt8(bits)) - 1
        let masked = appended & mask
        rawValue = rawValue | (masked << ((8 - bits) - bitIndex))
        bitIndex += bits
    }

    mutating func append(_ flag: Bool) {
        append(flag ? 1 : 0, bits: 1)
    }
}
