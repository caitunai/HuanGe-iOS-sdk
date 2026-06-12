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
            checksum: "53ee7145f6293a11daf475ae1c372a621662e36e5225603d8833a34b5aa51615"
        )
    ]
)
