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
            url: "https://github.com/Seperatebugle21/YoutubeDL-iOS/releases/download/python-ios-3.13.18-b18-modulemap/Python.xcframework.zip",
            checksum: "6a2988646a0ecbebec22bb474f8638a6c328e7ab1a31bf11ed5343bf0b72722d"
        ),
        .testTarget(name: "YoutubeDL_iOSTests", dependencies: ["YoutubeDL"])
    ]
)
