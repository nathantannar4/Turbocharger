// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Turbocharger",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Turbocharger",
            targets: ["Turbocharger"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Engine", from: "2.3.2"),
    ],
    targets: [
        .target(
            name: "Turbocharger",
            dependencies: [
                "Engine"
            ]
        )
    ]
)
