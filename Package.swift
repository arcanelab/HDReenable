// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "HDReenable",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "HDReenable", targets: ["HDRMenuApp"]),
    ],
    targets: [
        .executableTarget(
            name: "HDRMenuApp",
            dependencies: [],
            path: "Sources/HDRMenuApp",
            resources: [
                .copy("Resources/AppIcon.icns"),
                .copy("Resources/icon.svg")
            ]
        )
    ]
)
