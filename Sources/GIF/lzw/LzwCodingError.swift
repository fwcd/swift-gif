public enum LzwCodingError: Error {
    case decodedIndicesEmpty
    case noLastCode
    case tableTooSmall
}
