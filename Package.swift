// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "YoutubeDL-iOS",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "YoutubeDL", targets: ["YoutubeDL"])
    ],
    dependencies: [
        .package(url: "https://github.com/pvieito/PythonKit.git", .exact("0.5.1"))
    ],
    targets: [
        .target(
            name: "YoutubeDL",
            dependencies: ["PythonSupport", "PythonKit"],
            exclude: ["Transcoder.swift"],
            swiftSettings: [.unsafeFlags(["-Onone"])]
        ),
        .target(name: "PythonSupport", dependencies: ["Python"]),
        .binaryTarget(
            name: "Python",
            url: "https://github.com/Seperatebugle21/YoutubeDL-iOS/releases/download/python-ios-3.13.18-b18-modulemap-v2/Python.xcframework.zip",
            checksum: "__PYTHON_XCFRAMEWORK_CHECKSUM__"
        ),
        .testTarget(name: "YoutubeDL_iOSTests", dependencies: ["YoutubeDL"])
    ]
)
