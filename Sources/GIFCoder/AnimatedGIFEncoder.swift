import Foundation
import Logging
import Utils

fileprivate let log = Logger(label: "GIFCoder.AnimatedGIFEncoder")

public let gifColorCount = 256
public let gifNonTransparentColorCount = gifColorCount - 1
fileprivate let colorChannels = 3
fileprivate let transparentColorIndex: UInt8 = 0xFF
fileprivate let colorResolution: UInt8 = 0b111 // Between 0 and 8 (exclusive) -> Will be interpreted as (bits per pixel - 1)

/**
 * A GIF-encoder that supports
 * (looping) animations written in
 * pure Swift.
 */
public struct AnimatedGIFEncoder {
    private let width: UInt16
    private let height: UInt16
    private let globalQuantization: ColorQuantization?
    public private(set) var data: Data

    /**
    * Creates a new AnimatedGIF with the specified
    * dimensions. A loop count of 0 means infinite
    * loops.
    */
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
        self.init(width: UInt16(image.width), height: UInt16(image.height), globalQuantization: OctreeQuantization(fromImage: image, colorCount: gifNonTransparentColorCount))
    }

    // Determines how an AnimatedGIF should
    // move on to the next frame
    public enum DisposalMethod: UInt8 {
        case keepCanvas = 1
        case clearCanvas = 2
        case restoreCanvas = 3
    }

    struct PackedFieldByte {
        private(set) var rawValue: UInt8 = 0
        private var bitIndex: Int = 0

        private subscript(_ bitIndex: Int) -> UInt8 {
            get { return (rawValue >> (7 - bitIndex)) }
            set(newValue) { rawValue = rawValue | (newValue << (7 - bitIndex)) }
        }

        /**
        * Appends a value to the bitfield
        * by converting it to little-endian
        * and masking it.
        */
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

    private mutating func appendGraphicsControlExtension(disposalMethod: DisposalMethod, delayTime: UInt16) {
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
        let maxColorBytes = gifColorCount * colorChannels
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

    private mutating func appendImageDataAsLZW(frame: Image, quantization: ColorQuantization, width: Int, height: Int) {
        // Convert the ARGB-encoded image first to color
        // indices and then to LZW-compressed codes
        var encoder = LzwEncoder(colorCount: gifColorCount)

        log.debug("LZW-encoding the frame...")
        // Iterate all pixels as ARGB values and encode them
        for y in 0..<height {
            for x in 0..<width {
                encoder.encodeAndAppend(index: quantize(color: frame[y, x], with: quantization))
            }
        }
        encoder.finishEncoding()

        log.debug("Appending the encoded frame, minCodeSize: \(encoder.minCodeSize)...")
        append(byte: UInt8(encoder.minCodeSize))

        let lzwEncoded = encoder.bytes
        var byteIndex = 0
        while byteIndex < lzwEncoded.count {
            let subBlockByteCount = min(0xFF, lzwEncoded.count - byteIndex)
            append(byte: UInt8(subBlockByteCount))
            for _ in 0..<subBlockByteCount {
                append(byte: lzwEncoded[byteIndex])
                byteIndex += 1
            }
        }

        append(byte: 0x00) // Block terminator
    }

    /**
    * Appends a frame with the specified delay time
    * (in hundrets of a second).
    */
    public mutating func append(frame: Image, delayTime: UInt16, disposalMethod: DisposalMethod = .clearCanvas) throws {
        var localQuantization: ColorQuantization? = nil

        if globalQuantization == nil {
            localQuantization = OctreeQuantization(fromImage: frame, colorCount: gifColorCount)
        }

        try append(frame: frame, localQuantization: localQuantization, delayTime: delayTime, disposalMethod: disposalMethod)
    }

    /**
    * Appends a frame with the specified quantizer
    * and delay time (in hundrets of a second).
    */
    public mutating func append(frame: Image, localQuantization: ColorQuantization? = nil, delayTime: UInt16, disposalMethod: DisposalMethod = .clearCanvas) throws {
        let frameWidth = UInt16(frame.width)
        let frameHeight = UInt16(frame.height)
        assert(frameWidth == width)
        assert(frameHeight == height)

        if frameWidth != width || frameHeight != height {
            throw AnimatedGIFError.frameSizeMismatch(frame.width, frame.height, Int(width), Int(height))
        }

        appendGraphicsControlExtension(disposalMethod: disposalMethod, delayTime: delayTime)
        appendImageDescriptor(useLocalColorTable: localQuantization != nil)

        if let quantization = localQuantization {
            append(colorTable: quantization.colorTable)
        }

        guard let quantization = localQuantization ?? globalQuantization else { fatalError("No color quantization specified for GIF frame") }
        appendImageDataAsLZW(frame: frame, quantization: quantization, width: frame.width, height: frame.height)
    }

    public mutating func appendTrailer() {
        append(byte: 0x3B)
    }
}
