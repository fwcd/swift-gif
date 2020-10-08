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
            globalQuantization = try readColorTable()
        }

        var applicationExtensions = [ApplicationExtension]()
        var frames = [Frame]()

        while let frame = try readFrame() {
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

    private mutating func readColorTable() throws -> ColorQuantization {
        // TODO
        fatalError("TODO")
    }

    private mutating func readFrame() throws -> Frame? {
        // TODO
        fatalError("TODO")
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
        guard try readByte() == 0x00 else { throw GIFDecodingError.invalidBlockTerminator }
        return .looping(loopCount: loopCount)
    }

    private mutating func readTrailer() throws {
        guard try readByte() == GIFConstants.trailer else { throw GIFDecodingError.invalidTrailer }
    }
}
