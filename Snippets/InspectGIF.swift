import Foundation
import Logging
import GIF

LoggingSystem.bootstrap {
    GIFLogHandler(label: $0)
}

guard let inputPath = CommandLine.arguments.dropFirst().first else {
    print("Usage: \(CommandLine.arguments[0]) <input path>")
    exit(1)
}

let url = URL(fileURLWithPath: inputPath)
let data = try Data(contentsOf: url)
let gif = try GIF(data: data)

dump(gif)
