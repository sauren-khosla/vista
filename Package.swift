// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Vista",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Vista", targets: ["Vista"])],
    targets: [
        .target(name: "VistaCore"),
        .executableTarget(name: "Vista", dependencies: ["VistaCore"]),
        .testTarget(name: "VistaCoreTests", dependencies: ["VistaCore"]),
        .testTarget(name: "VistaModelTests", dependencies: ["Vista"])
    ],
    swiftLanguageModes: [.v5]
)
