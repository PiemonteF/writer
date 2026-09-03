// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Writer",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Writer", path: "Sources/Writer"),
        .testTarget(name: "WriterTests", dependencies: ["Writer"], path: "Tests/WriterTests"),
    ]
)
