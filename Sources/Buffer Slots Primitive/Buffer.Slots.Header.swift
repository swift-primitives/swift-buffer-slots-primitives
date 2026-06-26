public import Buffer_Primitive
public import Index_Primitives

// MARK: - Header

extension Buffer.Slots where S: ~Copyable {
    /// Pure state for a slots buffer.
    ///
    /// The header is trivial — just capacity. Unlike Linear (count),
    /// Ring (head + count), or Slab (bitmap), Slots has no mutable
    /// cursor state. All state lives in the metadata array.
    @frozen
    public struct Header: Copyable, Sendable {
        /// Total slot capacity.
        public let capacity: Index<S.Element>.Count

        /// Creates a header with the specified capacity.
        @inlinable
        public init(capacity: Index<S.Element>.Count) {
            self.capacity = capacity
        }
    }
}
