// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Writer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Ink.git", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(name: "Writer", dependencies: ["Ink"], path: "Sources/Writer"),
        .testTarget(name: "WriterTests", dependencies: ["Writer"], path: "Tests/WriterTests"),
    ]
)
