import ArgumentParser
import Foundation
import Logging
import GIF

LoggingSystem.bootstrap {
    GIFLogHandler(label: $0)
}

struct GIFInspector: ParsableCommand {
    @Argument(help: "The file path the input GIF")
    var inputPath: String

    mutating func run() throws {
        let url = URL(fileURLWithPath: inputPath)
        let data = try Data(contentsOf: url)
        let gif = try GIF(data: data)

        dump(gif)
    }
}

GIFInspector.main()
