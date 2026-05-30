// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sprint_check",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "sprint_check", targets: ["sprint_check"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "sprint_check",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            // path: ".",
            // exclude: [
            //     "advert.podspec",
            //     ".gitignore"
            // ],
            // sources: [
            //     "Classes"
            // ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
