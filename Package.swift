// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "YoutubeDL-iOS",

    platforms: [
        .iOS(.v13)
    ],

    products: [
        .library(
            name: "YoutubeDL",
            targets: [
                "YoutubeDL"
            ]
        )
    ],

    dependencies: [
        .package(
            url: "https://github.com/pvieito/PythonKit.git",
            .exact("0.5.1")
        ),


    ],

    targets: [
        .target(
            name: "YoutubeDL",

            dependencies: [
                "PythonSupport",
                "PythonKit"
            ],

            exclude: [
                "Transcoder.swift"
            ],

            swiftSettings: [
                .unsafeFlags([
                    "-Onone"
                ])
            ]
        ),

        .target(
            name: "PythonSupport",
            dependencies: ["Python"]
        ),

        .binaryTarget(
            name: "Python",
            url: "https://github.com/Seperatebugle21/YoutubeDL-iOS/releases/download/python-ios-3.13.18-b18/Python.xcframework.zip",
            checksum: "2358a6ea8557d901802f5d327b45c008e2b4e67a9f485772beebaf7497942833"
        ),

        .testTarget(
            name: "YoutubeDL_iOSTests",
            dependencies: [
                "YoutubeDL"
            ]
        )
    ]
)
