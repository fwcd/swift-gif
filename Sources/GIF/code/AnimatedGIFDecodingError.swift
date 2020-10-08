public enum AnimatedGIFDecodingError: Error {
    case noMoreBytes
    case invalidHeader
    case invalidTrailer
    case invalidStringEncoding
}
