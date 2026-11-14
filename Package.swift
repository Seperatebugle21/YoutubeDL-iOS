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
        // Python itself is not a package dependency: the app embeds
        // BeeWare's Python.xcframework (CPython 3.13) and installs the
        // standard library with a build phase. See README.
        .package(
            url: "https://github.com/pvieito/PythonKit.git",
            .exact("0.5.1")
        )
    ],

    targets: [
        .target(
            name: "YoutubeDL",

            dependencies: [
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

        .testTarget(
            name: "YoutubeDL_iOSTests",
            dependencies: [
                "YoutubeDL"
            ]
        )
    ]
)
