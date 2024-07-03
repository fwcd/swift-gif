// See http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html

public struct LogicalScreenDescriptor {
    public internal(set) var width: UInt16
    public internal(set) var height: UInt16
    public internal(set) var useGlobalColorTable: Bool
    // Between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)
    public internal(set) var colorResolution: UInt8
    public internal(set) var sortFlag: Bool
    public internal(set) var sizeOfGlobalColorTable: UInt8
    public internal(set) var backgroundColorIndex: UInt8
    public internal(set) var pixelAspectRatio: UInt8
}
