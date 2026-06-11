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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/0.3.0/HuanGeSdk-0.3.0.xcframework.zip",
            checksum: "a4c6c65aa6ccbe7907c5237ff9b22e2c70d48421509018973e764d5bed4f3994"
        )
    ]
)
