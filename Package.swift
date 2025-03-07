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
        .package(url: "https://github.com/utahnews/UtahNewsData.git", branch: "main"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "HTMLSoups",
            dependencies: [
                "SwiftSoup",
                .product(name: "UtahNewsData", package: "UtahNewsData"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]),
        .executableTarget(
            name: "HTMLSoupsCLI",
            dependencies: ["HTMLSoups"]),
        .testTarget(
            name: "HTMLSoupsTests",
            dependencies: [
                "HTMLSoups",
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]),
    ]
) 