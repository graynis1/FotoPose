// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FotoPose",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "FotoPose",
            targets: ["FotoPose"]
        )
    ],
    targets: [
        .target(
            name: "FotoPose",
            path: "Sources/FotoPose",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
