public struct ImageDescriptor {
    public internal(set) var imageLeft: UInt16
    public internal(set) var imageTop: UInt16
    public internal(set) var imageWidth: UInt16
    public internal(set) var imageHeight: UInt16
    public internal(set) var useLocalColorTable: Bool
    public internal(set) var interlaceFlag: Bool
    public internal(set) var sortFlag: Bool
    public internal(set) var sizeOfLocalColorTable: UInt8
}
