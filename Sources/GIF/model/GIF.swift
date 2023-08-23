import CairoGraphics
import QuartzCore

/// An in-memory, decoded GIF animation, closely
/// mirroring the internal structure of a GIF.
public struct GIF {
    public var logicalScreenDescriptor: LogicalScreenDescriptor
    public var globalQuantization: ColorQuantization?
    public var applicationExtensions: [ApplicationExtension]
    public var commentExtensions: [String]
    public var frames: [Frame] {
        didSet {
            if !logicalScreenDescriptor.useGlobalColorTable {
                assert(globalQuantization == nil)

                for frame in frames {
                    // If neither a local nor a global color table exists for any frame,
                    // generate the global color table to make that there is always one
                    // available.
                    if !frame.imageDescriptor.useLocalColorTable {
                        logicalScreenDescriptor.useGlobalColorTable = true
                        globalQuantization = OctreeQuantization(fromImage: frame.image)
                        break
                    }
                }
            }
        }
    }

    public var width: Int { Int(logicalScreenDescriptor.width) }
    public var height: Int { Int(logicalScreenDescriptor.height) }

    public var loopCount: Int? {
        get {
            applicationExtensions.compactMap {
                guard case let .looping(count) = $0 else { return nil }
                return Int(count)
            }.first
        }
        set {
            applicationExtensions = applicationExtensions.compactMap {
                if case .looping(_) = $0 {
                    return newValue.map { .looping(loopCount: UInt16($0)) }
                } else {
                    return $0
                }
            }
        }
    }

    // High-level initializers
    public init(width: Int, height: Int, loopCount: Int? = 0, globalQuantization: ColorQuantization? = nil) {
        self.init(
            logicalScreenDescriptor: LogicalScreenDescriptor(
                width: UInt16(width),
                height: UInt16(height),
                useGlobalColorTable: globalQuantization != nil,
                colorResolution: GIFConstants.colorResolution,
                sortFlag: false,
                sizeOfGlobalColorTable: GIFConstants.colorResolution,
                backgroundColorIndex: GIFConstants.backgroundColorIndex,
                pixelAspectRatio: 0
            ),
            globalQuantization: globalQuantization,
            applicationExtensions: [
                loopCount.map { .looping(loopCount: UInt16($0)) }
            ].compactMap { $0 }
        )
    }

    public init(quantizingImage image: CairoImage) {
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
        commentExtensions: [String] = [],
        frames: [Frame] = []
    ) {
        self.logicalScreenDescriptor = logicalScreenDescriptor
        self.globalQuantization = globalQuantization
        self.applicationExtensions = applicationExtensions
        self.commentExtensions = commentExtensions
        self.frames = frames
    }

    init(copyOf gif: GIF) {
        self.init(
            logicalScreenDescriptor: gif.logicalScreenDescriptor,
            globalQuantization: gif.globalQuantization,
            applicationExtensions: gif.applicationExtensions,
            commentExtensions: gif.commentExtensions,
            frames: gif.frames
        )
    }
}
