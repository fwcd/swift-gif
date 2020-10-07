import XCTest
@testable import GIF

final class BitDataTests: XCTestCase {
    static var allTests = [
        ("testBitData", testBitData)
    ]

    func testBitData() throws {
        var sink1 = BitData()
        XCTAssertEqual(sink1.bytes, [0])
        sink1.write(0b11, bitCount: 2)
        XCTAssertEqual(sink1.bytes, [0b11])
        sink1.write(0b0, bitCount: 1)
        XCTAssertEqual(sink1.bytes, [0b011])
        sink1.write(0b0101, bitCount: 4)
        XCTAssertEqual(sink1.bytes, [0b0101011])
        sink1.write(0b101, bitCount: 3)
        XCTAssertEqual(sink1.bytes, [0b10101011, 0b10])

        var source1 = sink1.atHead
        XCTAssertEqual(source1.read(bitCount: 2), 0b11)
        XCTAssertEqual(source1.read(bitCount: 1), 0b0)
        XCTAssertEqual(source1.read(bitCount: 4), 0b0101)
        XCTAssertEqual(source1.read(bitCount: 3), 0b101)

        var sink2 = BitData()
        sink2.write(0xABCD, bitCount: 16)

        var source2 = sink2.atHead
        XCTAssertEqual(source2.read(bitCount: 16), 0xABCD)

        var sink3 = BitData()
        sink3.write(4, bitCount: 3)
        sink3.write(1, bitCount: 3)
        sink3.write(6, bitCount: 3)
        sink3.write(2, bitCount: 3)
        sink3.write(9, bitCount: 4)

        var source3 = sink3.atHead
        XCTAssertEqual(source3.read(bitCount: 3), 4)
        XCTAssertEqual(source3.read(bitCount: 3), 1)
        XCTAssertEqual(source3.read(bitCount: 3), 6)
        XCTAssertEqual(source3.read(bitCount: 3), 2)
        XCTAssertEqual(source3.read(bitCount: 4), 9)
    }
}
