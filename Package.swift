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

        .package(
            url: "https://github.com/kewlbear/Python-iOS.git",
            .exact("0.1.1-b20230423-090254")
        )
    ],

    targets: [

        .target(
            name: "YoutubeDL",

            dependencies: [
                "Python-iOS",
                "PythonKit"
            ],

            exclude: [
                "Transcoder.swift"
            ],

            swiftSettings: [
                .unsafeFlags(
                    [
                        "-Onone"
                    ]
                )
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
