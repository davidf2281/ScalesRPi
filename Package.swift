// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScalesRPi",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ScalesRPi", targets: ["ScalesRPi"]),
    ],
    dependencies: [
        .package(url: "https://github.com/davidf2281/ScalesCore.git", branch: "main"),
        .package(url: "https://github.com/davidf2281/SwiftyGPIO.git", branch: "master")
    ],
    targets: [
        
        .target(name: "ScalesRPiC"),
        .executableTarget(
            name: "ScalesRPi",
            dependencies: [
                "ScalesRPiC",
                .product(name: "ScalesCore", package: "ScalesCore"),
                .product(name: "SwiftyGPIO", package: "SwiftyGPIO")
            ]),
        .testTarget(name: "ScalesRPiTests", dependencies: ["ScalesRPi"])
    ]
)
