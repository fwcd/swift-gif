import Foundation

/** Color channels, assuming RGB colors. */
fileprivate let CHANNELS = 3

/**
 * A quantization where all colors are evenly
 * spaced along each channel.
 */
public struct UniformQuantization: ColorQuantization {
    public private(set) var colorTable: [Color]
    private let colorsPerChannel: Int
    private let colorStride: Int

    public init(fromImage image: Image, colorCount: Int) {
        colorTable = []
        colorsPerChannel = Int(pow(Double(colorCount), 1.0 / Double(CHANNELS)))
        colorStride = 256 / colorsPerChannel

        for r in 0..<colorsPerChannel {
            for g in 0..<colorsPerChannel {
                for b in 0..<colorsPerChannel {
                    colorTable.append(Color(
                        red: UInt8(r * colorStride),
                        green: UInt8(g * colorStride),
                        blue: UInt8(b * colorStride)
                    ))
                }
            }
        }
    }

    private func tableIndexOf(r: Int, g: Int, b: Int) -> Int {
        return (colorsPerChannel * colorsPerChannel * r) + (colorsPerChannel * g) + b
    }

    public func quantize(color: Color) -> Int {
        let maxChannelColorIndex = colorsPerChannel - 1
        let r = min(maxChannelColorIndex, Int(color.red) / colorStride)
        let g = min(maxChannelColorIndex, Int(color.green) / colorStride)
        let b = min(maxChannelColorIndex, Int(color.blue) / colorStride)
        return tableIndexOf(r: r, g: g, b: b)
    }
}
