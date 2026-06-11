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
            targets: ["HuanGeSdk", "HuanGeSdkDependencies"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.10.2"),
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "8.2.0"),
        .package(url: "https://github.com/tsolomko/SWCompression.git", exact: "4.9.0"),
        .package(url: "https://github.com/tsolomko/BitByteData.git", exact: "2.1.0")
    ],
    targets: [
        .binaryTarget(
            name: "HuanGeSdk",
            url: "https://github.com/caitunai/HuanGe-iOS-sdk/releases/download/0.1.0/HuanGeSdk-0.1.0.xcframework.zip",
            checksum: "e581dd99ddc3a41c24fc81747b20ee67f4b2bcaef35974d4ce11e20573d1bfd6"
        ),
        .target(
            name: "HuanGeSdkDependencies",
            dependencies: [
                "HuanGeSdk",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "PromiseKit", package: "PromiseKit"),
                .product(name: "SWCompression", package: "SWCompression"),
                .product(name: "BitByteData", package: "BitByteData")
            ]
        )
    ]
)
