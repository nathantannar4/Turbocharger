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
        .package(url: "https://github.com/nathantannar4/Engine", from: "2.19.0"),
    ],
    targets: [
        .target(
            name: "Turbocharger",
            dependencies: [
                "Engine"
            ],
            swiftSettings: {
                var settings = [SwiftSetting]()
                #if compiler(>=6.2)
                settings.append(.define("XCODE_26"))
                #endif
                #if compiler(>=6.4)
                settings.append(.define("XCODE_27"))
                #endif
                return settings
            }()
        )
    ]
)
