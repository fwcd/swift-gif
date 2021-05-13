import XCTest
@testable import GIF

final class PackedFieldByteTests: XCTestCase {
    func testPackedFields() throws {
        var packed = PackedFieldByte()

        packed.append(true)
        XCTAssertEqual(packed.rawValue, 0b10000000)
        packed.append(0b001, bits: 3)
        XCTAssertEqual(packed.rawValue, 0b10010000)

        packed = packed.atHead

        XCTAssertEqual(packed.read(), true)
        XCTAssertEqual(packed.read(bits: 3), 0b001)

        var packed2 = PackedFieldByte(rawValue: 0b11101110)
        XCTAssertEqual(packed2.read(), true)
    }
}
