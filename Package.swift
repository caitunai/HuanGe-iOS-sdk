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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/1.0.6/HuanGeSdk-1.0.6.xcframework.zip",
            checksum: "efa6f744de98e546a137985a224d869d445920789750b1be98ddca2c6696bf4c"
        )
    ]
)
