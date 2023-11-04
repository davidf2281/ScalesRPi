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
        .package(url: "https://github.com/davidf2281/LinuxSPI.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "ScalesRPi",
            dependencies: [
                .product(name: "ScalesCore", package: "ScalesCore"),
                .product(name: "LinuxSPI", package: "LinuxSPI")
            ])
    ]
)
