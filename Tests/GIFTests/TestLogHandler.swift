import Logging

struct TestLogHandler: LogHandler {
    var logLevel: Logger.Level
    var metadata: Logger.Metadata = [:]
    let label: String

    init(label: String, logLevel: Logger.Level = .debug) {
        self.label = label
        self.logLevel = logLevel
    }

    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        print("  [\(level)] \(label): \(message)")
    }

    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { metadata[metadataKey] }
        set { metadata[metadataKey] = newValue }
    }
}
