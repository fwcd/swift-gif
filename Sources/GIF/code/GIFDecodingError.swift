public enum GIFDecodingError: Error {
    case noMoreBytes
    case invalidHeader
    case invalidTrailer
    case invalidStringEncoding
    case invalidBlockSize
    case invalidBlockTerminator
    case invalidLoopingExtension
}
