// See http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html

public struct LogicalScreenDescriptor {
    public let width: UInt16
    public let height: UInt16
    public let useGlobalColorTable: Bool
    // Between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)
    public let colorResolution: UInt8
    public let sortFlag: Bool
    public let sizeOfGlobalColorTable: UInt8
    public let backgroundColorIndex: UInt8
    public let pixelAspectRatio: UInt8
}
