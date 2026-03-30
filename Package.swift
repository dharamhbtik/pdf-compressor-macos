// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PDFCompressor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "PDFCompressor",
            targets: ["PDFCompressor"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PDFCompressor",
            path: "PDFCompressor",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("PDFKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
