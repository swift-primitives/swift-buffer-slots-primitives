import Ordinal_Primitives_Standard_Library_Integration
import Affine_Primitives_Standard_Library_Integration
public import Buffer_Growth_Primitives

// MARK: - Public Init + Capacity

extension Buffer.Slots where Element: ~Copyable {
    /// Creates a fixed-capacity slots buffer.
    ///
    /// All metadata slots are initialized to `metadataInitial`.
    /// Element slots are uninitialized — the consumer must initialize
    /// them before reading and deinitialize them before dropping.
    @inlinable
    public init(capacity: Index<Element>.Count, metadataInitial: Metadata) {
        let storage = Storage<Element>.Split<Metadata>.create(
            capacity: capacity,
            laneInitial: metadataInitial
        )
        self.init(
            header: Header(capacity: storage.header.capacity),
            storage: storage
        )
    }

    /// The number of slots.
    @inlinable
    public var capacity: Index<Element>.Count { header.capacity }
}
