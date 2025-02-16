import Logging

/// A simple log handler for internal purposes
/// (e.g. test logging, GIF inspector). Not intended
/// for consumers of the public GIF library.
public struct GIFLogHandler: LogHandler {
    public var logLevel: Logger.Level
    public var metadata: Logger.Metadata = [:]
    public let label: String

    public init(label: String, logLevel: Logger.Level = .debug) {
        self.label = label
        self.logLevel = logLevel
    }

    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        print("[\(level)] \(label): \(message)")
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
}
