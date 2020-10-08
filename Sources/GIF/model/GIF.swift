import Graphics

/// An in-memory, decoded GIF animation, closely
/// mirroring the internal structure of a GIF.
public struct GIF {
    public var logicalScreenDescriptor: LogicalScreenDescriptor
    public var globalQuantization: ColorQuantization?
    public var frames: [Frame] {
        didSet {
            for i in 0..<frames.count {
                frames[i].colorTable = frames[i].colorTable ?? OctreeQuantization(fromImage: frames[i].image, colorCount: GIFConstants.colorCount)
            }
        }
    }

    public var width: Int { Int(logicalScreenDescriptor.width) }
    public var height: Int { Int(logicalScreenDescriptor.height) }

    // High-level initializers
    public init(width: Int, height: Int, globalQuantization: ColorQuantization? = nil) {
        self.init(
            logicalScreenDescriptor: LogicalScreenDescriptor(
                width: width,
                height: height,
                useGlobalColorTable: globalQuantization != nil,
                colorResolution: colorResolution,
                sortFlag: false,
                sizeOfGlobalColorTable: GIFConstants.colorResolution,
                backgroundColorIndex: 0,
                pixelAspectRatio: 0
            ),
            globalQuantization: globalQuantization
        )
    }

    public init(quantizingImage image: Image) {
        self.init(
            width: image.width,
            height: image.height,
            globalQuantization: OctreeQuantization(fromImage: image, colorCount: GIFConstants.nonTransparentColorCount)
        )
    }

    // Low-level initializer
    init(logicalScreenDescriptor: LogicalScreenDescriptor, globalQuantization: ColorQuantization? = nil, frames: [Frame] = []) {
        self.logicalScreenDescriptor = logicalScreenDescriptor
        self.globalQuantization = globalQuantization
        self.frames = frames
    }
}
