import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        LzwEncoderTests.allTests
    ]
}
#endif
