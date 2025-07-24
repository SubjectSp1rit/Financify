// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LaunchAnimation",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "LaunchAnimation",
            type: .static,
            targets: ["LaunchAnimation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git",
                 from: "4.5.2")
    ],
    targets: [
        .target(
            name: "LaunchAnimation",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
