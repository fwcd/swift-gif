import XCTest
@testable import GIF

final class GIFDecoderTests: XCTestCase {
    static var allTests = [
        ("testGIFDecoder", testGIFDecoder)
    ]

    func testGIFDecoder() throws {
        for resource in ["spin", "mandelbrot"] {
            let url = Bundle.module.url(forResource: resource, withExtension: "gif")!
            let data = try Data(contentsOf: url)
            let gif = try GIF(data: data)

            // TODO: Perform assertions on GIF
        }
    }
}
