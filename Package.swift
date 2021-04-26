// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ConnectSDK-iOS",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "IFTTT SDK", targets: ["IFTTT SDK"])
    ],
    targets: [
        .target(
            name: "IFTTT SDK",
            path: "IFTTT SDK",
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SDKHostAppTests",
            dependencies: ["IFTTT SDK"],
            path: "SDKHostAppTests",
            exclude: ["Info.plist"],
            resources: [.process("fetch_connection_response.json")]
        )
    ]
)
