import Foundation
import Logging
import Graphics

fileprivate let log = Logger(label: "GIF.GIFDecoder")

/// Decodes an animated from an in-memory byte buffer.
struct GIFDecoder {
    public private(set) var globalQuantization: ColorQuantization? = nil
    private var logicalScreenDescriptor: LogicalScreenDescriptor!
    private var data: Data

    public var width: UInt16 { logicalScreenDescriptor.width }
    public var height: UInt16 { logicalScreenDescriptor.height }

    public init(data: Data) throws {
        self.data = data

        try readHeader()
        logicalScreenDescriptor = try readLogicalScreenDescriptor()

        if logicalScreenDescriptor.useGlobalColorTable {
            globalQuantization = try readColorTable()
        }

        // TODO: Read extensions, image data etc
    }

    public mutating func readGIF() throws -> GIF {
        // TODO
        fatalError("TODO")
    }

    private mutating func readByte() throws -> UInt8 {
        guard let byte = data.popFirst() else { throw GIFDecodingError.noMoreBytes }
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

    private mutating func readString() throws -> String {
        var bytes = [UInt8]()
        while let byte = try? readByte(), byte != 0 {
            bytes.append(byte)
        }
        guard let s = String(data: Data(bytes), encoding: .utf8) else { throw GIFDecodingError.invalidStringEncoding }
        return s
    }

    private mutating func readHeader() throws {
        guard try readString() == "GIF89a" else { throw GIFDecodingError.invalidHeader }
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

    public mutating func readFrame() throws -> (image: Image, delayTime: Int) {
        // TODO
        fatalError("TODO")
    }

    public mutating func readTrailer() throws {
        guard try readByte() == 0x3B else { throw GIFDecodingError.invalidTrailer }
    }
}
