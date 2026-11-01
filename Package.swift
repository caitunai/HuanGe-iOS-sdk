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
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/1.0.5/HuanGeSdk-1.0.5.xcframework.zip",
            checksum: "01c7a8fc2a727434c2bf20e5c08b666520602193a907cf536e72317dec82b82f"
        )
    ]
)
