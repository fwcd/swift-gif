// Based on http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html
import Utils
import Logging

fileprivate let log = Logger(label: "GIF.LzwEncoder")
fileprivate let maxCodeTableCount: Int = (1 << 12) - 1

struct LzwEncoder {
    private(set) var table: LzwEncoderTable
    private var indexBuffer: [Int] = []

    public var minCodeSize: Int { table.meta.minCodeSize }

    public init(colorCount: Int) {
        table = LzwEncoderTable(colorCount: colorCount)
    }

    public mutating func beginEncoding(into data: inout BitData) {
        write(code: table.meta.clearCode, into: &data)
    }

    public mutating func encodeAndAppend(index: Int, into data: inout BitData) {
        // The main LZW encoding algorithm
        let extendedBuffer = indexBuffer + [index]
        if table.contains(indices: extendedBuffer) {
            indexBuffer = extendedBuffer
        } else {
            write(code: table[indexBuffer]!, into: &data)
            if table.meta.count >= maxCodeTableCount {
                write(code: table.meta.clearCode, into: &data)
                table.reset()
            } else {
                table.append(indices: extendedBuffer)
            }
            indexBuffer = [index]
        }
    }

    public mutating func finishEncoding(into data: inout BitData) {
        write(code: table[indexBuffer]!, into: &data)
        write(code: table.meta.endOfInfoCode, into: &data)
    }

    private mutating func write(code: Int, into data: inout BitData) {
        log.trace("Encoded to \(code), table: \(table) at code size \(table.meta.codeSize)")
        data.write(UInt(code), bitCount: UInt(table.meta.codeSize))
    }
}
