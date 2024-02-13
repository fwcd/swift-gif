// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-gif",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GIF",
            targets: ["GIF"]
        ),
        .executable(
            name: "GIFInspector",
            targets: ["GIFInspector"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
        .package(url: "https://github.com/fwcd/swift-utils.git", from: "3.0.0"),
        .package(url: "https://github.com/fwcd/swift-graphics.git", from: "3.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "0.3.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GIF",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Utils", package: "swift-utils"),
                .product(name: "CairoGraphics", package: "swift-graphics")
            ]
        ),
        .executableTarget(
            name: "GIFInspector",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .target(name: "GIF")
            ]
        ),
        .executableTarget(
            name: "GIFDemoGenerator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Utils", package: "swift-utils"),
                .product(name: "CairoGraphics", package: "swift-graphics"),
                .target(name: "GIF")
            ]
        ),
        .testTarget(
            name: "GIFTests",
            dependencies: [
                .target(name: "GIF")
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
