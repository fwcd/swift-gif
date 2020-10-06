// Based on http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html
import Utils

struct LzwDecoderTable: CustomStringConvertible {
    // Stores the mappings from single codes to multiple indices
    private(set) var entries: [Int: [Int]] = [:]
	public var meta: LzwTableMeta
	var description: String { "\(entries)" }

    public init(colorCount: Int) {
        meta = LzwTableMeta(colorCount: colorCount)
    }

    public subscript(_ code: Int) -> [Int]? {
        if code < meta.minCount {
            return [code]
        } else {
            return entries[code]
        }
    }

    public mutating func append(indices: [Int]) {
        entries[meta.count] = indices
        meta.incrementCount()
    }

    public mutating func reset() {
        entries = [:]
        meta.reset()
    }
}
