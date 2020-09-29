// Based on http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html

struct LzwEncoderTable {
    private let colorCount: Int
    // Stores the mapping from multiple indices to a single code
    private var entries: [[Int]: Int] = [:]
    private(set) var codeSize: Int
    var count: Int

    public let minCodeSize: Int
    public let clearCode: Int
    public let endOfInfoCode: Int

    public init(colorCount: Int) {
        self.colorCount = colorCount

        // Find the smallest power of two that is
        // greater than or equal to the color count
        var size = 2
        while (1 << size) < colorCount {
            size += 1
        }
        minCodeSize = size

        clearCode = 1 << minCodeSize
        endOfInfoCode = clearCode + 1
        count = -1 // Will be set in reset()
        codeSize = -1 // Will be set in reset()

        reset()
    }

    public subscript(indices: [Int]) -> Int? {
        get {
            if indices.count == 1 {
                // A single index matches its color code
                return indices.first
            } else {
                return entries[indices]
            }
        }
    }

    public mutating func append(indices: [Int]) {
        assert(indices.count > 1)
        entries[indices] = count

        if count == (1 << codeSize) {
            // Increase code size
            codeSize += 1
        }

        count += 1
    }

    public func contains(indices: [Int]) -> Bool {
        return self[indices] != nil
    }

    public mutating func reset() {
        entries = [:]
        codeSize = minCodeSize + 1
        count = (1 << minCodeSize) + 2
    }
}
