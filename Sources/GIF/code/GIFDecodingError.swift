public enum GIFDecodingError: Error {
    case noMoreBytes
    case invalidHeader
    case invalidTrailer
    case invalidStringEncoding
}