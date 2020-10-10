import XCTest
import Logging
import Graphics
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
            let reDecoded = try GIF(data: reEncoded) // Try decoding it again

            for (frame1, frame2) in zip(gif.frames, reDecoded.frames) {
                assertImagesEqual(frame1.image, frame2.image)
                XCTAssertEqual(frame1.delayTime, frame2.delayTime)
            }
        }
    }

    private func assertImagesEqual(_ image1: Image, _ image2: Image) {
        XCTAssertEqual(image1.width, image2.width)
        XCTAssertEqual(image1.height, image2.height)

        for y in 0..<image1.height {
            for x in 0..<image1.width {
                XCTAssertEqual(image1[y, x], image2[y, x])
            }
        }
    }
}
