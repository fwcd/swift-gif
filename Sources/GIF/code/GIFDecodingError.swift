public enum GIFDecodingError: Error {
    case noMoreBytes
    case invalidHeader(String)
    case invalidTrailer(String)
    case invalidStringEncoding(String)
    case invalidBlockSize(String)
    case invalidBlockTerminator(String)
    case invalidDisposalMethod(UInt8)
    case invalidImageSeparator(String)
    case invalidLoopingExtension
    case invalidGraphicsControlExtension
    case missingImageDescriptor
    case noQuantizationForDecodingImage
}
