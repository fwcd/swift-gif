import ArgumentParser
import Foundation
import Logging
import GIF
import CairoGraphics
import Utils

LoggingSystem.bootstrap {
    GIFLogHandler(label: $0)
}

struct GIFDemoGenerator: ParsableCommand {
    @Argument(help: "The file path the output GIF")
    var outputPath: String

    mutating func run() throws {
        let url = URL(fileURLWithPath: outputPath)

        let (width, height) = (300, 300)
        var gif = GIF(width: width, height: height)

        for i in 0..<5 {
            let graphics = try CairoContext(width: width, height: height)

            graphics.draw(rect: Rectangle(fromX: Double(i) * 20, y: Double(i) * 20, width: 10, height: 10, color: .blue, isFilled: true))

            let image = try graphics.makeImage()
            gif.frames.append(.init(image: image, delayTime: 100))
        }

        try gif.encoded().write(to: url)
    }
}

GIFDemoGenerator.main()
