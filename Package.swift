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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/0.2.0/HuanGeSdk-0.2.0.xcframework.zip",
            checksum: "0325b51a637ca7e2eaa511209b59a74c26aea2b6ebf37ea862921d42db6a756b"
        )
    ]
)
