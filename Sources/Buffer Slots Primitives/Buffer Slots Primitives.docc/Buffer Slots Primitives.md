# ``Buffer_Slots_Primitives``

The slots buffer discipline over `Buffer` — a fixed-capacity, metadata-parametric slots
buffer backed by split storage, for noncopyable elements.

## Overview

`Buffer.Slots` is a fixed-capacity slots buffer backed by `Storage.Split` — a single heap
allocation holding a contiguous metadata array alongside the element array. Unlike the
range-tracked (linear, ring) or bitmap-tracked (slab) disciplines, Slots performs **no element
lifecycle management of its own**: the consumer determines slot occupancy through the metadata
values. A Swiss-table hash map, for example, uses `0x80` for an empty slot and `h2` hash bits
for an occupied one.

```swift
import Buffer_Slots_Primitives

let empty: UInt8 = 0x80
var table = Buffer<Storage<Int>.Split<Storage<UInt8>.Heap, Storage<Int>.Heap>>.Slots(capacity: 8, metadataInitial: empty)

// Insert: write the payload, then mark the slot occupied with its h2 hash byte.
let slot: Index<Int> = 3
table.initialize(to: 100, at: slot)
table[metadata: slot] = 0x42

// Probe: scan the contiguous metadata array (SIMD-friendly), then read the payload.
let value = table[payload: slot]                       // 100

// Delete: move the payload out, mark the slot empty again.
let removed = table.move(at: slot)                     // 100
table[metadata: slot] = empty
```

Because element lifecycle is consumer-managed, a consumer that initializes element slots MUST
deinitialize them before dropping the buffer — `deinitialize(where:)` deinitializes every slot
whose metadata indicates occupancy. This is the same capability boundary `Storage.Split` carries.

Slots is **fixed-capacity** — there is no growth. A consumer that needs to grow allocates a new
`Buffer.Slots` and re-inserts (e.g. a hash-table rehash).

## Topics

### Scope

- <doc:Buffer-Slots-Scope>
