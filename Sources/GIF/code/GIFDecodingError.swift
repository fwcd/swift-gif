public enum GIFDecodingError: Error {
    case noMoreBytes
    case invalidHeader(String)
    case invalidTrailer(String)
    case invalidStringEncoding(String)
    case invalidBlockSize(String)
    case invalidBlockTerminator(String)
    case invalidDisposalMethod(UInt8)
    case invalidImageSeparator(String)
    case invalidLoopingExtension(String)
    case invalidGraphicsControlExtension
    case unrecognizedBlock(String)
    case missingImageDescriptor(String)
    case noQuantizationForDecodingImage
}
