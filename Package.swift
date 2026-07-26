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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/1.0.1/HuanGeSdk-1.0.1.xcframework.zip",
            checksum: "5d4bd031aaa039b23ab113eb96e81f2ed51763d152bb9bb11746e1113c062198"
        )
    ]
)
