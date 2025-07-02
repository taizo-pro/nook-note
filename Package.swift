// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NookNote",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "NookNote",
            targets: ["NookNote"]
        ),
    ],
    dependencies: [
        // No external dependencies initially
    ],
    targets: [
        .executableTarget(
            name: "NookNote",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "NookNoteTests",
            dependencies: ["NookNote"],
            path: "Tests"
        ),
    ]
)