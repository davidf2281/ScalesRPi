// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "LinuxSPI",
    products: [
        .library(name: "LinuxSPI", targets: ["LinuxSPI"]),
    ],
    targets: [
        .target(name: "LinuxSPI"),
    ]
)