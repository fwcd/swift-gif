import XCTest
@testable import GIF

final class IndexArrayTests: XCTestCase {
    func testIndexArray() {
        XCTAssertEqual(Array(IndexArray()), [])
        XCTAssertEqual(Array(IndexArray(42)), [42])

        var array = IndexArray()
        array.append(2)
        array.append(3)
        array.append(3)
        array.append(50)
        array.append(50)
        array.append(50)
        array.append(2)
        XCTAssertEqual(Array(array), [2, 3, 3, 50, 50, 50, 2])
    }
}
