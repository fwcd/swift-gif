import Foundation
import Graphics

/// Some high-level extensions that expose encoding
/// and decoding operations.
extension GIF {
    public init(data: Data) throws {
        var decoder = try GIFDecoder(data: data)
        let gif = try decoder.readGIF()
        self.init(copyOf: gif)
    }

    public func encoded() throws -> Data {
        var encoder = GIFEncoder()
        try encoder.append(gif: self)
        return encoder.data
    }
}
