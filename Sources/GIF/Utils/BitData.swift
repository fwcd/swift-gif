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
        var remainingBitCount = bitCount
        var cursor: UInt = 0
        while remainingBitCount > 0 {
            if remainingBitsInByte == 8 {
                let byte = UInt8(truncatingIfNeeded: value &>> cursor)
                if remainingBitCount >= 8 {
                    bytes[byteIndex] = byte
                    byteIndex += 1
                    bytes.append(0)
                    cursor &+= 8
                    remainingBitCount &-= 8
                } else {
                    let mask = ~UInt8(truncatingIfNeeded: 255 &<< remainingBitCount)
                    bytes[byteIndex] = byte & mask
                    bitIndexFromRight += remainingBitCount
                    cursor &+= remainingBitCount
                    remainingBitCount &-= remainingBitCount
                }
            } else if remainingBitCount >= remainingBitsInByte {
                let byte = UInt8(truncatingIfNeeded: value &>> cursor)
                bytes[byteIndex] |= byte &<< bitIndexFromRight
                bytes.append(0)
                cursor &+= remainingBitsInByte
                remainingBitCount &-= remainingBitsInByte
                bitIndexFromRight += remainingBitsInByte
            } else {
                var byte = UInt8(truncatingIfNeeded: value &>> cursor)
                let mask = ~UInt8(truncatingIfNeeded: 255 &<< remainingBitCount)
                byte &= mask
                byte = byte &<< bitIndexFromRight

                bytes[byteIndex] |= byte
                bitIndexFromRight += remainingBitCount
                cursor &+= remainingBitCount
                remainingBitCount &-= remainingBitCount
            }
        }
        precondition(cursor == bitCount, "Corrupted cursor.")

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
