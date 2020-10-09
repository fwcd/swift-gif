import Foundation
import Logging
import Graphics

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
        }

        var applicationExtensions = [ApplicationExtension]()
        var frames = [Frame]()

        while true {
            var foundSomething = false

            if let applicationExtension = try readApplicationExtension() {
                applicationExtensions.append(applicationExtension)
                foundSomething = true
            }

            if let frame = try readFrame(colorResolution: logicalScreenDescriptor.colorResolution, globalQuantization: globalQuantization) {
                frames.append(frame)
                foundSomething = true
            }

            guard foundSomething else { break }
        }

        try readTrailer()

        return GIF(
            logicalScreenDescriptor: logicalScreenDescriptor,
            globalQuantization: globalQuantization,
            applicationExtensions: applicationExtensions,
            frames: frames
        )
    }

    @discardableResult
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

    @discardableResult
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
        guard let s = String(data: Data(bytes), encoding: .utf8) else { throw GIFDecodingError.invalidStringEncoding("Not a UTF-8 string: \(bytes.map { String($0, radix: 16) }.joined(separator: " "))") }
        return s
    }

    private mutating func readBytes(count: Int) throws -> [UInt8] {
        var bytes = [UInt8]()
        for _ in 0..<count {
            try bytes.append(readByte())
        }
        return bytes
    }

    private mutating func readSubBlocks() throws -> Data {
        var subData = Data()
        while let subBlockByteCount = try? readByte(), subBlockByteCount != 0x00 {
            // TODO: Improve performance by using copyBytes (or similar) and unsafe pointers?
            for _ in 0..<subBlockByteCount {
                try subData.append(readByte())
            }
        }
        return subData
    }

    private mutating func readHeader() throws {
        let header = try readString(maxLength: 6)
        guard ["GIF89a", "GIF87a"].contains(header) else { throw GIFDecodingError.invalidHeader(header) }
    }

    private mutating func readLogicalScreenDescriptor() throws -> LogicalScreenDescriptor {
        let width = try readShort()
        let height = try readShort()

        var packedField = try readPackedField()
        let useGlobalColorTable = packedField.read()
        let colorResolution = packedField.read(bits: 3)
        let sortFlag = packedField.read()
        let sizeOfGlobalColorTable = packedField.read(bits: 3)

        let backgroundColorIndex = try readByte()
        let pixelAspectRatio = try readByte()

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

    private func colorCount(colorResolution: UInt8) -> Int {
        return 1 << (UInt(colorResolution) + 1) // = 2 ^ (N + 1), see http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html#graphics_control_extension_block
    }

    private mutating func readColorTable(colorResolution: UInt8) throws -> ColorQuantization {
        var colorTable = [Color]()

        for _ in 0..<colorCount(colorResolution: colorResolution) {
            try colorTable.append(readColor())
        }

        return OctreeQuantization(fromColors: colorTable)
    }

    private mutating func readGraphicsControlExtension() throws -> GraphicsControlExtension? {
        guard try peekShort() == 0x21F9 else { return nil }
        try readShort()
        guard try readByte() == 0x04 else { throw GIFDecodingError.invalidBlockSize("in graphics control extension") }

        var packedField = try readPackedField()
        let disposalMethodRaw = packedField.read(bits: 3)
        guard let disposalMethod = DisposalMethod(rawValue: disposalMethodRaw) else { throw GIFDecodingError.invalidDisposalMethod(disposalMethodRaw) }
        let userInputFlag = packedField.read()
        let transparentColorFlag = packedField.read()

        let delayTime = try readShort()
        let backgroundColorIndex = try readByte()

        guard try readByte() == 0x00 else { throw GIFDecodingError.invalidBlockTerminator("in graphics control extension") }

        return GraphicsControlExtension(
            disposalMethod: disposalMethod,
            userInputFlag: userInputFlag,
            transparentColorFlag: transparentColorFlag,
            delayTime: delayTime,
            backgroundColorIndex: backgroundColorIndex
        )
    }

    private mutating func readImageDescriptor() throws -> ImageDescriptor? {
        guard try peekByte() == 0x2C else { return nil }
        try readByte()

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

    private mutating func readImageDataAsLZW(quantization: ColorQuantization, width: Int, height: Int, colorResolution: UInt8) throws -> Image {
        // Read beginning of image block
        let minCodeSize = try readByte()

        // Read data sub-blocks
        let lzwData = try readSubBlocks()

        // Perform actual decoding
        var lzwEncoded = BitData(from: [UInt8](lzwData))
        var decoder = LzwDecoder(colorCount: colorCount(colorResolution: colorResolution), minCodeSize: Int(minCodeSize))
        var decoded = [Int]() // holds the color indices

        try decoder.beginDecoding(from: &lzwEncoded)
        while try decoder.decodeAndAppend(from: &lzwEncoded, into: &decoded) {}

        // Decode the color indices to actual (A)RGB colors and write them into an image
        let colorTable = quantization.colorTable
        var image = try Image(width: width, height: height)

        for y in 0..<height {
            for x in 0..<width {
                image[y, x] = colorTable[decoded[(y * width) + x]]
            }
        }

        return image
    }

    private mutating func readFrame(colorResolution: UInt8, globalQuantization: ColorQuantization?) throws -> Frame? {
        let graphicsControlExtension = try readGraphicsControlExtension()
        guard let imageDescriptor = try readImageDescriptor() else {
            if graphicsControlExtension == nil {
                return nil
            } else {
                throw GIFDecodingError.missingImageDescriptor
            }
        }
        var localQuantization: ColorQuantization?

        if imageDescriptor.useLocalColorTable {
            localQuantization = try readColorTable(colorResolution: colorResolution)
        }

        guard let quantization = localQuantization ?? globalQuantization else { throw GIFDecodingError.noQuantizationForDecodingImage }
        let image = try readImageDataAsLZW(quantization: quantization, width: Int(imageDescriptor.imageWidth), height: Int(imageDescriptor.imageHeight), colorResolution: colorResolution)

        return Frame(
            image: image,
            imageDescriptor: imageDescriptor,
            graphicsControlExtension: graphicsControlExtension,
            localQuantization: localQuantization
        )
    }

    private mutating func readApplicationExtension() throws -> ApplicationExtension? {
        guard try peekShort() == 0x21FF else { return nil }
        try readShort()
        return try readLoopingExtension()
    }

    private mutating func readLoopingExtension() throws -> ApplicationExtension {
        let netscape = "NETSCAPE2.0"
        try readByte() // Skip block size
        guard try readString(maxLength: netscape.count) == netscape else { throw GIFDecodingError.invalidLoopingExtension }
        try readByte() // Skip block size
        guard try readByte() == 0x01 else { throw GIFDecodingError.invalidLoopingExtension }
        let loopCount = try readShort()
        guard try readByte() == 0x00 else { throw GIFDecodingError.invalidBlockTerminator("in looping extension") }
        return .looping(loopCount: loopCount)
    }

    private mutating func readCommentExtension() throws -> String? {
        guard try peekShort() == 0x21FE else { return nil }
        try readShort()
        guard let s = try String(data: readSubBlocks(), encoding: .utf8) else { throw GIFDecodingError.invalidStringEncoding("Could not decode comment") }
        return s
    }

    private mutating func readTrailer() throws {
        guard try readByte() == GIFConstants.trailer else { throw GIFDecodingError.invalidTrailer }
    }
}
