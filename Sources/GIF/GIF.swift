import Foundation
import Graphics

/// An in-memory, decoded GIF animation.
public struct GIF {
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
        globalQuantization = OctreeQuantization(fromImage: image, colorCount: GIFConstants.nonTransparentColorCount)
    }

    public init(data: Data) throws {
        var decoder = try GIFDecoder(data: data)

        width = Int(decoder.width)
        height = Int(decoder.height)
        globalQuantization = decoder.globalQuantization
        frames = []

        while let (image, delayTime) = try? decoder.readFrame() {
            frames.append(Frame(image: image, delayTime: delayTime))
        }

        try decoder.readTrailer()
    }

    public struct Frame {
        public let image: Image
        public let delayTime: Int
        public let localQuantization: ColorQuantization?
        public let disposalMethod: DisposalMethod

        public init(image: Image, delayTime: Int, localQuantization: ColorQuantization? = nil, disposalMethod: DisposalMethod = .clearCanvas) {
            self.image = image
            self.delayTime = delayTime
            self.localQuantization = localQuantization
            self.disposalMethod = disposalMethod
        }
    }

    public mutating func append(frame: Frame) {
        frames.append(frame)
    }

    public func encoded() throws -> Data {
        var encoder = GIFEncoder(width: UInt16(width), height: UInt16(height), globalQuantization: globalQuantization)

        for frame in frames {
            var localQuantization: ColorQuantization? = nil

            if globalQuantization == nil {
                localQuantization = OctreeQuantization(fromImage: frame.image, colorCount: GIFConstants.colorCount)
            }

            try encoder.appendFrame(image: frame.image, delayTime: UInt16(frame.delayTime), localQuantization: localQuantization, disposalMethod: frame.disposalMethod.rawValue)
        }

        encoder.appendTrailer()
        return encoder.data
    }
}
