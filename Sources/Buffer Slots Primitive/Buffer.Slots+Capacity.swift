import Affine_Primitives_Standard_Library_Integration
public import Buffer_Primitive
public import Index_Primitives
public import Memory_Allocator_Primitive
public import Memory_Heap_Primitives
import Ordinal_Primitives_Standard_Library_Integration
public import Storage_Contiguous_Primitives
public import Store_Split_Primitives

// MARK: - Public Init + Capacity

extension Buffer.Slots where S: ~Copyable {
    /// Creates a fixed-capacity slots buffer.
    ///
    /// All metadata slots are initialized to `metadataInitial`.
    /// Element slots are uninitialized — the consumer must initialize
    /// them before reading and deinitialize them before dropping. The
    /// dual-plane split substrate is built directly here; the planes and
    /// metadata type are recovered through the same-type pin.
    @inlinable
    public init<M: BitwiseCopyable, E: ~Copyable>(
        capacity: Index<E>.Count,
        metadataInitial: M
    ) where S == Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>> {
        var lanes = Storage<Memory.Allocator<Memory.Heap>>.Contiguous<M>.create(minimumCapacity: capacity.retag(M.self))
        var slot: Index<M> = .zero
        let end = capacity.retag(M.self).map(Ordinal.init)
        while slot < end {
            lanes.initialize(at: slot, to: metadataInitial)
            slot += .one
        }
        self.init(
            header: Header(capacity: capacity),
            storage: Store.Split(
                lanes: lanes,
                elements: Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>.create(minimumCapacity: capacity)
            )
        )
    }

    /// The number of slots.
    @inlinable
    public var capacity: Index<S.Element>.Count { header.capacity }
}
