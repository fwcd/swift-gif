import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LzwEncoderTests.allTests),
        testCase(BitDataTests.allTests)
    ]
}
#endif
