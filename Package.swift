// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HelpBooks",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "helpbooks",
            targets: ["HelpBooksCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/johnxnguyen/Down", branch: "master"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.11.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.0.0")
    ],
    targets: [
        .executableTarget(
            name: "HelpBooksCLI",
            dependencies: [
                "Down",
                "SwiftSoup",
                "Yams",
                "HelpBooksCore"
            ]
        ),
        .target(
            name: "HelpBooksCore",
            dependencies: [
                "Down",
                "SwiftSoup",
                "Yams"
            ]
        )
    ]
)
