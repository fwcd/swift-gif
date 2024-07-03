import Foundation

public extension Sequence where Element == UInt8 {
    var hexString: String {
        map { String($0, radix: 16) }.joined(separator: " ")
    }
}
