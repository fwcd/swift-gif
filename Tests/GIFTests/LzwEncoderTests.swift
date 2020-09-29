import XCTest
@testable import GIF

final class LzwEncoderTests: XCTestCase {
    static var allTests = [
        ("testLzwEncoder", testLzwEncoder)
    ]
    // Using the sample image from
    // http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html
    private let indices = [
        1, 1, 1, 1, 1, 2, 2, 2, 2, 2,
        1, 1, 1, 1, 1, 2, 2, 2, 2, 2,
        1, 1, 1, 1, 1, 2, 2, 2, 2, 2,
        1, 1, 1, 0, 0, 0, 0, 2, 2, 2,
        1, 1, 1, 0, 0, 0, 0, 2, 2, 2,
        2, 2, 2, 0, 0, 0, 0, 1, 1, 1,
        2, 2, 2, 0, 0, 0, 0, 1, 1, 1,
        2, 2, 2, 2, 2, 1, 1, 1, 1, 1,
        2, 2, 2, 2, 2, 1, 1, 1, 1, 1,
        2, 2, 2, 2, 2, 1, 1, 1, 1, 1
    ]

    func testLzwEncoder() throws {
        var encoder = LzwEncoder(colorCount: 4)
        var i = 0

        // Each code uses 3 bits in the output
        XCTAssertEqual(encoder.table.codeSize, 3)
        XCTAssertEqual(encoder.table.count, 6)

        // See http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html#lzw_bytes
        // for details on this example
        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 6)
        XCTAssertEqual(encoder.bytes, [0b00000100]) // #4

        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 7)
        XCTAssertEqual(encoder.bytes, [0b00001100]) // #4 #1

        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 7)
        XCTAssertEqual(encoder.bytes, [0b00001100]) // #4 #1

        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 8)
        XCTAssertEqual(encoder.bytes, [0b10001100, 0b00000001]) // #4 #1 #6

        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 8)
        XCTAssertEqual(encoder.bytes, [0b10001100, 0b00000001]) // #4 #1 #6

        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 9)
        XCTAssertEqual(encoder.table.codeSize, 4)
        XCTAssertEqual(encoder.bytes, [0b10001100, 0b00001101]) // #4 #1 #6 #6

        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 10)
        XCTAssertEqual(encoder.bytes, [0b10001100, 0b00101101, 0b00000000]) // #4 #1 #6 #6 #2

        encodeNext(&encoder, &i)
        XCTAssertEqual(encoder.table.count, 10)
        XCTAssertEqual(encoder.bytes, [0b10001100, 0b00101101, 0b00000000]) // #4 #1 #6 #6 #2
    }

    private func encodeNext(_ encoder: inout LzwEncoder, _ i: inout Int) {
        encoder.encodeAndAppend(index: indices[i])
        i += 1
    }
}
