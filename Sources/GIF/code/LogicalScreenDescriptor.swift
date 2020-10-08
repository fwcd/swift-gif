// See http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html

struct LogicalScreenDescriptor {
    let width: UInt16
    let height: UInt16
    let useGlobalColorTable: Bool
    // Between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)
    let colorResolution: UInt8
    let sortFlag: Bool
    let sizeOfGlobalColorTable: UInt8
    let backgroundColorIndex: UInt8
    let pixelAspectRatio: UInt8
}
