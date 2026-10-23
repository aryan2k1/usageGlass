// swift-tools-version: 6.2
import PackageDescription
let package = Package(
    name: "UsageGlass",
    platforms: [.macOS(.v26)],
    products: [.executable(name: "UsageGlass", targets: ["UsageGlass"])],
    targets: [
        .executableTarget(name: "UsageGlass", resources: [.copy("Resources")]),
        .testTarget(name: "UsageGlassTests", dependencies: ["UsageGlass"])
    ],
    swiftLanguageModes: [.v5]
)
