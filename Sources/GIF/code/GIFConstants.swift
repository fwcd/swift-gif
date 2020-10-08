struct GIFConstants {
    static let colorCount = 256
    static let colorChannels = 3
    static let colorResolution: UInt8 = 0b111 // A standard value, between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)
    static let nonTransparentColorCount = colorCount - 1

    private init() {}
}
