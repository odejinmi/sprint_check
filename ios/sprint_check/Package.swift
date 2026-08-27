// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "sprint_check",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "sprint-check", targets: ["sprint_check"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "sprint_check",
            dependencies: [
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
