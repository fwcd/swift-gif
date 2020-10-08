import Foundation
import Graphics

fileprivate let transparentColorIndex: UInt8 = 0xFF
fileprivate let colorResolution: UInt8 = 0b111 // Between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)

/// Some high-level extensions to the GIF structure
/// supporting en- and decoding.
extension GIF {
    public var width: Int { logicalScreenDescriptor.width }
    public var height: Int { logicalScreenDescriptor.height }

    public init(width: Int, height: Int, globalQuantization: ColorQuantization? = nil) {
        self.init(
            logicalScreenDescriptor: LogicalScreenDescriptor(
                width: width,
                height: height,
                useGlobalColorTable: globalQuantization != nil,
                colorResolution: colorResolution,
                sortFlag: false,
                sizeOfGlobalColorTable: colorResolution,
                backgroundColorIndex: 0,
                pixelAspectRatio: 0
            ),
            globalQuantization: globalQuantization
        )
    }

    public init(quantizingImage image: Image) {
        self.init(
            width: image.width,
            height: image.height,
            globalQuantization: OctreeQuantization(fromImage: image, colorCount: GIFConstants.nonTransparentColorCount)
        )
    }

    public init(data: Data) throws {
        var decoder = try GIFDecoder(data: data)
        let gif = try decoder.readGIF()
        self.init(localScreenDescriptor: gif.localScreenDescriptor, globalColorTable: gif.globalColorTable, frames: gif.frames)
    }

    public mutating func append(frame: Frame) {
        var f = frame
        if colorTable == nil {
            f.colorTable = OctreeQuantization(fromImage: f.image, colorCount: GIFConstants.colorCount)
        }
        frames.append(f)
    }

    public func encoded() throws -> Data {
        var encoder = GIFEncoder()
        encoder.append(gif: self)
        return encoder.data
    }
}
