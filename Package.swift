// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-buffer-slots-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "Buffer Slots Primitive", targets: ["Buffer Slots Primitive"]),
        .library(name: "Buffer Slots Primitives", targets: ["Buffer Slots Primitives"]),
        .library(name: "Buffer Slots Primitives Test Support", targets: ["Buffer Slots Primitives Test Support"]),
    ],
    dependencies: [
        .package(path: "../swift-buffer-primitives"),
        .package(path: "../swift-storage-primitives"),
        .package(path: "../swift-storage-split-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-affine-primitives"),
        .package(path: "../swift-ordinal-primitives"),
        .package(path: "../swift-memory-primitives"),
    ],
    targets: [
        .target(
            name: "Buffer Slots Primitive",
            dependencies: [
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(name: "Buffer Growth Primitives", package: "swift-buffer-primitives"),
                .product(name: "Storage Split Primitives", package: "swift-storage-split-primitives"),
                .product(name: "Storage Inline Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Initialization Primitives", package: "swift-storage-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
            ]
        ),
        .target(
            name: "Buffer Slots Primitives",
            dependencies: [
                "Buffer Slots Primitive",
                .product(name: "Storage Split Primitives", package: "swift-storage-split-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
            ]
        ),
        // MARK: - Test Support
        .target(
            name: "Buffer Slots Primitives Test Support",
            dependencies: [
                "Buffer Slots Primitives",
                .product(name: "Memory Primitives Test Support", package: "swift-memory-primitives"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        .testTarget(
            name: "Buffer Slots Primitives Tests",
            dependencies: ["Buffer Slots Primitives", "Buffer Slots Primitives Test Support"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("BuiltinModule"),
        .enableExperimentalFeature("RawLayout"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
