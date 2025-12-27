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
        .target(
            name: "DisplayPlaceLib",
            path: "Sources/DisplayPlaceLib"
        ),
        .executableTarget(
            name: "HDRMenuApp",
            dependencies: ["DisplayPlaceLib"],
            path: "Sources/HDRMenuApp",
            resources: []
        )
    ]
)
