import Foundation
import Logging
import CairoGraphics
import Utils

fileprivate let log = Logger(label: "GIF.GIFEncoder")

/// Encodes an animated GIF to an in-memory byte buffer.
struct GIFEncoder {
    public private(set) var data: Data

    private static let frameEncodingQueue = DispatchQueue(label: "GIF.GIFEncoder.frameEncodingQueue")

    /// Creates a new GIF with the specified
    /// dimensions. A loop count of 0 means infinite
    /// loops.
    public init() {
        data = Data()
    }

    public mutating func append(gif: GIF) throws {
        // See http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html for a detailed explanation of the format
        appendHeader()
        append(logicalScreenDescriptor: gif.logicalScreenDescriptor)

        if let quantization = gif.globalQuantization {
            append(colorTable: quantization.colorTable, size: gif.logicalScreenDescriptor.sizeOfGlobalColorTable)
        }

        for applicationExtension in gif.applicationExtensions {
            append(applicationExtension: applicationExtension)
        }

        // TODO: Encode comment extensions

        var numCores: Int = ProcessInfo.processInfo.processorCount
        let frames = gif.frames
    
        numCores = min(numCores, frames.count)
        var encoders: [GIFEncoder] = []
        for _ in 0..<frames.count {
            encoders.append(GIFEncoder())
        }
        var finishedFrameCount: Int = numCores
    
        let encodeFrames: (Int) -> Void = { z in
            var i = z
            while true {
                let getEncoder = { () -> (GIFEncoder?, Int?) in
                    if i > numCores {
                        if finishedFrameCount >= frames.count {
                            return (nil, nil)
                        }
                        let output = encoders[finishedFrameCount]
                        let encoderID = finishedFrameCount
                        finishedFrameCount += 1
                        return (output, encoderID)
                    } else {
                        return (encoders[i], i)
                    }
                }
                let (encoder, encoderID) = GIFEncoder.frameEncodingQueue.sync(execute: getEncoder)
                defer {
                    i = numCores + 1
                }
                guard var encoder, let encoderID else {
                    break
                }

                encoder.append(frame: frames[encoderID], globalQuantization: gif.globalQuantization, sizeOfGlobalColorTable: gif.logicalScreenDescriptor.sizeOfGlobalColorTable, backgroundColorIndex: gif.logicalScreenDescriptor.backgroundColorIndex)

                GIFEncoder.frameEncodingQueue.sync {
                    encoders[encoderID] = encoder
                }
            }
        }
        if frames.count <= 1 {
            encodeFrames(0)
        } else {
            DispatchQueue.concurrentPerform(iterations: numCores, execute: encodeFrames)
        }

        for encoder in encoders {
            self.data.append(encoder.data)
        }

        appendTrailer()

        log.debug("Appended GIF")
    }

    private mutating func append(byte: UInt8) {
        data.append(byte)
    }

    private mutating func append(packedField: PackedFieldByte) {
        append(byte: packedField.rawValue)
    }

    private mutating func append(short: UInt16) {
        data.append(UInt8(short & 0xFF))
        data.append(UInt8((short >> 8) & 0xFF))
    }

    private mutating func append(string: String) {
        // TODO: Use proper throws + exception here
        data.append(string.data(using: .utf8)!)
    }

    private mutating func append(color: Color) {
        append(byte: color.red)
        append(byte: color.green)
        append(byte: color.blue)
    }

    private mutating func appendHeader() {
        append(string: "GIF89a")

        log.debug("Appended header")
    }

    private mutating func append(logicalScreenDescriptor: LogicalScreenDescriptor) {
        append(short: logicalScreenDescriptor.width)
        append(short: logicalScreenDescriptor.height)

        var packedField = PackedFieldByte()
        packedField.append(logicalScreenDescriptor.useGlobalColorTable)
        packedField.append(logicalScreenDescriptor.colorResolution, bits: 3)
        packedField.append(logicalScreenDescriptor.sortFlag)
        packedField.append(logicalScreenDescriptor.sizeOfGlobalColorTable, bits: 3)
        append(packedField: packedField)

        append(byte: logicalScreenDescriptor.backgroundColorIndex)
        append(byte: logicalScreenDescriptor.pixelAspectRatio)

        log.debug("Appended logical screen descriptor")
    }

    private mutating func append(applicationExtension: ApplicationExtension) {
        switch applicationExtension {
            case .looping(let loopCount):
                append(byte: GIFConstants.extensionIntroducer)
                append(byte: GIFConstants.applicationExtension)
                append(byte: 0x0B) // Block size
                append(string: "NETSCAPE2.0")
                append(byte: 0x03) // Block size
                append(byte: 0x01) // Loop indicator
                append(short: loopCount)
                append(byte: 0x00) // Block terminator
        }

        log.debug("Appended application extension")
    }

    private mutating func append(graphicsControlExtension: GraphicsControlExtension) {
        append(byte: GIFConstants.extensionIntroducer)
        append(byte: GIFConstants.graphicsControlExtension)
        append(byte: 0x04) // Block size in bytes

        var packedField = PackedFieldByte()
        packedField.append(0, bits: 3)
        packedField.append(graphicsControlExtension.disposalMethod.rawValue, bits: 3)
        packedField.append(graphicsControlExtension.userInputFlag)
        packedField.append(graphicsControlExtension.transparentColorFlag)
        append(packedField: packedField)

        append(short: graphicsControlExtension.delayTime)
        append(byte: graphicsControlExtension.backgroundColorIndex) // Transparent color index
        append(byte: 0x00) // Block terminator

        log.debug("Appended graphics control extension")
    }

    private mutating func append(imageDescriptor: ImageDescriptor) {
        append(byte: GIFConstants.imageSeparator)
        append(short: imageDescriptor.imageLeft)
        append(short: imageDescriptor.imageTop)
        append(short: imageDescriptor.imageWidth)
        append(short: imageDescriptor.imageHeight)

        var packedField = PackedFieldByte()
        packedField.append(imageDescriptor.useLocalColorTable)
        packedField.append(imageDescriptor.interlaceFlag)
        packedField.append(imageDescriptor.sortFlag)
        packedField.append(0, bits: 2)
        packedField.append(imageDescriptor.sizeOfLocalColorTable, bits: 3)
        append(packedField: packedField)

        log.debug("Appended image descriptor")
    }

    private mutating func append(colorTable: [Color], size: UInt8) {
        log.debug("Appending color table...")

        let maxColorBytes = colorTableCountOf(size: size) * GIFConstants.colorChannels
        var i = 0

        for color in colorTable {
            append(color: color)
            i += GIFConstants.colorChannels
        }

        while i < maxColorBytes {
            append(byte: 0x00)
            i += 1
        }

        log.debug("Appended color table")
    }

    private func quantize(color: Color, with quantization: ColorQuantization, backgroundColorIndex: UInt8) -> Int {
        if color.alpha < 128 {
            return Int(backgroundColorIndex) // Use transparent color
        } else {
            return quantization.quantize(color: color)
        }
    }

    private mutating func appendImageDataAsLZW(
        image: CairoImage,
        quantization: ColorQuantization,
        width: Int,
        height: Int,
        backgroundColorIndex: UInt8
    ) {
        log.debug("Appending image data...")

        // Convert the ARGB-encoded image first to color
        // indices and then to LZW-compressed codes
        var encoder = LzwEncoder(colorCount: GIFConstants.colorCount)
        var lzwEncoded = BitData()

        log.debug("LZW-encoding the image data...")
        encoder.beginEncoding(into: &lzwEncoded)

        // Iterate all pixels as ARGB values and encode them
        for y in 0..<height {
            for x in 0..<width {
                encoder.encodeAndAppend(index: quantize(color: image[y, x], with: quantization, backgroundColorIndex: backgroundColorIndex), into: &lzwEncoded)
            }
        }

        encoder.finishEncoding(into: &lzwEncoded)

        log.debug("Appending the encoded image data (min code size: \(encoder.minCodeSize))...")
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

        log.debug("Appended image data")
    }

    /// Appends a frame with the specified quantizer
    /// and delay time (in hundrets of a second).
    private mutating func append(
        frame: Frame,
        globalQuantization: ColorQuantization? = nil,
        sizeOfGlobalColorTable: UInt8,
        backgroundColorIndex: UInt8
    ) {
        let image = frame.image
        let sizeOfColorTable = frame.imageDescriptor.useLocalColorTable ? frame.imageDescriptor.sizeOfLocalColorTable : sizeOfGlobalColorTable
        var actualBackgroundColorIndex = backgroundColorIndex

        if let graphicsControlExtension = frame.graphicsControlExtension {
            append(graphicsControlExtension: graphicsControlExtension)

            if frame.imageDescriptor.useLocalColorTable {
                actualBackgroundColorIndex = graphicsControlExtension.backgroundColorIndex
            }
        }

        append(imageDescriptor: frame.imageDescriptor)

        if let quantization = frame.localQuantization {
            append(colorTable: quantization.colorTable, size: sizeOfColorTable)
        }

        guard let quantization = frame.localQuantization ?? globalQuantization else { fatalError("No color quantization specified for GIF frame") }
        appendImageDataAsLZW(image: image, quantization: quantization, width: image.width, height: image.height, backgroundColorIndex: actualBackgroundColorIndex)

        log.debug("Appended frame")
    }

    private mutating func appendTrailer() {
        append(byte: GIFConstants.trailer)

        log.debug("Appended trailer")
    }
}
