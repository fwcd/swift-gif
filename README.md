# GIF Coder for Swift

[![Linux](https://github.com/fwcd/swift-gif-coder/workflows/Linux/badge.svg)](https://github.com/fwcd/swift-gif-coder/actions)

A lightweight LZW encoder and decoder for animated GIFs written in pure Swift, thus running on any platform, including Linux.

## Example
```swift
// Create a new GIF
var gif = GIF(width: 300, height: 300)

// Add some frames for the animation
for i in 0..<20 {
    let image = try Image(fromPngFile: "frame\(i).png")
    gif.frames.append(.init(image: image, delayTime: 100))
}

// Encode the GIF to a byte buffer
let data = try gif.encoded()
```

## System Dependencies
* Swift 5.3+
* See [swift-graphics](https://github.com/fwcd/swift-graphics)
