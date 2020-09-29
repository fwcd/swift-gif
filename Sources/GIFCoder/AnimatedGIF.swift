import Foundation

public struct AnimatedGIF {
    public let width: Int
    public let height: Int
    private let globalQuantization: ColorQuantization?
    public var frames: [Frame] = []

    public init(width: Int, height: Int, globalQuantization: ColorQuantization? = nil) {
        self.width = width
        self.height = height
        self.globalQuantization = globalQuantization
    }

    public init(quantizingImage image: Image) {
        width = image.width
        height = image.height
        globalQuantization = OctreeQuantization(fromImage: image, colorCount: gifNonTransparentColorCount)
    }

    public struct Frame {
        public let image: Image
        public let delayTime: Int

        public init(image: Image, delayTime: Int) {
            self.image = image
            self.delayTime = delayTime
        }
    }

    public mutating func append(frame: Frame) {
        frames.append(frame)
    }

    public func encoded() throws -> Data {
        var encoder = AnimatedGIFEncoder(width: UInt16(width), height: UInt16(height), globalQuantization: globalQuantization)
        for frame in frames {
            try encoder.append(frame: frame.image, delayTime: UInt16(frame.delayTime))
        }
        encoder.appendTrailer()
        return encoder.data
    }
}
