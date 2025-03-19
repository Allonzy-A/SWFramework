// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SWFramework",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SWFramework",
            targets: ["SWFramework"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SWFramework",
            dependencies: [],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "SWFrameworkTests",
            dependencies: ["SWFramework"]),
    ]
) 