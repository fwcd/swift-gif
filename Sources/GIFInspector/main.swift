import ArgumentParser
import Foundation
import GIF

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
