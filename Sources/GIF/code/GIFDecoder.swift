import Foundation
import Logging
import Graphics
import Utils

fileprivate let log = Logger(label: "GIF.GIFDecoder")

/// Decodes an animated from an in-memory byte buffer.
struct GIFDecoder {
    private var data: Data

    public init(data: Data) throws {
        self.data = data
    }

    public mutating func readGIF() throws -> GIF {
        try readHeader()

        let logicalScreenDescriptor = try readLogicalScreenDescriptor()
        var globalQuantization: ColorQuantization? = nil

        if logicalScreenDescriptor.useGlobalColorTable {
            globalQuantization = try readColorTable(colorResolution: logicalScreenDescriptor.colorResolution)
        } else {
            log.trace("No global color table!")
        }

        var applicationExtensions = [ApplicationExtension]()
        var commentExtensions = [String]()
        var frames = [Frame]()

        while try peekByte() != GIFConstants.trailer {
            var foundSomething = false

            if let applicationExtension = try readApplicationExtension() {
                applicationExtensions.append(applicationExtension)
                foundSomething = true
            } else if let commentExtension = try readCommentExtension() {
                commentExtensions.append(commentExtension)
                foundSomething = true
            } else if let frame = try readFrame(colorResolution: logicalScreenDescriptor.colorResolution, globalQuantization: globalQuantization, backgroundColorIndex: logicalScreenDescriptor.backgroundColorIndex) {
                frames.append(frame)
                foundSomething = true
            }

            guard foundSomething else { throw GIFDecodingError.unrecognizedBlock("Did not recognize this block: \(data.prefix(8).hexString)...") }
        }

        try readTrailer()

        log.debug("Read GIF")

        return GIF(
            logicalScreenDescriptor: logicalScreenDescriptor,
            globalQuantization: globalQuantization,
            applicationExtensions: applicationExtensions,
            commentExtensions: commentExtensions,
            frames: frames
        )
    }

    private mutating func readByte() throws -> UInt8 {
        guard let byte = data.popFirst() else { throw GIFDecodingError.noMoreBytes }
        return byte
    }

    private func peekByte() throws -> UInt8 {
        guard let byte = data.first else { throw GIFDecodingError.noMoreBytes }
        return byte
    }

    private mutating func readPackedField() throws -> PackedFieldByte {
        try PackedFieldByte(rawValue: readByte())
    }

    private mutating func readShort() throws -> UInt16 {
        let lower = try readByte()
        let higher = try readByte()
        return (UInt16(higher) << 8) | UInt16(lower)
    }

    private func peekShort() throws -> UInt16 {
        let lower = try peekByte()
        let higher = try peekByte()
        return (UInt16(higher) << 8) | UInt16(lower)
    }

    private mutating func readColor() throws -> Color {
        let red = try readByte()
        let green = try readByte()
        let blue = try readByte()
        return Color(red: red, green: green, blue: blue)
    }

    private mutating func readString(maxLength: Int = Int.max) throws -> String {
        var bytes = [UInt8]()
        while let byte = try? readByte(), byte != 0 {
            bytes.append(byte)
            if bytes.count >= maxLength {
                break
            }
        }
        guard let s = String(data: Data(bytes), encoding: .utf8) else { throw GIFDecodingError.invalidStringEncoding("Not a UTF-8 string: \(bytes.hexString)") }
        return s
    }

    private mutating func skipByte() throws {
        try skipBytes(count: 1)
    }

    private mutating func skipBytes(count: Int) throws {
        guard data.count >= count else { throw GIFDecodingError.noMoreBytes }
        data.removeFirst(count)
    }

    private func peekBytes(count: Int) throws -> [UInt8] {
        guard data.count >= count else { throw GIFDecodingError.noMoreBytes }
        return [UInt8](data.prefix(count))
    }

    private mutating func readBytes(count: Int) throws -> [UInt8] {
        var bytes = [UInt8]()
        for _ in 0..<count {
            try bytes.append(readByte())
        }
        return bytes
    }

    private mutating func readSubBlocks() throws -> Data {
        log.trace("Reading data sub-blocks...")

        var subData = Data()
        while let subBlockByteCount = try? readByte(), subBlockByteCount != 0x00 {
            // TODO: Improve performance by using copyBytes (or similar) and unsafe pointers?
            for _ in 0..<subBlockByteCount {
                try subData.append(readByte())
            }
        }

        log.debug("Read data sub-blocks...")
        return subData
    }

    private mutating func readHeader() throws {
        log.trace("Reading header...")

        let header = try readString(maxLength: 6)
        guard ["GIF89a", "GIF87a"].contains(header) else { throw GIFDecodingError.invalidHeader(header) }

        log.debug("Read header (\(header))")
    }

    private mutating func readLogicalScreenDescriptor() throws -> LogicalScreenDescriptor {
        log.trace("Reading logical screen descriptor...")

        let width = try readShort()
        let height = try readShort()

        var packedField = try readPackedField()
        let useGlobalColorTable = packedField.read()
        let colorResolution = packedField.read(bits: 3)
        let sortFlag = packedField.read()
        let sizeOfGlobalColorTable = packedField.read(bits: 3)

        let backgroundColorIndex = try readByte()
        let pixelAspectRatio = try readByte()

        log.debug("Read logical screen descriptor (width: \(width), height: \(height), global color table: \(useGlobalColorTable), color resolution: \(String(colorResolution, radix: 2)), bg color index: \(backgroundColorIndex))")

        return LogicalScreenDescriptor(
            width: width,
            height: height,
            useGlobalColorTable: useGlobalColorTable,
            colorResolution: colorResolution,
            sortFlag: sortFlag,
            sizeOfGlobalColorTable: sizeOfGlobalColorTable,
            backgroundColorIndex: backgroundColorIndex,
            pixelAspectRatio: pixelAspectRatio
        )
    }

    private mutating func readColorTable(colorResolution: UInt8) throws -> ColorQuantization {
        log.trace("Reading color table...")

        var colorTable = [Color]()

        for _ in 0..<colorTableSizeOf(colorResolution: colorResolution) {
            try colorTable.append(readColor())
        }

        log.debug("Read color table (\(colorTable.count) colors)")

        return OctreeQuantization(fromColors: colorTable)
    }

    private mutating func readGraphicsControlExtension() throws -> GraphicsControlExtension? {
        guard try peekBytes(count: 2) == [GIFConstants.extensionIntroducer, GIFConstants.graphicsControlExtension] else { return nil }
        try skipBytes(count: 2)
        guard try readByte() == 0x04 else { throw GIFDecodingError.invalidBlockSize("in graphics control extension") }

        log.trace("Reading graphics control extension...")

        var packedField = try readPackedField()
        packedField.skip(bits: 3)
        let disposalMethodRaw = packedField.read(bits: 3)
        guard let disposalMethod = DisposalMethod(rawValue: disposalMethodRaw) else { throw GIFDecodingError.invalidDisposalMethod(disposalMethodRaw) }
        let userInputFlag = packedField.read()
        let transparentColorFlag = packedField.read()

        let delayTime = try readShort()
        let backgroundColorIndex = try readByte()

        guard try readByte() == 0x00 else { throw GIFDecodingError.invalidBlockTerminator("in graphics control extension") }

        log.debug("Read graphics control extension (disposal method: \(disposalMethod), delay time: \(delayTime), transparent: \(transparentColorFlag))")

        return GraphicsControlExtension(
            disposalMethod: disposalMethod,
            userInputFlag: userInputFlag,
            transparentColorFlag: transparentColorFlag,
            delayTime: delayTime,
            backgroundColorIndex: backgroundColorIndex
        )
    }

    private mutating func readImageDescriptor() throws -> ImageDescriptor? {
        guard try peekByte() == GIFConstants.imageSeparator else { return nil }
        try skipByte()

        log.trace("Reading image descriptor...")

        let imageLeft = try readShort()
        let imageTop = try readShort()
        let imageWidth = try readShort()
        let imageHeight = try readShort()

        var packedField = try readPackedField()
        let useLocalColorTable = packedField.read()
        let interlaceFlag = packedField.read()
        let sortFlag = packedField.read()
        packedField.skip(bits: 2)
        let sizeOfLocalColorTable = packedField.read(bits: 3)

        log.debug("Read image descriptor (left: \(imageLeft), top: \(imageTop), width: \(imageWidth), height: \(imageHeight), local color table: \(useLocalColorTable)))")

        return ImageDescriptor(
            imageLeft: imageLeft,
            imageTop: imageTop,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            useLocalColorTable: useLocalColorTable,
            interlaceFlag: interlaceFlag,
            sortFlag: sortFlag,
            sizeOfLocalColorTable: sizeOfLocalColorTable
        )
    }

    private mutating func readImageDataAsLZW(
        quantization: ColorQuantization,
        width: Int,
        height: Int,
        colorResolution: UInt8,
        backgroundColorIndex: UInt8
    ) throws -> Image {
        log.debug("Reading image data...")

        // Read beginning of image block
        let minCodeSize = try readByte()

        // Read data sub-blocks
        let lzwData = try readSubBlocks()

        // Perform actual decoding
        var lzwEncoded = BitData(from: [UInt8](lzwData))
        var decoder = LzwDecoder(colorCount: colorTableSizeOf(colorResolution: colorResolution), minCodeSize: Int(minCodeSize))
        var decoded = [Int]() // holds the color indices

        log.debug("LZW-decoding the image data (min code size: \(minCodeSize))...")
        try decoder.beginDecoding(from: &lzwEncoded)
        while try decoder.decodeAndAppend(from: &lzwEncoded, into: &decoded) {}

        // Decode the color indices to actual (A)RGB colors and write them into an image
        let colorTable = quantization.colorTable
        var image = try Image(width: width, height: height)

        assert(decoded.count >= width * height)
        log.debug("Decoded image data \(decoded.prefix(10).map(UInt8.init).hexString)...")

        for y in 0..<height {
            for x in 0..<width {
                let colorIndex = decoded[(y * width) + x]
                let isTransparent = colorIndex == backgroundColorIndex
                assert(isTransparent || colorIndex < colorTable.count, "Color index #\(colorIndex) is too large for color table of size \(colorTable.count) (note: background color index is #\(backgroundColorIndex))")
                image[y, x] = isTransparent ? Colors.transparent : colorTable[colorIndex]
            }
        }

        log.debug("Read image data (\(lzwData.count) bytes LZW-encoded, \(width * height) pixels)")

        return image
    }

    private mutating func readFrame(
        colorResolution: UInt8,
        globalQuantization: ColorQuantization?,
        backgroundColorIndex: UInt8
    ) throws -> Frame? {
        let graphicsControlExtension = try readGraphicsControlExtension()
        guard let imageDescriptor = try readImageDescriptor() else {
            if graphicsControlExtension == nil {
                return nil
            } else {
                throw GIFDecodingError.missingImageDescriptor
            }
        }

        log.trace("Reading frame...")

        let actualBackgroundColorIndex = (graphicsControlExtension?.backgroundColorIndex).filter { _ in imageDescriptor.useLocalColorTable } ?? backgroundColorIndex
        var localQuantization: ColorQuantization?

        if imageDescriptor.useLocalColorTable {
            localQuantization = try readColorTable(colorResolution: colorResolution)
        } else {
            log.trace("No local color table!")
        }

        guard let quantization = localQuantization ?? globalQuantization else { throw GIFDecodingError.noQuantizationForDecodingImage }
        let image = try readImageDataAsLZW(quantization: quantization, width: Int(imageDescriptor.imageWidth), height: Int(imageDescriptor.imageHeight), colorResolution: colorResolution, backgroundColorIndex: actualBackgroundColorIndex)

        log.debug("Read frame")

        return Frame(
            image: image,
            imageDescriptor: imageDescriptor,
            graphicsControlExtension: graphicsControlExtension,
            localQuantization: localQuantization
        )
    }

    private mutating func readApplicationExtension() throws -> ApplicationExtension? {
        guard try peekBytes(count: 2) == [GIFConstants.extensionIntroducer, GIFConstants.applicationExtension] else { return nil }
        try skipBytes(count: 2)
        return try readLoopingExtension()
    }

    private mutating func readLoopingExtension() throws -> ApplicationExtension {
        let blockSize = try readByte() // Block size
        let s = try readString(maxLength: Int(blockSize))
        guard s == "NETSCAPE2.0" else { throw GIFDecodingError.invalidLoopingExtension(s) }
        guard try readByte() == 0x03 else { throw GIFDecodingError.invalidBlockSize("too much data in looping extension") }
        guard try readByte() == 0x01 else { throw GIFDecodingError.invalidBlockSize("looping extension should only contain 1 data sub-block") }
        let loopCount = try readShort()
        guard try readByte() == 0x00 else { throw GIFDecodingError.invalidBlockTerminator("in looping extension") }
        return .looping(loopCount: loopCount)
    }

    private mutating func readCommentExtension() throws -> String? {
        guard try peekBytes(count: 2) == [GIFConstants.extensionIntroducer, GIFConstants.commentExtension] else { return nil }
        try skipBytes(count: 2)
        guard let s = try String(data: readSubBlocks(), encoding: .utf8) else { throw GIFDecodingError.invalidStringEncoding("Could not decode comment") }
        return s
    }

    private mutating func readTrailer() throws {
        let trailer = try peekByte()
        guard trailer == GIFConstants.trailer else { throw GIFDecodingError.invalidTrailer("Remaining bytes: \(data.truncated(to: 4).hexString)...") }
        try skipByte()
    }
}
