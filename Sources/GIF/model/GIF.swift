import Graphics

/// An in-memory, decoded GIF animation, closely
/// mirroring the internal structure of a GIF.
public struct GIF {
    public var logicalScreenDescriptor: LogicalScreenDescriptor
    public var globalQuantization: ColorQuantization?
    public var frames: [Frame]

    public init(logicalScreenDescriptor: LogicalScreenDescriptor, globalQuantization: ColorQuantization? = nil, frames: [Frame] = []) {
        self.logicalScreenDescriptor = logicalScreenDescriptor
        self.globalQuantization = globalQuantization
        self.frames = frames
    }
}
