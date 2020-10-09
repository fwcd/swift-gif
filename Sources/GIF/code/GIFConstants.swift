struct GIFConstants {
    static let colorCount = 256
    static let colorChannels = 3
    static let colorResolution: UInt8 = 0b111 // A standard value, between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)
    static let backgroundColorIndex: UInt8 = 0xFF
    static let nonTransparentColorCount = colorCount - 1

    // Magic bytes

    static let trailer: UInt8 = 0x3B
    static let extensionIntroducer: UInt8 = 0x21
    static let imageSeparator: UInt8 = 0x2C
    static let graphicsControlExtension: UInt8 = 0xF9
    static let applicationExtension: UInt8 = 0xFF
    static let commentExtension: UInt8 = 0xFE
    static let plaintextExtension: UInt8 = 0x01

    private init() {}
}
