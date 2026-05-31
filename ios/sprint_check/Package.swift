// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sprint_check",
    platforms: [
        .iOS("15.5")
    ],
    products: [
        .library(name: "sprint-check", targets: ["sprint_check"])
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
