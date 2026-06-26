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
        // MARK: - Type module — the lean `~Copyable` `Buffer.Slots` type plus the operations
        //         that touch its storage internals (`@usableFromInline internal` per [MOD-036]).
        .library(name: "Buffer Slots Primitive", targets: ["Buffer Slots Primitive"]),
        // MARK: - Umbrella — `Buffer Slots Primitives` doubles as the [MOD-005] umbrella. Slots is
        //         single-variant and carries no Copyable-imposing conformance, so the type/ops
        //         split is degenerate: the umbrella is exports-only (re-exports the type module).
        .library(name: "Buffer Slots Primitives", targets: ["Buffer Slots Primitives"]),
        .library(name: "Buffer Slots Primitives Test Support", targets: ["Buffer Slots Primitives Test Support"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", branch: "main"),
        // W3 tower: resolve the changed storage stack against the canonical-basename worktrees.
        .package(url: "https://github.com/swift-primitives/swift-storage-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-storage-split-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-allocation-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-affine-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ordinal-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Type module — lean `~Copyable` `Buffer.Slots` + `@usableFromInline internal`
        //         ops co-located with storage ([MOD-036]). Single-variant: no satellite, so
        //         no `package` window and no [MOD-037] cross-variant pinning.
        .target(
            name: "Buffer Slots Primitive",
            dependencies: [
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(name: "Store Split Primitives", package: "swift-storage-split-primitives"),
                .product(name: "Store Protocol Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Allocator Primitive", package: "swift-memory-allocation-primitives"),
                .product(name: "Storage Contiguous Primitives", package: "swift-storage-primitives"),
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
            ]
        ),

        // MARK: - Umbrella — exports-only ([MOD-005]). Re-exports the type module; carries no
        //         conformances of its own (slots exposes none). Acyclic per [MOD-032]: depends
        //         on the type module singular, never the reverse.
        .target(
            name: "Buffer Slots Primitives",
            dependencies: [
                "Buffer Slots Primitive",
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
