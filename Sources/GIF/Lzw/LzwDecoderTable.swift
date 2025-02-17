// Based on http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html
import Utils
import Logging

fileprivate let log = Logger(label: "GIF.LzwDecoderTable")

struct LzwDecoderTable: CustomStringConvertible {
    // Stores the mappings from single codes to multiple indices
    private(set) var entries: [Int: IndexArray] = [:]
	public var meta: LzwTableMeta
	public var description: String { "\(entries)" }

    public init(colorCount: Int, minCodeSize: Int? = nil) {
        meta = LzwTableMeta(colorCount: colorCount, minCodeSize: minCodeSize)
    }

    public subscript(_ code: Int) -> IndexArray? {
        if code < meta.minCount {
            return .init(code)
        } else {
            return entries[code]
        }
    }

    public mutating func append(indices: IndexArray) {
        entries[meta.count] = indices
        log.trace("Added \(meta.count)")
        meta.incrementCount()
        meta.updateCodeSize(offset: 0)
    }

    public mutating func reset() {
        entries = [:]
        meta.reset()
    }
}
