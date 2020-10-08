// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-gif",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GIF",
            targets: ["GIF"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        .package(url: "https://github.com/fwcd/swift-utils.git", from: "1.0.0"),
        .package(url: "https://github.com/fwcd/swift-graphics.git", .revision("5e5e5240ca7ff0a849c7cf6c3d57904af059f68a"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GIF",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Utils", package: "swift-utils"),
                .product(name: "Graphics", package: "swift-graphics")
            ]
        ),
        .testTarget(
            name: "GIFTests",
            dependencies: [
                .target(name: "GIF")
            ],
            resources: [
                .process("Resources/mandelbrot.gif")
            ]
        )
    ]
)
