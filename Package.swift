// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ConnectSDK-iOS",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "IFTTTConnectSDK", targets: ["IFTTTConnectSDK"])
    ],
    targets: [
        .target(
            name: "IFTTTConnectSDK",
            path: "IFTTT SDK",
            exclude: ["Info.plist"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SDKHostAppTests",
            dependencies: ["IFTTTConnectSDK"],
            path: "SDKHostAppTests",
            exclude: ["Info.plist"],
            resources: [.process("fetch_connection_response.json")]
        )
    ]
)
