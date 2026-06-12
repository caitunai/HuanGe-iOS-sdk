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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/0.4.0/HuanGeSdk-0.4.0.xcframework.zip",
            checksum: "d599166e8e7c49d03ba18fd670c450c4633f74c957b6a3feffd9823ccc4f55ac"
        )
    ]
)
