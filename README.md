# GIF Coder for Swift

[![Build](https://github.com/fwcd/swift-gif/actions/workflows/build.yml/badge.svg)](https://github.com/fwcd/swift-gif/actions/workflows/build.yml)
[![Docs](https://github.com/fwcd/swift-gif/actions/workflows/docs.yml/badge.svg)](https://fwcd.github.io/swift-gif/documentation/gif)

A lightweight LZW encoder and decoder for animated GIFs written in pure Swift, thus running on any platform, including Linux.

## Example

```swift
// Create a new GIF
var gif = GIF(width: 300, height: 300)

// Add some frames for the animation
for i in 0..<20 {
    let image = try CairoImage(pngFilePath: "frame\(i).png")
    gif.frames.append(.init(image: image, delayTime: 100))
}

// Encode the GIF to a byte buffer
let data = try gif.encoded()
```

## System Dependencies

* Swift 5.9+
* Cairo, see [swift-graphics](https://github.com/fwcd/swift-graphics)
