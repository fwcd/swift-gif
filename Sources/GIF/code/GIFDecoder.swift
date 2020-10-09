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

        while let frame = try readFrame(colorResolution: logicalScreenDescriptor.colorResolution, globalQuantization: globalQuantization) {
            frames.append(frame)
        }

        while let applicationExtension = try readApplicationExtension() {
            applicationExtensions.append(applicationExtension)
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

    private mutating func readPackedField() throws -> PackedFieldByte {
        try PackedFieldByte(rawValue: readByte())
    }

    @discardableResult
    private mutating func readShort() throws -> UInt16 {
        let lower = try readByte()
        let higher = try readByte()
        return (UInt16(higher) << 8) | UInt16(lower)
    }

    private mutating func readColor() throws -> Color {
        let red = try readByte()
        let green = try readByte()
        let blue = try readByte()
        return Color(red: red, green: green, blue: blue)
    }

    private mutating func readString() throws -> String {
        var bytes = [UInt8]()
        while let byte = try? readByte(), byte != 0 {
            bytes.append(byte)
        }
        guard let s = String(data: Data(bytes), encoding: .utf8) else { throw GIFDecodingError.invalidStringEncoding }
        return s
    }

    private mutating func readBytes(count: Int) throws -> [UInt8] {
        var bytes = [UInt8]()
        for _ in 0..<count {
            try bytes.append(readByte())
        }
        return bytes
    }

    private mutating func readHeader() throws {
        guard try ["GIF89a", "GIF87a"].contains(readString()) else { throw GIFDecodingError.invalidHeader }
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

    private mutating func readColorTable(colorResolution: UInt8) throws -> ColorQuantization {
        let colorCount = 1 << (UInt(colorResolution) + 1) // = 2 ^ (N + 1), see http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html#graphics_control_extension_block
        var colorTable = [Color]()

        for _ in 0..<colorCount {
            try colorTable.append(readColor())
        }

        return OctreeQuantization(fromColors: colorTable)
    }

    private mutating func readGraphicsControlExtension() throws -> GraphicsControlExtension {
        guard try readBytes(count: 2) == [0x21, 0xF9] else { throw GIFDecodingError.invalidGraphicsControlExtension }
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

    private mutating func readImageDescriptor() throws -> ImageDescriptor {
        // TODO
        fatalError("TODO")
    }

    private mutating func readImageDataAsLZW(quantization: ColorQuantization, width: Int, height: Int) throws -> Image {
        // TODO
        fatalError("TODO")
    }

    private mutating func readFrame(colorResolution: UInt8, globalQuantization: ColorQuantization?) throws -> Frame? {
        let graphicsControlExtension = try? readGraphicsControlExtension()
        let imageDescriptor = try readImageDescriptor()
        var localQuantization: ColorQuantization?

        if imageDescriptor.useLocalColorTable {
            localQuantization = try readColorTable(colorResolution: colorResolution)
        }

        guard let quantization = localQuantization ?? globalQuantization else { throw GIFDecodingError.noQuantizationForDecodingImage }
        let image = try readImageDataAsLZW(quantization: quantization, width: Int(imageDescriptor.imageWidth), height: Int(imageDescriptor.imageHeight))

        return Frame(
            image: image,
            imageDescriptor: imageDescriptor,
            graphicsControlExtension: graphicsControlExtension,
            localQuantization: localQuantization
        )
    }

    private mutating func readApplicationExtension() throws -> ApplicationExtension? {
        guard try readShort() == 0x21FF else { return nil }
        return try? readLoopingExtension()
    }

    private mutating func readLoopingExtension() throws -> ApplicationExtension {
        try readByte() // Skip block size
        guard try readString() == "NETSCAPE2.0" else { throw GIFDecodingError.invalidLoopingExtension }
        try readByte() // Skip block size
        guard try readByte() == 0x01 else { throw GIFDecodingError.invalidLoopingExtension }
        let loopCount = try readShort()
        guard try readByte() == 0x00 else { throw GIFDecodingError.invalidBlockTerminator("in looping extension") }
        return .looping(loopCount: loopCount)
    }

    private mutating func readTrailer() throws {
        guard try readByte() == GIFConstants.trailer else { throw GIFDecodingError.invalidTrailer }
    }
}
