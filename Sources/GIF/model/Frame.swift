import Graphics

public struct Frame {
    public let image: Image
    public let imageDescriptor: ImageDescriptor
    public let graphicsControlExtension: GraphicsControlExtension
    public let localQuantization: ColorQuantization?

    public var delayTime: Int { Int(graphicsControlExtension.delayTime) }
    public var disposalMethod: DisposalMethod { graphicsControlExtension.disposalMethod }

    /// High-level initializer
    public init(
        image: Image,
        imageDescriptor: ImageDescriptor? = nil,
        delayTime: Int,
        localQuantization: ColorQuantization? = nil,
        disposalMethod: DisposalMethod = .clearCanvas
    ) {
        self.init(
            image: image,
            imageDescriptor: imageDescriptor ?? ImageDescriptor(
                imageLeft: 0,
                imageTop: 0,
                imageWidth: UInt16(image.width),
                imageHeight: UInt16(image.height),
                useLocalColorTable: localQuantization != nil,
                interlaceFlag: false,
                sortFlag: false,
                sizeOfLocalColorTable: GIFConstants.colorResolution
            ),
            graphicsControlExtension: GraphicsControlExtension(
                disposalMethod: disposalMethod,
                userInputFlag: false,
                transparentColorFlag: true,
                delayTime: UInt16(delayTime),
                backgroundColorIndex:
            ),
            localQuantization: localQuantization
        )
    }

    /// Low-level initializer
    init(
        image: Image,
        imageDescriptor: ImageDescriptor,
        graphicsControlExtension: GraphicsControlExtension,
        localQuantization: ColorQuantization?
    ) {
        self.image = image
        self.imageDescriptor = imageDescriptor
        self.graphicsControlExtension = graphicsControlExtension
        self.localQuantization = localQuantization
    }
}
