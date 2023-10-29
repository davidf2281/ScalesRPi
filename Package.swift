// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScalesRPi",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "scales", targets: ["ScalesRPi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/davidf2281/ScalesCore.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "ScalesRPi",
            dependencies: [ .product(name: "ScalesCore",
                                     package: "ScalesCore")])
    ]
)
