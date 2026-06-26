// Re-export the `Buffer` namespace + the truthful dual-plane substrate so consumers of
// `Buffer<S>.Slots` resolve the type and spell its Store.Split column without separate
// imports (MemberImportVisibility).
@_exported public import Buffer_Primitive
@_exported public import Memory_Allocator_Primitive
@_exported public import Memory_Heap_Primitives
@_exported public import Storage_Contiguous_Primitives
@_exported public import Store_Split_Primitives
