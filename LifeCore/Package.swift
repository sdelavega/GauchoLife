// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LifeCore",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "LifeCore", targets: ["LifeCore"]),
        .library(name: "LifeSettingsUI", targets: ["LifeSettingsUI"]),
    ],
    targets: [
        .target(name: "LifeCore"),
        .target(name: "LifeSettingsUI", dependencies: ["LifeCore"]),
        .testTarget(name: "LifeCoreTests", dependencies: ["LifeCore"]),
    ]
)
