// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SkillsUI",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "SkillsUI",
            path: "Sources"
        ),
    ],
    swiftLanguageModes: [.v6]
)
