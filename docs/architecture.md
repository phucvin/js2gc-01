# Architecture

This document describes the high-level architecture of the JS-to-Wasm compiler.

## Overview

The compiler translates a subset of JavaScript (TypeScript AST) into WebAssembly (Wasm) with Garbage Collection (GC) extensions. It targets the WasmGC proposal (structs, arrays).

## Pipeline

1.  **Parse**: TypeScript compiler API (`ts.createSourceFile`) parses the JS source into an AST.
2.  **Traverse**: The compiler iterates over the AST, visiting functions, statements, and expressions.
3.  **Compile**:
    *   **Functions**: `src/compiler/function.ts` compiles function declarations.
    *   **Statements**: `src/compiler/statement.ts` handles control flow (if, block, return, variables).
    *   **Expressions**: `src/compiler/expressions/` handles values, operations, and calls.
4.  **Generate WAT**: The output is a WebAssembly Text (WAT) string.
5.  **Binaryen**: The `binaryen` library parses the WAT, validates it, and emits the binary `.wasm`.

## Object Model

The runtime implements a dynamic object model using WasmGC structs and arrays.

### Shapes (Hidden Classes)

Objects are backed by **Shapes** (similar to V8's hidden classes) to map property names to storage indices.

```wat
(type $Shape (struct
  (field $parent (ref null $Shape))  ;; Parent shape in transition tree
  (field $key i32)                   ;; Property name ID (hash/index)
  (field $offset i32)                ;; Storage index for this property
  (field $proto anyref)              ;; Prototype object
))
```

### Objects

An object consists of a reference to its current Shape and a storage array for values.

```wat
(type $Object (struct
  (field $shape (mut (ref $Shape)))
  (field $storage (mut (ref $Storage)))
))

(type $Storage (array (mut anyref)))
```

### Property Access

1.  **Lookup**: `src/compiler/runtime.ts` defines `$lookup_in_shape` which walks the shape tree to find the offset for a key.
2.  **Inline Caching (IC)**:
    *   **CallSite**: A global struct stores the `$expected_shape`, `$offset`, and `$holder`.
    *   **Fast Path**: If the object's shape matches `$expected_shape`, the storage index `$offset` is used directly.
    *   **Slow Path**: If not, full lookup is performed, and the cache is updated.

## Runtime

The runtime is currently statically linked (concatenated) into every generated module. It includes:
*   **Object Helpers**: `$new_object`, `$put_field`, `$get_field_...`.
*   **Arithmetic**: `$add`, `$sub` (with polymorphic dispatch for i31, f64).
*   **Console**: `$console_log` wrappers.

### Shared Runtime Module Strategy

*Current Status: Monolithic (Runtime included in every module)*

**Planned Strategy:**
To reduce binary size and allow modularity, the runtime should be extracted into a separate Wasm module (`runtime.wasm`).

1.  **Exports**: The runtime module exports helpers like `$new_object`, `$get_field`, and the GC types (`$Object`, `$Shape`).
2.  **Imports**: User code imports these helpers.
3.  **Linking**: A dynamic linker (or host) connects the user module's imports to the runtime module's exports.

*Challenge*: WasmGC types must be canonicalized or nominally equivalent across modules. Using Type Imports/Exports (Wasm proposal) or ensuring identical type definitions in both modules is required. Currently, we duplicate type definitions to ensure compatibility if we were to split them.

## Calling Convention

*   **Values**: All values are passed as `anyref`.
    *   **Integers**: Small integers are `i31ref`. Large integers are boxed in `$BoxedI32`.
    *   **Floats**: Boxed in `$BoxedF64`.
    *   **Strings**: `$String` (array of bytes).
    *   **Objects**: `$Object` (struct).
    *   **Null**: `ref.null any`.
    *   **Undefined**: Treated as `ref.null any` (simplified).

*   **Functions**:
    *   Closures are structs containing the function reference and an environment object.
    *   `call_ref` is used for dynamic invocation.
