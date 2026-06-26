import Buffer_Primitive
import Buffer_Slots_Primitives
import Buffer_Slots_Primitives_Test_Support
import Storage_Contiguous_Primitives
import Store_Split_Primitives
import Testing

// Buffer.Slots is generic over its dual-plane split substrate `S` (b-pin:
// `Buffer<Store.Split<Storage<…System>.Contiguous<Metadata>, Storage<…System>.Contiguous<Element>>>.Slots`).
// Per [TEST-004] we use the parallel namespace pattern — @Suite in extensions of
// generic type specializations is silently not discovered by Swift Testing.
//
// The canonical tower under test has element type `Int` and metadata type `UInt8`
// (the Swiss-table control-byte shape). Aliased for readability; the dual-plane
// operations recover the metadata type through the same-type pin on `S`.
private typealias Slots = Buffer<Store.Split<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<UInt8>, Storage<Memory.Allocator<Memory.Heap>>.Contiguous<Int>>>.Slots

@Suite("Buffer.Slots")
struct SlotsTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
    @Suite struct Integration {}
}

// MARK: - Unit

extension SlotsTests.Unit {

    @Test
    func `init creates buffer with requested capacity`() {
        let capacity: Index<Int>.Count = 8
        let buffer = Slots(capacity: capacity, metadataInitial: 0x80)
        #expect(buffer.capacity == capacity)
    }

    @Test
    func `metadata subscript reads initial value`() {
        let buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 0
        #expect(buffer[metadata: slot] == 0x80)
    }

    @Test
    func `metadata subscript writes and reads back`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 2
        buffer[metadata: slot] = 0x42
        #expect(buffer[metadata: slot] == 0x42)
    }

    @Test
    func `initialize and move round-trips element`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 1
        buffer.initialize(to: 99, at: slot)
        let value = buffer.move(at: slot)
        #expect(value == 99)
    }

    @Test
    func `initialize and deinitialize does not crash`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 0
        buffer.initialize(to: 42, at: slot)
        buffer.deinitialize(at: slot)
    }

    @Test
    func `payload subscript reads initialized element`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 2
        buffer.initialize(to: 77, at: slot)
        #expect(buffer[payload: slot] == 77)
        buffer.deinitialize(at: slot)
    }

    @Test
    func `payload subscript overwrites element`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 1
        buffer.initialize(to: 10, at: slot)
        buffer[payload: slot] = 20
        #expect(buffer[payload: slot] == 20)
        buffer.deinitialize(at: slot)
    }

    @Test
    func `fill metadata overwrites all slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer[metadata: 0] = 0x42
        buffer[metadata: 1] = 0x43
        buffer.fill(metadata: 0xFF)
        #expect(buffer[metadata: 0] == 0xFF)
        #expect(buffer[metadata: 1] == 0xFF)
        #expect(buffer[metadata: 2] == 0xFF)
        #expect(buffer[metadata: 3] == 0xFF)
    }

    @Test
    func `fill payload writes all slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer.fill(payload: 0)
        #expect(buffer[payload: 0] == 0)
        #expect(buffer[payload: 1] == 0)
        #expect(buffer[payload: 2] == 0)
        #expect(buffer[payload: 3] == 0)
        // Clean up — all slots are initialized via fill
        buffer.deinitialize(where: { _ in true })
    }

    @Test
    func `deinitialize where cleans up occupied slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        // Simulate Swiss-table: 0x80 = empty, anything else = occupied
        buffer.initialize(to: 10, at: 0)
        buffer[metadata: 0] = 0x01
        buffer.initialize(to: 20, at: 2)
        buffer[metadata: 2] = 0x02
        // Slots 1 and 3 remain uninitialized (metadata 0x80)
        buffer.deinitialize(where: { $0 != 0x80 })
    }

    @Test
    func `withMetadataPointer provides contiguous access`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer[metadata: 1] = 0x42
        buffer[metadata: 3] = 0x43

        let result = unsafe buffer.withMetadataPointer { ptr in
            (unsafe ptr[0], unsafe ptr[1], unsafe ptr[2], unsafe ptr[3])
        }
        #expect(result.0 == 0x80)
        #expect(result.1 == 0x42)
        #expect(result.2 == 0x80)
        #expect(result.3 == 0x43)
    }

    @Test
    func `withMutableMetadataPointer allows mutation`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)

        unsafe buffer.withMutableMetadataPointer { ptr in
            unsafe ptr[0] = 0xAA
            unsafe ptr[1] = 0xBB
        }
        #expect(buffer[metadata: 0] == 0xAA)
        #expect(buffer[metadata: 1] == 0xBB)
    }

}
// The prior `pointer(at:)` returning escape hatch is WITHDRAWN (depointer arc) and Buffer.Slots
// is MOVE-ONLY per R-1 — their tests are removed; CoW coverage re-materializes at the W4 ADTs.

// MARK: - Edge Cases

extension SlotsTests.EdgeCase {

    @Test
    func `all metadata initially uniform`() {
        let buffer = Slots(capacity: 8, metadataInitial: 0x80)
        for i: UInt in 0..<8 {
            let slot = Index<Int>(_unchecked: Ordinal(i))
            #expect(buffer[metadata: slot] == 0x80)
        }
    }

    @Test
    func `deinitialize where with no occupied slots is safe`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        // No elements initialized — should be a no-op
        buffer.deinitialize(where: { $0 != 0x80 })
    }

    @Test
    func `deinitialize where with all occupied slots`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x00)
        // metadataInitial 0x00 means "occupied" in our predicate
        buffer.initialize(to: 1, at: 0)
        buffer.initialize(to: 2, at: 1)
        buffer.initialize(to: 3, at: 2)
        buffer.initialize(to: 4, at: 3)
        buffer.deinitialize(where: { $0 == 0x00 })
    }

    @Test
    func `fill metadata then selective overwrite`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        buffer.fill(metadata: 0xFF)
        buffer[metadata: 2] = 0x42
        #expect(buffer[metadata: 0] == 0xFF)
        #expect(buffer[metadata: 1] == 0xFF)
        #expect(buffer[metadata: 2] == 0x42)
        #expect(buffer[metadata: 3] == 0xFF)
    }

    @Test
    func `move leaves slot uninitialized for reuse`() {
        var buffer = Slots(capacity: 4, metadataInitial: 0x80)
        let slot: Index<Int> = 0

        buffer.initialize(to: 100, at: slot)
        let moved = buffer.move(at: slot)
        #expect(moved == 100)

        // Re-initialize the same slot
        buffer.initialize(to: 200, at: slot)
        let moved2 = buffer.move(at: slot)
        #expect(moved2 == 200)
    }
}

// MARK: - Integration

extension SlotsTests.Integration {

    @Test
    func `Swiss-table lifecycle — insert, probe, delete`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: 8, metadataInitial: empty)

        // Insert: slot 3 gets h2=0x42, payload=100
        let slot: Index<Int> = 3
        buffer.initialize(to: 100, at: slot)
        buffer[metadata: slot] = 0x42

        // Probe: find slot via metadata, read payload
        #expect(buffer[metadata: slot] == 0x42)
        #expect(buffer[payload: slot] == 100)

        // Delete: move payload out, mark empty
        let removed = buffer.move(at: slot)
        buffer[metadata: slot] = empty
        #expect(removed == 100)
        #expect(buffer[metadata: slot] == empty)
    }

    @Test
    func `multiple slots occupied simultaneously`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: 8, metadataInitial: empty)

        // Populate slots 0, 2, 5, 7
        let slots: [(Index<Int>, Int, UInt8)] = [
            (0, 10, 0x01),
            (2, 20, 0x02),
            (5, 50, 0x05),
            (7, 70, 0x07),
        ]
        for (slot, value, h2) in slots {
            buffer.initialize(to: value, at: slot)
            buffer[metadata: slot] = h2
        }

        // Verify all occupied
        for (slot, value, h2) in slots {
            #expect(buffer[metadata: slot] == h2)
            #expect(buffer[payload: slot] == value)
        }

        // Verify unoccupied slots still empty
        #expect(buffer[metadata: 1] == empty)
        #expect(buffer[metadata: 3] == empty)
        #expect(buffer[metadata: 4] == empty)
        #expect(buffer[metadata: 6] == empty)

        // Cleanup via deinitialize(where:)
        buffer.deinitialize(where: { $0 != empty })
    }

    @Test
    func `metadata scan via withMetadataPointer`() {
        let empty: UInt8 = 0x80
        var buffer = Slots(capacity: 8, metadataInitial: empty)
        buffer[metadata: 1] = 0x42
        buffer[metadata: 4] = 0x42
        buffer[metadata: 6] = 0x42

        // Scan for matching h2 values
        let matches = unsafe buffer.withMetadataPointer { ptr in
            var result: [Int] = []
            for i in 0..<8 {
                if unsafe ptr[i] == 0x42 {
                    result.append(i)
                }
            }
            return result
        }
        #expect(matches == [1, 4, 6])
    }
}
