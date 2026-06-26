# Buffer Slots Primitives — Scope

What this package is, and what it deliberately leaves to its siblings.

## Overview

`swift-buffer-slots-primitives` provides the **slots buffer discipline** over the `Buffer`
namespace: a fixed-capacity, metadata-parametric slots buffer backed by split storage. It
defines ``Buffer/Slots`` — a single allocation holding a contiguous metadata array alongside the
element array, with consumer-managed element lifecycle and no element-lifecycle tracking of its
own. It is the substrate a Swiss-table hash map builds on (metadata bytes for the control word,
elements for the payload).

Slots is **single-variant** — there is no Inline, Small, or Bounded form. It is one specialized
buffer discipline among siblings — linear, ring, slab, linked, arena, aligned, unbounded — each
its own package. It supports noncopyable (`~Copyable`) element types.

## Module shape

`Buffer.Slots` ships as **two modules**, the type/ops split in its degenerate form:

- A **type module** (``Buffer Slots Primitive``, singular) — the lean `~Copyable` value type
  together with *all* the operations that touch its storage (capacity, metadata/payload
  subscripts, element lifecycle, bulk operations, pointer access, copy-on-write). Those
  operations are `@usableFromInline internal` and live next to the storage so they remain
  inlinable across package boundaries (`[MOD-036]`).
- An **umbrella module** (``Buffer Slots Primitives``, plural) — exports-only. `Buffer.Slots`
  carries no `Copyable`-imposing conformance (no `Sequence`/`Collection`/`Sequence.Drain`/
  `Span.Protocol` — only the conditional `Copyable`/`Sendable` tags, which live with the
  type), so there are no isolated conformances to carry here. The plural therefore re-exports
  the type module and nothing more.

`import Buffer_Slots_Primitives` brings in the whole package. Because slots is single-variant,
the umbrella and the type module are the only two modules — there are no variant ops modules to
re-export.

> This two-module shape is a structural choice — co-locating internal operations with their
> storage is a standard-library-grade technique for keeping a public type lean while its
> operations stay inlinable. It is not a workaround for any compiler defect.

## Core targets

| Module | Form | Holds |
|--------|------|-------|
| `Buffer Slots Primitive` | type | `Buffer.Slots`, `.Header`, all storage-touching ops + CoW |
| `Buffer Slots Primitives` | umbrella | re-exports the type module (exports-only; carries no conformances) |

## Out of scope

| Capability | Belongs in |
|------------|------------|
| Other buffer disciplines (linear, ring, slab, linked, arena) | `swift-buffer-{linear,ring,slab,linked,arena}-primitives` |
| Aligned and unbounded buffer forms | `swift-buffer-aligned-primitives`, `swift-buffer-unbounded-primitives` |
| Growth (Slots is fixed-capacity; growth is a consumer rehash) | consumer code (allocate a new `Buffer.Slots` and re-insert) |
| Element-occupancy policy (what metadata value means "occupied") | consumer code (Slots is metadata-parametric by design) |
| The `Buffer` namespace and capacity-growth vocabulary | `swift-buffer-primitives` |
| Split storage substrate (metadata + element dual arrays) | `swift-storage-split-primitives` |
| Indices, offsets, and counts | `swift-index-primitives` |

## Evaluation rule

Additions are evaluated against this scope. A buffer form that is not the *slots* discipline
extracts to its own sibling package rather than growing this one. A new operation belongs here
only if it operates *on* a slots buffer; storage layout, occupancy policy, and indexing concerns
delegate to the packages above and to the consumer.
