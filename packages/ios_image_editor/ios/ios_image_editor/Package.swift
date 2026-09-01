// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ios_image_editor",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "ios-image-editor", targets: ["ios_image_editor"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ios_image_editor",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
