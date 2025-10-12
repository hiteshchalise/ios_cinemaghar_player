// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CinemagharPlayerTest",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CinemagharPlayerTest",
            targets: ["CinemagharPlayerTest"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CinemagharPlayerTest"
        ),
        .testTarget(
            name: "CinemagharPlayerTestTests",
            dependencies: ["CinemagharPlayerTest"]
        ),
    ]
)
