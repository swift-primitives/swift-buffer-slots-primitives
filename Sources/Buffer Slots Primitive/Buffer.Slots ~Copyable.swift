import Affine_Primitives_Standard_Library_Integration
public import Buffer_Primitive
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Contiguous_Primitives
public import Store_Split_Primitives

// MARK: - Metadata Subscript

extension Buffer.Slots where S: ~Copyable {
    /// Reads or writes the metadata at the given slot.
    ///
    /// The lane (metadata) plane and its element type `M` are recovered from
    /// the substrate `S` through the same-type pin (fresh params, RHS-only).
    @inlinable
    public subscript<M, E: ~Copyable>(metadata slot: Index<E>) -> M
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        get { storage.lanes[slot.retag(M.self)] }
        set { storage.lanes[slot.retag(M.self)] = newValue }
    }
}

// MARK: - S.Element Lifecycle (UNTRACKED — the elements ledger stays `.empty`)
//
// Occupancy is consumer-defined (the metadata predicate), which the seam's linear-prefix ledger
// cannot describe — a tracking ledger would make the elements plane's deinit oracle destroy the
// wrong slots. Every lifecycle op here therefore resets the elements ledger to `.empty` after
// the seam op (the seam self-maintains a prefix shape; the reset restores the untracked
// discipline). The consumer remains responsible for `deinitialize(where:)` before drop.

extension Buffer.Slots where S: ~Copyable {
    /// Initializes the element at the given slot.
    ///
    /// - Precondition: The slot must be uninitialized.
    @inlinable
    public mutating func initialize<M: BitwiseCopyable, E: ~Copyable>(to value: consuming E, at slot: Index<E>)
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        storage.initialize(at: slot, to: value)
        storage.elements.initialization = .empty
    }

    /// Moves the element out of the given slot, leaving it uninitialized.
    ///
    /// - Precondition: The slot must contain an initialized element.
    @inlinable
    public mutating func move<M: BitwiseCopyable, E: ~Copyable>(at slot: Index<E>) -> E
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        let element = storage.move(at: slot)
        storage.elements.initialization = .empty
        return element
    }

    /// Deinitializes the element at the given slot.
    ///
    /// - Precondition: The slot must contain an initialized element.
    @inlinable
    public mutating func deinitialize<M: BitwiseCopyable, E: ~Copyable>(at slot: Index<E>)
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        _ = storage.move(at: slot)
        storage.elements.initialization = .empty
    }
}

// MARK: - Bulk Operations

extension Buffer.Slots where S: ~Copyable {
    /// Fills all metadata slots with the given value.
    ///
    /// Metadata is `BitwiseCopyable`, so initializing over a previously
    /// initialized slot is a plain overwrite — the fill is valid both for
    /// fresh (uninitialized) and for in-use metadata planes. The lane plane
    /// and metadata type are recovered through the same-type pin.
    @inlinable
    public mutating func fill<M: BitwiseCopyable, E: ~Copyable>(metadata value: M)
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        var slot: Index<M> = .zero
        let end = header.capacity.retag(M.self).map(Ordinal.init)
        while slot < end {
            storage.lanes.initialize(at: slot, to: value)
            slot += .one
        }
    }

    /// Deinitializes element slots where metadata indicates occupancy.
    ///
    /// The consumer must call this before dropping a buffer containing
    /// initialized non-`BitwiseCopyable` elements.
    ///
    /// - Parameter isOccupied: Returns `true` for metadata values that
    ///   indicate the corresponding element slot is initialized.
    @inlinable
    public mutating func deinitialize<M, E: ~Copyable>(where isOccupied: (M) -> Bool)
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        var slot: Index<E> = .zero
        let end = header.capacity.map(Ordinal.init)
        while slot < end {
            if isOccupied(storage.lanes[slot.retag(M.self)]) {
                _ = storage.move(at: slot)
            }
            slot += .one
        }
        storage.elements.initialization = .empty
    }
}

// MARK: - Metadata region access (span-derived; the depointer surface)
//
// The lanes plane is fully initialized for its whole life, so its count-bounded span covers
// `[0, capacity)`. The prior RETURNING pointer escape hatches (`metadataPointer()` /
// `pointer(at:)`) predate the depointer arc and are WITHDRAWN — consumers use the scoped forms
// (or the seam) instead.

extension Buffer.Slots where S: ~Copyable {
    /// Calls `body` with a pointer to the contiguous metadata array.
    ///
    /// Use this for SIMD operations on metadata (e.g., Swiss-table control byte scanning).
    @inlinable
    public func withMetadataPointer<M: BitwiseCopyable, E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (UnsafePointer<M>) throws(Failure) -> R
    ) throws(Failure) -> R
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        try storage.withLanes { lanes throws(Failure) -> R in
            let span = lanes.span
            return try unsafe span.withUnsafeBufferPointer { buffer throws(Failure) -> R in
                // The lanes plane is allocated for `capacity` metadata slots and stays fully
                // initialized for its whole life, so a non-empty slots buffer always has a
                // non-nil base; SIMD control-byte scanning needs the raw base pointer.
                // swift-format-ignore: NeverForceUnwrap
                try unsafe body(buffer.baseAddress!)
            }
        }
    }

    /// Calls `body` with a mutable pointer to the contiguous metadata array.
    @inlinable
    public mutating func withMutableMetadataPointer<M: BitwiseCopyable, E: ~Copyable, R, Failure: Swift.Error>(
        _ body: (UnsafeMutablePointer<M>) throws(Failure) -> R
    ) throws(Failure) -> R
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        try storage.withMutableLanes { lanes throws(Failure) -> R in
            var span = lanes.mutableSpan
            return try unsafe span.withUnsafeMutableBufferPointer { buffer throws(Failure) -> R in
                // The lanes plane is allocated for `capacity` metadata slots and stays fully
                // initialized for its whole life, so a non-empty slots buffer always has a
                // non-nil base; SIMD control-byte scanning needs the raw base pointer.
                // swift-format-ignore: NeverForceUnwrap
                try unsafe body(buffer.baseAddress!)
            }
        }
    }
}
