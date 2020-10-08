import XCTest
@testable import GIF

final class GIFDecoderTests: XCTestCase {
    static var allTests = [
        ("testGIFDecoder", testGIFDecoder)
    ]

    func testGIFDecoder() throws {
        let url = Bundle.module.url(forResource: "mandelbrot", withExtension: "gif")!
        let data = try Data(contentsOf: url)
        let gif = try GIF(data: data)

        // TODO: Perform assertions on GIF
    }
}
