public enum GIFDecodingError: Error {
    case noMoreBytes
    case invalidHeader
    case invalidTrailer
    case invalidStringEncoding
    case invalidBlockSize(String)
    case invalidBlockTerminator(String)
    case invalidDisposalMethod(UInt8)
    case invalidImageSeparator(String)
    case invalidLoopingExtension
    case invalidGraphicsControlExtension
    case noQuantizationForDecodingImage
}
