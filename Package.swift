// swift-tools-version: 5.10
// Library modules for tests / tooling. App target: `xcodegen generate` → Mihon.xcodeproj
//
// Folder layout (Usagi-style):
//   App / Features / Core / Domain / Data / DesignSystem / Resources / Tests
//   + SourceAPI / Reader / Backup / Download / Extension / Tracking

import PackageDescription

let package = Package(
    name: "Mihon",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "SourceAPI", targets: ["SourceAPI"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Reader", targets: ["Reader"]),
        .library(name: "Backup", targets: ["Backup"]),
        .library(name: "Download", targets: ["Download"]),
        .library(name: "Extensions", targets: ["Extensions"]),
        .library(name: "Tracking", targets: ["Tracking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .target(name: "Core", path: "Core"),
        .target(name: "Domain", dependencies: ["Core"], path: "Domain"),
        .target(name: "SourceAPI", path: "SourceAPI"),
        .target(
            name: "Data",
            dependencies: [
                "Core",
                "Domain",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Data"
        ),
        .target(name: "DesignSystem", dependencies: ["Core"], path: "DesignSystem"),
        .target(
            name: "Reader",
            dependencies: ["Core", "Domain", "SourceAPI"],
            path: "Reader"
        ),
        .target(name: "Backup", dependencies: ["Core", "Domain"], path: "Backup"),
        .target(
            name: "Download",
            dependencies: ["Core", "Domain", "SourceAPI", "Reader"],
            path: "Download"
        ),
        .target(
            name: "Extensions",
            dependencies: ["Core", "SourceAPI"],
            path: "Extensions"
        ),
        .target(
            name: "Tracking",
            dependencies: ["Core", "Domain"],
            path: "Tracking"
        ),
        .testTarget(name: "CoreTests", dependencies: ["Core"], path: "Tests/Core"),
        .testTarget(name: "DomainTests", dependencies: ["Domain"], path: "Tests/Domain"),
        .testTarget(name: "ReaderTests", dependencies: ["Reader"], path: "Tests/Reader"),
    ]
)
