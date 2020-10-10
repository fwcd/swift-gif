import XCTest
import Logging
@testable import GIF

fileprivate let log = Logger(label: "GIFTests.GIFCoderTests")

final class GIFCoderTests: XCTestCase {
    static var allTests = [
        ("testGIFCoder", testGIFCoder)
    ]

    func testGIFCoder() throws {
        for resource in ["mini", "mandelbrot"] {
            log.info("Testing GIF en-/decoder with \(resource).gif...")

            let url = Bundle.module.url(forResource: resource, withExtension: "gif")!
            let data = try Data(contentsOf: url)
            let gif = try GIF(data: data) // Try decoding the GIF
            let reEncoded = try gif.encoded() // Try encoding it again

            XCTAssertEqual(data, reEncoded)
        }
    }
}
