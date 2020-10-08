import Graphics

public struct Frame {
    public let image: Image
    public let imageDescriptor: ImageDescriptor
    public let delayTime: Int
    public let localQuantization: ColorQuantization?
    public let disposalMethod: DisposalMethod

    public init(
        image: Image,
        imageDescriptor: ImageDescriptor? = nil,
        delayTime: Int,
        localQuantization: ColorQuantization? = nil,
        disposalMethod: DisposalMethod = .clearCanvas
    ) {
        self.image = image
        self.imageDescriptor = imageDescriptor ?? ImageDescriptor(
            imageLeft: 0,
            imageTop: 0,
            imageWidth: UInt16(image.width),
            imageHeight: UInt16(image.height),
            useLocalColorTable: localQuantization != nil,
            interlaceFlag: false,
            sortFlag: false,
            sizeOfLocalColorTable: GIFConstants.colorResolution
        )
        self.delayTime = delayTime
        self.localQuantization = localQuantization
        self.disposalMethod = disposalMethod
    }
}
