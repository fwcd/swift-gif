struct IndexArray: Hashable {
    private var entries: [Entry]
    private(set) var count: Int

    struct Entry: Hashable {
        var value: Int
        var count: Int = 1
    }

    var first: Int? {
        entries.first?.value
    }

    var last: Int? {
        entries.last?.value
    }

    init() {
        entries = []
        count = 0
    }

    init(_ value: Int) {
        entries = [.init(value: value)]
        count = 1
    }

    mutating func append(_ value: Int) {
        if value == entries.last?.value {
            entries[entries.count - 1].count += 1
        } else {
            entries.append(.init(value: value))
        }
        count += 1
    }
}
