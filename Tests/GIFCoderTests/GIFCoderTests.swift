import XCTest
@testable import GIFCoder

final class GIFCoderTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(GIFCoder().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
