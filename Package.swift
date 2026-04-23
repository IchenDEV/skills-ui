// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SkillsUI",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/textual.git", from: "0.3.1"),
    ],
    targets: [
        .executableTarget(
            name: "SkillsUI",
            dependencies: [
                .product(name: "Textual", package: "textual"),
            ],
            path: "Sources"
        ),
    ],
    swiftLanguageModes: [.v6]
)
