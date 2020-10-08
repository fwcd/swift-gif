struct PackedFieldByte {
    private(set) var rawValue: UInt8
    private var bitIndex: Int = 0

    init(rawValue: UInt8 = 0) {
        self.rawValue = rawValue
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

    mutating func read(bits: Int) -> UInt8 {
        assert(bitIndex < 8)
        let mask: UInt8 = (1 << UInt8(bits)) - 1
        let value = (rawValue >> ((8 - bits) - bitIndex)) & mask
        bitIndex += bits
        return value
    }

    mutating func read() -> Bool {
        read(bits: 1) != 0
    }

    mutating func skip(bits: Int) {
        bitIndex += bits
    }

    mutating func skip() {
        skip(bits: 1)
    }
}
