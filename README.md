# Buffer Slots Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

The **slots buffer discipline** over the `Buffer` namespace: a fixed-capacity, metadata-parametric
slots buffer backed by split storage, with consumer-managed element lifecycle — the substrate a
Swiss-table hash map builds on. Supports noncopyable (`~Copyable`) elements.

`Buffer.Slots` is one buffer discipline among siblings; linear, ring, slab, linked, and arena
each live in their own package.

---

## Quick Start

`Buffer.Slots` performs no element-lifecycle tracking of its own — the metadata array *is* the
occupancy state, and the consumer decides what each metadata value means. That makes it the right
substrate for open-addressed hash tables, where the control bytes and the payloads must sit in one
allocation.

```swift
import Buffer_Slots_Primitives

// `Buffer.Slots` is generic over its dual-plane split substrate. The canonical tower carries
// `Int` payloads behind `UInt8` control bytes — the Swiss-table shape. Alias it for readability.
typealias Table = Buffer<
    Store.Split<
        Storage<Memory.Allocator<Memory.Heap>>.Contiguous<UInt8>,
        Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>
    >
>.Slots

// 8 slots, metadata byte 0x80 = "empty" (the Swiss-table convention).
let empty: UInt8 = 0x80
var table = Table(capacity: 8, metadataInitial: empty)

// Insert: write the payload, then mark the slot occupied with its h2 hash byte.
let slot: Index<Int> = 3
table.initialize(to: 100, at: slot)
table[metadata: slot] = 0x42

// Probe: read the payload (or scan the contiguous metadata array for SIMD matching).
let value = table[payload: slot]          // 100

// Delete: move the payload out, mark the slot empty again.
let removed = table.move(at: slot)        // 100
table[metadata: slot] = empty

// Before dropping a buffer with initialized elements, deinitialize the occupied slots.
table.deinitialize(where: { $0 != empty })
```

`Buffer.Slots` is generic over both its element type (including noncopyable elements) and a
`BitwiseCopyable` metadata type — typically `UInt8` for a Swiss-table control byte. It is
fixed-capacity: growth is a consumer concern (allocate a larger buffer and re-insert).

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-buffer-slots-primitives.git", branch: "main")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Buffer Slots Primitives", package: "swift-buffer-slots-primitives"),
    ]
)
```

The package is pre-1.0 — depend on `branch: "main"` until `0.1.0` is tagged. Requires Swift 6.3.1
and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux toolchain).

---

## Architecture

`Buffer.Slots` ships as two modules: a lean type module (the value type plus every operation that
touches its storage) and an exports-only umbrella. Slots is single-variant and carries no
`Copyable`-imposing conformance, so — unlike the multi-variant disciplines — there are no separate
conformance modules; the umbrella simply re-exports the type module.

| Product | Target | Purpose |
|---------|--------|---------|
| `Buffer Slots Primitive` | `Sources/Buffer Slots Primitive/` | The `Buffer.Slots` value type plus every storage-touching operation: the capacity initializer, the metadata and payload subscripts, the element-lifecycle operations (`initialize` / `move` / `deinitialize`), bulk fills, and the `withMetadataPointer` SIMD escape hatch. |
| `Buffer Slots Primitives` | `Sources/Buffer Slots Primitives/` | The package umbrella — exports-only; re-exports the type module so a single `import` brings in the whole package. |
| `Buffer Slots Primitives Test Support` | `Tests/Support/` | Re-exports the package for test consumers. |

Foundation-free.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |

---

## Related Packages

- [`swift-buffer-primitives`](https://github.com/swift-primitives/swift-buffer-primitives) — the `Buffer` namespace and capacity-growth vocabulary.
- [`swift-storage-split-primitives`](https://github.com/swift-primitives/swift-storage-split-primitives) — the split storage substrate (metadata + element dual arrays in one allocation).
- Sibling disciplines: `swift-buffer-linear-primitives`, `swift-buffer-ring-primitives`, `swift-buffer-slab-primitives`, `swift-buffer-linked-primitives`, `swift-buffer-arena-primitives`.

---

## Community

<!-- BEGIN: discussion -->
<!-- Discussion thread created at publication. -->
<!-- END: discussion -->

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
