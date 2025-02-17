struct IndexArray: Hashable, Sequence {
    typealias Element = Int

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

    mutating func append(contentsOf array: IndexArray) {
        if let lastEntry = entries.last, let firstEntry = array.entries.first, lastEntry.value == firstEntry.value {
            entries[entries.count - 1].count += firstEntry.count
            entries += array.entries.dropFirst()
        } else {
            entries += array.entries
        }
    }

    func makeIterator() -> Iterator {
        Iterator(self)
    }

    struct Iterator: IteratorProtocol {
        private let array: IndexArray
        private var entryIndex = 0
        private var valueIndex = 0

        private var entry: Entry {
            array.entries[entryIndex]
        }

        fileprivate init(_ array: IndexArray) {
            self.array = array
        }

        mutating func next() -> Element? {
            guard entryIndex < array.entries.count else {
                return nil
            }
            let value = entry.value
            if valueIndex >= entry.count - 1 {
                valueIndex = 0
                entryIndex += 1
            } else {
                valueIndex += 1
            }
            return value
        }
    }
}
