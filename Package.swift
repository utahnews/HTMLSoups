// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HTMLSoups",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HTMLSoups",
            targets: ["HTMLSoups"]),
        .executable(
            name: "HTMLSoupsCLI",
            targets: ["HTMLSoupsCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1"),
        // Development/test dependencies
        .package(url: "https://github.com/utahnews/UtahNewsData.git", branch: "main")
    ],
    targets: [
        .target(
            name: "HTMLSoups",
            dependencies: [
                "SwiftSoup"
            ]),
        .executableTarget(
            name: "HTMLSoupsCLI",
            dependencies: [
                "HTMLSoups",
                .product(name: "UtahNewsData", package: "UtahNewsData")
            ]),
        .testTarget(
            name: "HTMLSoupsTests",
            dependencies: [
                "HTMLSoups",
                .product(name: "UtahNewsData", package: "UtahNewsData")
            ]),
    ]
) 