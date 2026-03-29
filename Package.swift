// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SkillsUI",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "SkillsUI",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            path: "Sources"
        ),
    ],
    swiftLanguageModes: [.v6]
)
