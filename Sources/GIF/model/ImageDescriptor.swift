public struct ImageDescriptor {
    public let imageLeft: UInt16
    public let imageTop: UInt16
    public let imageWidth: UInt16
    public let imageHeight: UInt16
    public let useLocalColorTable: Bool
    public let interlaceFlag: Bool
    public let sortFlag: Bool
    public let sizeOfLocalColorTable: UInt8

    public init(
        imageLeft: UInt16,
        imageTop: UInt16,
        imageWidth: UInt16,
        imageHeight: UInt16,
        useLocalColorTable: Bool,
        interlaceFlag: Bool,
        sortFlag: Bool,
        sizeOfLocalColorTable: UInt8
    ) {
        self.imageLeft = imageLeft
        self.imageTop = imageTop
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.useLocalColorTable = useLocalColorTable
        self.interlaceFlag = interlaceFlag
        self.sortFlag = sortFlag
        self.sizeOfLocalColorTable = sizeOfLocalColorTable
    }
}
