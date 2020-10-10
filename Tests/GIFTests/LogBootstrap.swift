import Logging

// See https://github.com/apple/swift-log/issues/77
//
// Slightly hacky approach to configure the log level
// (and handler) for logging in unit tests.

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap {
        TestLogHandler(label: $0)
    }
    return true
}()
