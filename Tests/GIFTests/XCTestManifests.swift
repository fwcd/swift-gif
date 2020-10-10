import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LzwCoderTests.allTests),
        testCase(BitDataTests.allTests),
        testCase(GIFCoderTests.allTests),
        testCase(PackedFieldByteTests.allTests)
    ]
}
#endif
