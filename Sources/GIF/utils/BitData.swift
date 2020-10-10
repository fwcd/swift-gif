import Foundation
import Logging

fileprivate let log = Logger(label: "GIF.BitData")

/// Enables reading and writing chunks of individual
/// bits in a byte buffer. Note that bits are written
/// from **right (LSB) to left (MSB)** inside a byte.
struct BitData {
    public private(set) var bytes: [UInt8]
    private var byteIndex: Int = 0
    private var bitIndexFromRight: UInt = 0 { // ...inside the current byte
        didSet {
            if bitIndexFromRight >= 8 {
                byteIndex += 1
                bitIndexFromRight = 0
            }
        }
    }
    private var remainingBitsInByte: UInt { 8 - bitIndexFromRight }
    public var atHead: BitData { BitData(from: bytes) }

    public init(from bytes: [UInt8] = [0]) {
        self.bytes = bytes
    }

    /// Writes the rightmost `bitCount` bits from the value.
    public mutating func write(_ value: UInt, bitCount: UInt) {
        // Write bits
        for i in 0..<bitCount {
            let bit = (value >> i) & 1
            bytes[byteIndex] |= UInt8(bit << bitIndexFromRight)
            bitIndexFromRight += 1

            if bitIndexFromRight == 0 {
                bytes.append(0)
            }
        }
        log.trace("Wrote \(value & ((1 << bitCount) - 1)) of width \(bitCount)")
    }

    public mutating func read(bitCount: UInt) -> UInt {
        assert(bitCount <= UInt.bitWidth)
        // Read bits
        var result: UInt = 0
        for i in 0..<bitCount {
            let bit = (UInt(bytes[byteIndex]) >> bitIndexFromRight) & 1
            result |= bit << i
            bitIndexFromRight += 1
        }
        log.trace("Read \(result) of width \(bitCount)")
        return result
    }
}
