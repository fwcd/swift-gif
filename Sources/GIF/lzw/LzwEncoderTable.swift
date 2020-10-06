// Based on http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html

struct LzwEncoderTable: CustomStringConvertible {
    private let colorCount: Int
    // Stores the mapping from multiple indices to a single code
    private var entries: [[Int]: Int] = [:]
    public private(set) var meta: LzwTableMeta
    var description: String { "\(entries)" }

    public init(colorCount: Int) {
        meta = LzwTableMeta(colorCount: colorCount)
    }

    public subscript(indices: [Int]) -> Int? {
        if indices.count == 1 {
            // A single index matches its color code
            return indices.first
        } else {
            return entries[indices]
        }
    }

    public mutating func append(indices: [Int]) {
        assert(indices.count > 1)
        entries[indices] = meta.count
        meta.incrementCount()
    }

    public func contains(indices: [Int]) -> Bool {
        return self[indices] != nil
    }

    public mutating func reset() {
        entries = [:]
        meta.reset()
    }
}
