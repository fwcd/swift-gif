import XCTest
@testable import GIF

final class LzwCoderTests: XCTestCase {
    static var allTests = [
        ("testLzwEncoder", testLzwEncoder),
        ("testLzwDecoder", testLzwDecoder)
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
        var encoded = BitData()
        var i = 0

        encoder.beginEncoding(into: &encoded)

        // Each code uses 3 bits in the output
        XCTAssertEqual(encoder.table.meta.codeSize, 3)
        XCTAssertEqual(encoder.table.meta.count, 6)

        // See http://giflib.sourceforge.net/whatsinagif/lzw_image_data.html#lzw_bytes
        // for details on this example
        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 6)
        XCTAssertEqual(encoded.bytes, [0b00000100]) // #4

        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 7)
        XCTAssertEqual(encoded.bytes, [0b00001100]) // #4 #1

        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 7)
        XCTAssertEqual(encoded.bytes, [0b00001100]) // #4 #1

        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 8)
        XCTAssertEqual(encoded.bytes, [0b10001100, 0b00000001]) // #4 #1 #6

        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 8)
        XCTAssertEqual(encoded.bytes, [0b10001100, 0b00000001]) // #4 #1 #6

        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 9)
        XCTAssertEqual(encoder.table.meta.codeSize, 4)
        XCTAssertEqual(encoded.bytes, [0b10001100, 0b00001101]) // #4 #1 #6 #6

        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 10)
        XCTAssertEqual(encoded.bytes, [0b10001100, 0b00101101, 0b00000000]) // #4 #1 #6 #6 #2

        encodeNext(with: &encoder, into: &encoded, &i)
        XCTAssertEqual(encoder.table.meta.count, 10)
        XCTAssertEqual(encoded.bytes, [0b10001100, 0b00101101, 0b00000000]) // #4 #1 #6 #6 #2
    }

    private func encodeNext(with encoder: inout LzwEncoder, into data: inout BitData, _ i: inout Int) {
        encoder.encodeAndAppend(index: indices[i], into: &data)
        i += 1
    }

    func testLzwDecoder() throws {
        var encoder = LzwEncoder(colorCount: 4)
        var encoded = BitData()

        encoder.beginEncoding(into: &encoded)
        for index in indices {
            encoder.encodeAndAppend(index: index, into: &encoded)
        }
        encoder.finishEncoding(into: &encoded)

        encoded = encoded.atHead

        var decoder = LzwDecoder(colorCount: 4)
        var decoded = [Int]()

        try decoder.beginDecoding(from: &encoded)
        for _ in 0..<indices.count {
            try decoder.decodeAndAppend(from: &encoded, into: &decoded)
        }

        XCTAssertEqual(decoded, indices)
    }
}
