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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/1.0.4/HuanGeSdk-1.0.4.xcframework.zip",
            checksum: "e02236951b84791619216836039b09bc60dce6f186d12cb0b9de6d67f585a590"
        )
    ]
)
