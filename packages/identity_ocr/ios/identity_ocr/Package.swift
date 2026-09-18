// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "identity_ocr",
    platforms: [.iOS("13.0")],
    products: [.library(name: "identity-ocr", targets: ["identity_ocr"])],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(url: "https://github.com/SwiftyTesseract/libtesseract.git", exact: "0.2.0")
    ],
    targets: [.target(
        name: "identity_ocr",
        dependencies: [
            .product(name: "FlutterFramework", package: "FlutterFramework"),
            .product(name: "libtesseract", package: "libtesseract")
        ],
        linkerSettings: [.linkedLibrary("z"), .linkedLibrary("c++")]
    )]
)
