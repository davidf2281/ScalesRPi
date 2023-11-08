// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScalesRPi",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "scales", targets: ["ScalesRPi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/davidf2281/ScalesCore.git", branch: "main"),
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ScalesRPi",
            dependencies: [
                .product(name: "ScalesCore", package: "ScalesCore"),
                .product(name: "SwiftyGPIO", package: "SwiftyGPIO")
            ])
    ]
)
