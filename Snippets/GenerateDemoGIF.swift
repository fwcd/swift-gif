import Foundation
import Logging
import GIF
import CairoGraphics
import Utils

LoggingSystem.bootstrap {
    GIFLogHandler(label: $0)
}

guard let outputPath = CommandLine.arguments.dropFirst().first else {
    print("Usage: \(CommandLine.arguments[0]) <output path>")
    exit(1)
}

let url = URL(fileURLWithPath: outputPath)

let (width, height) = (300, 300)
var gif = GIF(width: width, height: height)

for i in 0..<5 {
    let ctx = try CairoContext(width: width, height: height)

    ctx.draw(rect: Rectangle(fromX: Double(i) * 20, y: Double(i) * 20, width: 10, height: 10, color: .blue, isFilled: true))

    let image = try ctx.makeImage()
    gif.frames.append(.init(image: image, delayTime: 100))
}

try gif.encoded().write(to: url)
