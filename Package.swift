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
            checksum: "05637f4fd5e3756c31c218f103896f9c25d6997dede3f0854b94f8276024a73f"
        ),
        .testTarget(name: "YoutubeDL_iOSTests", dependencies: ["YoutubeDL"])
    ]
)
