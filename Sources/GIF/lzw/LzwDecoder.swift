// Based on http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html
import Utils
import Logging

fileprivate let log = Logger(label: "GIF.LzwDecoder")

struct LzwDecoder {
    private(set) var table: LzwDecoderTable
    private var lastCode: Int? = nil

    public var minCodeSize: Int { return table.meta.minCodeSize }

    public init(colorCount: Int) {
        table = LzwDecoderTable(colorCount: colorCount)
    }

    public mutating func beginDecoding(from data: inout BitData) throws {
        // Read clear code
        var discarded = [Int]()
        try decodeAndAppend(from: &data, into: &discarded)
    }

    @discardableResult
    public mutating func decodeAndAppend(from data: inout BitData, into decoded: inout [Int]) throws -> Bool {
        let code = data.read(bitCount: UInt(table.meta.codeSize))
        return try decodeAndAppend(code: Int(code), into: &decoded)
    }

    private mutating func decodeAndAppend(code: Int, into decoded: inout [Int]) throws -> Bool {
        // The main LZW decoding algorithm
        guard code != table.meta.endOfInfoCode else { return false }
        if code == table.meta.clearCode {
            table.reset()
            lastCode = nil
        } else {
            if let indices = table[code] {
                decoded.append(contentsOf: indices)
                guard let k = indices.first else { throw LzwCodingError.decodedIndicesEmpty }
                log.trace("Found code: k = \(k) from \(indices) @ codeSize \(table.meta.codeSize)")
                if let lastCode = lastCode {
                    guard let lastIndices = table[lastCode] else { throw LzwCodingError.tableTooSmall }
                    table.append(indices: lastIndices + [k])
                }
            } else {
                guard let lastCode = lastCode else { throw LzwCodingError.noLastCode }
                guard let lastIndices = table[lastCode] else { throw LzwCodingError.tableTooSmall }
                guard let k = lastIndices.first else { throw LzwCodingError.decodedIndicesEmpty }
                log.trace("Did not found code: k = \(k)")
                let nextIndices = lastIndices + [k]
                decoded.append(contentsOf: nextIndices)
                table.append(indices: nextIndices)
            }
            lastCode = code
        }
        log.trace("Decoded from \(code), table: \(table) -> \(decoded) at code size \(table.meta.codeSize)")
        return true
    }
}
