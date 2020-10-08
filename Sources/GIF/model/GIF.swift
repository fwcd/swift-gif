import Graphics

/// An in-memory, decoded GIF animation, closely
/// mirroring the internal structure of a GIF.
public struct GIF {
    public var logicalScreenDescriptor: LogicalScreenDescriptor
    public var globalQuantization: ColorQuantization?
    public var applicationExtensions: [ApplicationExtension]
    public var frames: [Frame] {
        didSet {
            for i in 0..<frames.count {
                frames[i].colorTable = frames[i].colorTable ?? OctreeQuantization(fromImage: frames[i].image, colorCount: GIFConstants.colorCount)
            }
        }
    }

    public var width: Int { Int(logicalScreenDescriptor.width) }
    public var height: Int { Int(logicalScreenDescriptor.height) }

    public var loopCount: Int? {
        get {
            frames.compactMap {
                guard let .looping(count) = $0 else { return nil }
                return Int(count)
            }.first
        }
        set {
            frames = frames.map {
                if .looping(_) = $0 {
                    return .looping(UInt16(newValue))
                } else {
                    return $0
                }
            }
        }
    }

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
    init(
        logicalScreenDescriptor: LogicalScreenDescriptor,
        globalQuantization: ColorQuantization? = nil,
        applicationExtensions: [ApplicationExtension] = [],
        frames: [Frame] = []
    ) {
        self.logicalScreenDescriptor = logicalScreenDescriptor
        self.globalQuantization = globalQuantization
        self.applicationExtensions = applicationExtensions
        self.frames = frames
    }
}
