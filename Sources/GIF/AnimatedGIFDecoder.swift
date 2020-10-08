import Foundation
import Logging
import Graphics

fileprivate let log = Logger(label: "GIF.AnimatedGIFDecoder")

/// Decodes an animated from an in-memory byte buffer.
struct AnimatedGIFDecoder {
    public let width: Int!
    public let height: Int!
    public let globalQuantization: ColorQuantization?
    private var data: Data

    public init(data: Data) throws {
        self.data = data

        // TODO
        width = -1
        height = -1
        globalQuantization = nil
    }

    private mutating func readByte() throws -> UInt8 {
        guard let byte = data.popFirst() else { throw AnimatedGIFDecodingError.noMoreBytes }
        return byte
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
        guard let s = String(data: Data(bytes), encoding: .utf8) else { throw AnimatedGIFDecodingError.invalidStringEncoding }
        return s
    }

    private mutating func readHeader() throws {
        guard try readString() == "GIF89a" else { throw AnimatedGIFDecodingError.invalidHeader }
    }

    private mutating func readLogicalScreenDescriptor() throws {
        // TODO
    }

    public mutating func readFrame() throws -> (image: Image, delayTime: Int) {
        // TODO
        fatalError("TODO")
    }

    public mutating func readTrailer() throws {
        guard try readByte() == 0x3B else { throw AnimatedGIFDecodingError.invalidTrailer }
    }
}
