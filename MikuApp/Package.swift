// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Miku",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Miku",
            path: "Sources/Miku",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
