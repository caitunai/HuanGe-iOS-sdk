// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HuanGeSdk",
    platforms: [
        .iOS(.v16)
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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/1.0.0/HuanGeSdk-1.0.0.xcframework.zip",
            checksum: "62b94f746f0353f0b97f358d764a573907ff4d17c162595afef005a5688a075f"
        )
    ]
)
