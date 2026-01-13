# Potential Optimizations

This document outlines potential optimizations identified by analyzing the generated WebAssembly (WAT) files.

## Pending Optimizations

### 1. Shared Runtime Module
**Observation:**
Each generated WAT file includes a full copy of the runtime helper functions (`$console_log`, `$get_type_id`, `$add_slow`, etc.) and type definitions.

**Optimization:**
-   **Shared Library:** Extract these helpers into a shared runtime module (e.g., `runtime.wasm`) and import them. This significantly reduces the size of generated binaries.
-   **Dead Code Elimination:** Only emit types and helpers that are actually referenced by the user's code.

### 2. Optimize Type Checks with `br_on_cast`
**Observation:**
Polymorphic code often checks a type with `ref.test` then casts with `ref.cast`. While implemented for `console.log`, this pattern is still prevalent in binary operators (e.g., `$add`, `$sub`) and other helpers.

**Optimization:**
-   **Binary Operators:** Update `$add` and `$sub` (and their cached variants) to use `br_on_cast` to combine the check and the cast, branching to specific handlers. This reduces the number of instructions and potential branches.
-   **Dispatch Table:** For many types, a dispatch table based on type ID could be faster.

### 3. Redundant Type Casts (`ref.as_non_null`)
**Observation:**
The compiler emits `ref.as_non_null` on values locally known to be non-nullable (e.g., immediately after `struct.new` or `array.new`).

**Status:**
Partially Implemented. `local.tee` is now used for object literal and closure initialization, but explicit casts remain in other areas (e.g., `call_ref` blocks, `closure` invocation).

**Optimization:**
-   **Strict Locals:** Use `(ref $T)` typed locals or `let` blocks where possible to maintain non-nullability without casts throughout the function body.
-   **Flow Analysis:** Implement basic flow analysis to track non-nullability within a function.

### 4. Temporary Locals and Stack Usage
**Observation:**
The compiler generates many temporary locals (`$temp_0`, etc.) to hold intermediate results, sometimes excessively.

**Status:**
Partially Implemented. `dropResult` logic helps avoid some drops, but `local.set`/`local.get` chains persist.

**Optimization:**
-   **Chaining:** Utilize the WebAssembly stack machine more effectively. Chain calls (like `obj.method().field`) without intermediate `local.set`/`local.get`.

### 5. Optimize `struct.get` chains
**Observation:**
Deep property access involves multiple function calls.

**Optimization:**
-   Inline trivial property accessors to allow the engine's JIT to optimize the `struct.get` chain directly.

### 6. Specialized Int32 Arithmetic
**Observation:**
Arithmetic operations often box operands into `i31ref` or `BoxedI32` unnecessarily for local calculations.

**Optimization:**
-   Keep values as raw `i32` on the stack or in locals as long as possible. Only box when storing to `anyref` or passing to generic functions.

## Implemented / Resolved

### 1. String Pooling and Constants
**Status:** Implemented.
-   Globals are used for "null" and "[object Object]".
-   `registerStringLiteral` deduplicates string literals.

### 2. Efficient String Construction
**Status:** Implemented.
-   Uses `array.new_data` to initialize arrays from passive data segments for constant strings.

### 3. Dispatch Logic in `console.log`
**Status:** Implemented.
-   `$console_log` uses `br_on_cast` blocks to dispatch to the correct printer.

### 4. Inline Cache Improvements (Reuse Loaded Shape)
**Status:** Implemented.
-   `$get_field_cached` reuses the loaded shape (via `local.tee`) when checking against the cache.
-   Short-circuiting logic using `br_if` is implemented for `add` and `sub` caches.

### 5. Object Literal Construction
**Status:** Implemented.
-   **Pre-computed Shapes:** Uses `registerShape` to create global shape definitions for object literals.
-   **Efficient Initialization:** Uses `local.tee` to avoid redundant `local.get` during property assignment.

### 7. Prototype Inheritance with Inline Cache
**Status:** Implemented.
-   **Structure:** `$Shape` now includes `$proto` (prototype). `$CallSite` (Inline Cache) includes `$holder` (the object where the property was found).
-   **Lookup:** `$get_field_resolve` walks the prototype chain if the property is not found on the receiver.
-   **Optimization:** `$get_field_cached` checks the shape. If matched, it uses the cached `$holder` to access the property directly (either on the receiver or the prototype), avoiding the chain traversal in the fast path.

