struct LzwTableMeta {
    public let colorCount: Int
    public let minCodeSize: Int
    public let minCount: Int
    public let clearCode: Int
    public let endOfInfoCode: Int

    public private(set) var count: Int
    public private(set) var codeSize: Int

    public init(colorCount: Int) {
        self.colorCount = colorCount

        // Find the smallest power of two that is
        // greater than or equal to the color count
        var size = 2
        while (1 << size) < colorCount {
            size += 1
        }
        minCodeSize = size
        minCount = (1 << minCodeSize) + 2

        clearCode = 1 << minCodeSize
        endOfInfoCode = clearCode + 1
        codeSize = -1 // set in reset()
        count = -1 // set in reset()
        reset()
    }

    mutating func incrementCount() {
        if count == (1 << codeSize) {
            codeSize += 1
        }
        count += 1
    }

    mutating func reset() {
        count = minCount
        codeSize = minCodeSize + 1
    }
}
