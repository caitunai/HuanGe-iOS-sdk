// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HuanGeSdk",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "HuanGeSdk",
            targets: ["HuanGeSdk"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "HuanGeSdk",
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/0.1.0/HuanGeSdk-0.1.0.xcframework.zip",
            checksum: "e581dd99ddc3a41c24fc81747b20ee67f4b2bcaef35974d4ce11e20573d1bfd6"
        )
    ]
)
