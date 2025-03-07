// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HTMLSoups",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "HTMLSoups",
            targets: ["HTMLSoups"]),
        .library(
            name: "HTMLSoupsUtahNews",
            targets: ["HTMLSoupsUtahNews"]),
        .executable(
            name: "HTMLSoupsCLI",
            targets: ["HTMLSoupsCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1"),
        .package(url: "https://github.com/utahnews/UtahNewsData.git", branch: "main"),
    ],
    targets: [
        // Core library target
        .target(
            name: "HTMLSoups",
            dependencies: [
                "SwiftSoup",
                .product(name: "UtahNewsData", package: "UtahNewsData"),
            ]),

        // Utah news specific target
        .target(
            name: "HTMLSoupsUtahNews",
            dependencies: [
                "HTMLSoups",
                .product(name: "UtahNewsData", package: "UtahNewsData"),
            ]),

        // CLI target
        .executableTarget(
            name: "HTMLSoupsCLI",
            dependencies: [
                "HTMLSoups",
                "HTMLSoupsUtahNews",
            ]),

        // Test targets
        .testTarget(
            name: "HTMLSoupsTests",
            dependencies: ["HTMLSoups"]),

        .testTarget(
            name: "HTMLSoupsUtahNewsTests",
            dependencies: [
                "HTMLSoupsUtahNews",
                .product(name: "UtahNewsData", package: "UtahNewsData"),
            ]),
    ]
)
