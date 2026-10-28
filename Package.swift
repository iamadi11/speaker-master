// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SpeakerMaster",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SpeakerMaster", targets: ["SpeakerMaster"]),
    ],
    targets: [
        .target(
            name: "SpeakerMaster",
            path: "Sources/SpeakerMaster"
        ),
        .testTarget(
            name: "SpeakerMasterTests",
            dependencies: ["SpeakerMaster"],
            path: "Sources/SpeakerMasterTests"
        ),
    ]
)
