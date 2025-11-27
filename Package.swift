// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Asdfghjkl",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Asdfghjkl", targets: ["Asdfghjkl"]),
        .library(name: "AsdfghjklCore", targets: ["AsdfghjklCore"])
    ],
    targets: [
        .target(
            name: "AsdfghjklCore"
        ),
        .executableTarget(
            name: "Asdfghjkl",
            dependencies: ["AsdfghjklCore"]
        ),
        .testTarget(
            name: "AsdfghjklTests",
            dependencies: ["AsdfghjklCore"]
        )
    ]
)
