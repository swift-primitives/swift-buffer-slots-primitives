public import Buffer_Primitive
import Memory_Allocator_Primitive
import Memory_Heap_Primitives
public import Storage_Contiguous_Primitives
public import Store_Protocol_Primitives
import Store_Split_Primitives

extension Buffer where S: Store.`Protocol`, S: ~Copyable {
    // MARK: - Slots

    /// A fixed-capacity slots buffer backed by dual-plane split storage.
    ///
    /// Provides metadata-parametric random-access slots over two parallel
    /// heap planes: a metadata plane and an element plane. The substrate `S`
    /// IS the split itself —
    /// `Buffer<Store.Split<Storage<…System>.Contiguous<Metadata>, Storage<…System>.Contiguous<Element>>>.Slots`
    /// is the canonical tower. The dual-plane operations recover the lane
    /// (metadata) plane and its element type through a same-type pin on `S`.
    ///
    /// ## Metadata-Driven Storage
    ///
    /// Unlike Linear/Ring (range-tracked) and Slab (bitmap-tracked),
    /// Slots performs **no element lifecycle management**. The consumer
    /// determines slot occupancy through the metadata values — for example,
    /// a Swiss-table hash map uses `0x80` for empty and `h2` hash bits
    /// for occupied.
    ///
    /// ## Consumer-Managed Element Lifecycle
    ///
    /// `Buffer.Slots` has no deinit for elements. Any consumer that
    /// initializes element slots must deinitialize them before releasing
    /// the buffer, typically via ``deinitialize(where:)``.
    /// This is a capability boundary — the same contract as
    /// `Storage.Split`.
    ///
    /// ## Move-only (R-1) + the untracked-elements ledger rule
    ///
    /// `Buffer.Slots` is move-only over the move-only substrate; value semantics enter at the
    /// ADT tier via the ratified `Shared` column. The ELEMENTS plane runs UNTRACKED: occupancy
    /// is consumer-defined (the metadata predicate), so the seam's linear-prefix ledger cannot
    /// describe it — every element-lifecycle op here resets the elements ledger to `.empty`,
    /// keeping the plane's deinit oracle inert. The LANES plane stays tracked (it is fully
    /// initialized for its whole life). The consumer MUST `deinitialize(where:)` initialized
    /// non-trivial elements before dropping the buffer — the prior contract, unchanged.
    ///
    /// ## No Growth
    ///
    /// Fixed-capacity. Consumers requiring growth must allocate a new
    /// `Buffer.Slots` and re-insert elements (e.g., hash table rehash).
    @frozen
    public struct Slots: ~Copyable {
        // refined-C ([MOD-036]): `@usableFromInline internal` (not `package`) so the co-located
        // ops in this type module stay cross-package inlinable. Slots is single-variant — there
        // is no satellite reaching these cross-module, so [MOD-037] does not apply and no
        // `package` window is needed (all callers are in this module).
        @usableFromInline
        var header: Header

        // (b-pin): the substrate `S` IS the dual-plane split. Conditional Copyable conditions
        // directly on `S` (the field's type) — exactly the Box/Bounded `var storage: S` shape,
        // legal because the field's type is the namespace param. The lane plane and metadata
        // type are recovered per-operation through a same-type pin on `S`.
        @usableFromInline
        var storage: S

        @inlinable
        package init(header: Header, storage: consuming S) {
            self.header = header
            self.storage = storage
        }
    }
}

// MARK: - Conditional Conformances (Slots)

/// Sendable conformance for `Buffer.Slots`.
///
/// ## Safety Invariant
///
/// `Buffer.Slots` is `~Copyable` with `Store.Split` dual-plane storage. Single
/// ownership enforced; cross-thread transfer is a move.
///
/// ## Intended Use
///
/// - Transferring a slots buffer to a worker thread.
///
/// ## Non-Goals
///
/// - Not a shared concurrent buffer.
extension Buffer.Slots: @unsafe @unchecked Sendable where S: Sendable {}
