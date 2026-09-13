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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/1.0.2/HuanGeSdk-1.0.2.xcframework.zip",
            checksum: "f09ce4950184560ddaa48e0d622f18b65e1d133b50c82f1a3480ff9ddbecd3f6"
        )
    ]
)
