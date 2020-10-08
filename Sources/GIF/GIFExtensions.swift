import Foundation
import Graphics

/// Some high-level extensions to the GIF structure
/// for en- and decoding.
extension GIF {
    public init(data: Data) throws {
        var decoder = try GIFDecoder(data: data)
        let gif = try decoder.readGIF()
        self.init(localScreenDescriptor: gif.localScreenDescriptor, globalColorTable: gif.globalColorTable, frames: gif.frames)
    }

    public func encoded() throws -> Data {
        var encoder = GIFEncoder()
        encoder.append(gif: self)
        return encoder.data
    }
}
