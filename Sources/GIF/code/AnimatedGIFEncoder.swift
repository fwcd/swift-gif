import Foundation
import Logging
import Graphics
import Utils

fileprivate let log = Logger(label: "GIF.AnimatedGIFEncoder")

fileprivate let colorChannels = 3
fileprivate let transparentColorIndex: UInt8 = 0xFF
fileprivate let colorResolution: UInt8 = 0b111 // Between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)

/// Encodes an animated GIF to an in-memory byte buffer.
struct AnimatedGIFEncoder {
    private let width: UInt16
    private let height: UInt16
    private let globalQuantization: ColorQuantization?
    public private(set) var data: Data

    /// Creates a new AnimatedGIF with the specified
    /// dimensions. A loop count of 0 means infinite
    /// loops.
    public init(width: UInt16, height: UInt16, loopCount: UInt16 = 0, globalQuantization: ColorQuantization? = nil) {
        data = Data()
        self.width = width
        self.height = height
        self.globalQuantization = globalQuantization

        // See http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html for a detailed explanation of the format
        appendHeader()
        appendLogicalScreenDescriptor(useGlobalColorTable: globalQuantization != nil)

        if let quantization = globalQuantization {
            append(colorTable: quantization.colorTable)
        }

        appendLoopingApplicationExtensionBlock(loopCount: loopCount)
    }

    public init(quantizingImage image: Image) {
        self.init(width: UInt16(image.width), height: UInt16(image.height), globalQuantization: OctreeQuantization(fromImage: image, colorCount: GIFConstants.nonTransparentColorCount))
    }

    private mutating func append(byte: UInt8) {
        data.append(byte)
    }

    private mutating func append(short: UInt16) {
        data.append(UInt8(short & 0xFF))
        data.append(UInt8((short >> 8) & 0xFF))
    }

    private mutating func append(string: String) {
        data.append(string.data(using: .utf8)!)
    }

    private mutating func appendHeader() {
        append(string: "GIF89a")
    }

    private mutating func appendLogicalScreenDescriptor(useGlobalColorTable: Bool = false) {
        append(short: width)
        append(short: height)

        let sortFlag = false
        let sizeOfGlobalColorTable: UInt8 = colorResolution

        var packedField = PackedFieldByte()
        packedField.append(useGlobalColorTable)
        packedField.append(colorResolution, bits: 3)
        packedField.append(sortFlag)
        packedField.append(sizeOfGlobalColorTable, bits: 3)
        append(byte: packedField.rawValue)

        let backgroundColorIndex: UInt8 = 0
        let pixelAspectRatio: UInt8 = 0
        append(byte: backgroundColorIndex)
        append(byte: pixelAspectRatio)
    }

    private mutating func appendLoopingApplicationExtensionBlock(loopCount: UInt16) {
        append(byte: 0x21) // Extension introducer
        append(byte: 0xFF) // Application extension
        append(byte: 0x0B) // Block size
        append(string: "NETSCAPE2.0")
        append(byte: 0x03) // Block size
        append(byte: 0x01) // Loop indicator
        append(short: loopCount)
        append(byte: 0x00) // Block terminator
    }

    private mutating func appendGraphicsControlExtension(disposalMethod: UInt8, delayTime: UInt16) {
        append(byte: 0x21) // Extension introducer
        append(byte: 0xF9) // Graphics control label
        append(byte: 0x04) // Block size in bytes

        let disposalMethod = DisposalMethod.clearCanvas.rawValue
        let userInputFlag = false
        let transparentColorFlag = true

        var packedField = PackedFieldByte()
        packedField.append(0, bits: 3)
        packedField.append(disposalMethod, bits: 3)
        packedField.append(userInputFlag)
        packedField.append(transparentColorFlag)
        append(byte: packedField.rawValue)

        append(short: delayTime)
        append(byte: transparentColorIndex) // Transparent color index
        append(byte: 0x00) // Block terminator
    }

    private mutating func appendImageDescriptor(useLocalColorTable: Bool = false) {
        append(byte: 0x2C) // Image separator
        append(short: 0) // Left position
        append(short: 0) // Top position
        append(short: width)
        append(short: height)

        let interlaceFlag = false
        let sortFlag = false
        let sizeOfLocalColorTable: UInt8 = colorResolution

        var packedField = PackedFieldByte()
        packedField.append(useLocalColorTable)
        packedField.append(interlaceFlag)
        packedField.append(sortFlag)
        packedField.append(0, bits: 2)
        packedField.append(sizeOfLocalColorTable, bits: 3)
        append(byte: packedField.rawValue)
    }

    private mutating func append(colorTable: [Color]) {
        log.debug("Appending color table...")
        let maxColorBytes = GIFConstants.colorCount * colorChannels
        var i = 0

        for color in colorTable {
            append(byte: color.red)
            append(byte: color.green)
            append(byte: color.blue)
            i += colorChannels
        }

        while i < maxColorBytes {
            append(byte: 0x00)
            i += 1
        }
    }

    private func quantize(color: Color, with quantization: ColorQuantization) -> Int {
        if color.alpha < 128 {
            return Int(transparentColorIndex)
        } else {
            return quantization.quantize(color: color)
        }
    }

    private mutating func appendImageDataAsLZW(image: Image, quantization: ColorQuantization, width: Int, height: Int) {
        // Convert the ARGB-encoded image first to color
        // indices and then to LZW-compressed codes
        var encoder = LzwEncoder(colorCount: GIFConstants.colorCount)
        var lzwEncoded = BitData()

        log.debug("LZW-encoding the frame...")
        encoder.beginEncoding(into: &lzwEncoded)

        // Iterate all pixels as ARGB values and encode them
        for y in 0..<height {
            for x in 0..<width {
                encoder.encodeAndAppend(index: quantize(color: image[y, x], with: quantization), into: &lzwEncoded)
            }
        }

        encoder.finishEncoding(into: &lzwEncoded)

        log.debug("Appending the encoded frame, minCodeSize: \(encoder.minCodeSize)...")
        append(byte: UInt8(encoder.minCodeSize))

        let lzwData = lzwEncoded.bytes
        var byteIndex = 0
        while byteIndex < lzwData.count {
            let subBlockByteCount = min(0xFF, lzwData.count - byteIndex)
            append(byte: UInt8(subBlockByteCount))
            for _ in 0..<subBlockByteCount {
                append(byte: lzwData[byteIndex])
                byteIndex += 1
            }
        }

        append(byte: 0x00) // Block terminator
    }

    /// Appends a frame with the specified delay time
    /// (in hundrets of a second).
    public mutating func appendFrame(
        image: Image,
        delayTime: UInt16,
        disposalMethod: UInt8
    ) throws {
        var localQuantization: ColorQuantization? = nil

        if globalQuantization == nil {
            localQuantization = OctreeQuantization(fromImage: image, colorCount: GIFConstants.colorCount)
        }

        try appendFrame(image: image, delayTime: delayTime, localQuantization: localQuantization, disposalMethod: disposalMethod)
    }

    /// Appends a frame with the specified quantizer
    /// and delay time (in hundrets of a second).
    public mutating func appendFrame(
        image: Image,
        delayTime: UInt16,
        localQuantization: ColorQuantization? = nil,
        disposalMethod: UInt8
    ) throws {
        let frameWidth = UInt16(image.width)
        let frameHeight = UInt16(image.height)
        assert(frameWidth == width)
        assert(frameHeight == height)

        if frameWidth != width || frameHeight != height {
            throw AnimatedGIFEncodingError.frameSizeMismatch(image.width, image.height, Int(width), Int(height))
        }

        appendGraphicsControlExtension(disposalMethod: disposalMethod, delayTime: delayTime)
        appendImageDescriptor(useLocalColorTable: localQuantization != nil)

        if let quantization = localQuantization {
            append(colorTable: quantization.colorTable)
        }

        guard let quantization = localQuantization ?? globalQuantization else { fatalError("No color quantization specified for GIF frame") }
        appendImageDataAsLZW(image: image, quantization: quantization, width: image.width, height: image.height)
    }

    public mutating func appendTrailer() {
        append(byte: 0x3B)
    }
}
