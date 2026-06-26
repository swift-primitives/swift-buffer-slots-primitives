import Affine_Primitives_Standard_Library_Integration
public import Buffer_Primitive
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Contiguous_Primitives
public import Store_Split_Primitives

// CoW (`ensureUnique`) is withdrawn at this tier per R-1: the buffer is move-only over the
// move-only substrate; value semantics enter at the ADT tier via the ratified `Shared` column.
// What remains here is genuinely Copyable-element-only and CoW-free.

// MARK: - Payload Subscript (Copyable Only)

extension Buffer.Slots where S: ~Copyable, S.Element: Copyable {
    /// Reads or writes the element at the given slot.
    ///
    /// - Precondition: The slot must contain an initialized element.
    @inlinable
    public subscript(payload slot: Index<S.Element>) -> S.Element {
        get { storage[slot] }
        set { storage[slot] = newValue }
    }
}

// MARK: - Bulk Payload Fill (BitwiseCopyable)

extension Buffer.Slots where S: ~Copyable {
    /// Fills all element slots with the given value.
    ///
    /// `BitwiseCopyable` elements make initializing over a previously
    /// initialized slot a plain overwrite, so the fill is valid both for
    /// fresh (uninitialized) and for in-use element planes. The elements
    /// ledger is reset to `.empty` (the untracked discipline).
    @inlinable
    public mutating func fill<M: BitwiseCopyable, E: BitwiseCopyable>(payload value: E)
    where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        var slot: Index<E> = .zero
        let end = header.capacity.map(Ordinal.init)
        while slot < end {
            storage.initialize(at: slot, to: value)
            slot += .one
        }
        storage.elements.initialization = .empty
    }
}
