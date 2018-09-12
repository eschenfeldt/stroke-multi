// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StrokeMulti",
    dependencies: [
        .package(url: "https://github.com/eschenfeldt/stroke-swift.git", .branch("master")),
        .package(url: "https://github.com/JohnSundell/Files.git", .branch("master")),
        .package(url: "https://github.com/jkandzi/Progress.swift", .branch("master")),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "StrokeMulti",
            dependencies: ["StrokeModel", "Files", "Progress", "Utility"]),
    ]
)
