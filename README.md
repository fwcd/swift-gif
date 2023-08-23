# GIF Coder for Swift

[![Build](https://github.com/fwcd/swift-gif/actions/workflows/build.yml/badge.svg)](https://github.com/fwcd/swift-gif/actions/workflows/build.yml)

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

## Technical Details

GIF encoding is more computationally intensive than decoding. It can become a bottleneck when GIF is used as a video codec and serialization must happen in real-time. Therefore, multicore CPU is used to accelerate the encoding of animated GIFs. All the animation frames are gathered into one `Array`, which is divided among all CPU cores in the system.

## System Dependencies

* Swift 5.7+
* Cairo, see [swift-graphics](https://github.com/fwcd/swift-graphics)
