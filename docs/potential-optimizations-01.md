# Potential Optimizations

This document consolidates optimization opportunities identified by analyzing generated WebAssembly (WAT) files.

## 1. String Optimizations

### String Pooling and Constants
**Observation:** The runtime currently constructs new string objects (arrays) every time it needs to print or use a constant string (e.g., "null", "true", "false", "[object Object]").
**Optimization:**
-   Allocate constant strings once (e.g., in a global, static array, or lazy-initialized global).
-   Reuse these references instead of allocating new arrays on every call.

### Efficient String Construction
**Observation:** Strings are constructed character-by-character using `array.new_fixed` with immediate `i32.const` values, which bloats binary size for long strings.
**Optimization:**
-   Use `array.new_data` (if supported by the Wasm GC target) or `memory.init` to initialize arrays from a passive data segment.

## 2. Runtime & Code Size

### Shared Runtime Module
**Observation:** Each generated WAT file includes a full copy of runtime helper functions (`$console_log`, `$get_type_id`, `$add_slow`, etc.) and type definitions.
**Optimization:**
-   **Shared Library:** Extract helpers into a shared runtime module (e.g., `runtime.wasm`) and import them.
-   **Dead Code Elimination:** Only emit types and helpers that are actually referenced by the user's code.

### Dispatch Logic (e.g., `console.log`)
**Observation:** `console.log` uses a linear cascade of `if/else` blocks with `ref.test`.
**Optimization:**
-   **Type IDs/Dispatch Table:** Use `br_table` on a type ID or a "printable" interface/method on the base object to dispatch faster.

## 3. Type System & Instruction Selection

### Optimize Type Checks with `br_on_cast`
**Observation:** Polymorphic code often uses `ref.test` followed by `ref.cast`.
**Optimization:**
-   Use `br_on_cast` (or `br_on_cast_fail`) to combine the check and the cast, reducing code size and execution overhead.

### Redundant Type Casts (`ref.as_non_null`)
**Observation:** The compiler frequently generates `ref.as_non_null` casts for values that are structurally guaranteed to be non-nullable (e.g., results of `struct.new`).
**Optimization:**
-   Omit the cast if the source is already typed as non-nullable.
-   Use `(ref $T)` typed locals or stack-based flow to preserve type information.

### Non-Nullable Fields in Structures
**Observation:** Structs like `$Closure` use nullable fields (e.g., `funcref`) where a value is always expected.
**Optimization:**
-   Use non-nullable types (e.g., `(ref func)`) in struct definitions to avoid runtime null checks.

### Short-Circuiting Logic
**Observation:** Inline caches and other logic previously used eager `i32.and`.
**Status:** [Implemented for `$add_cached` and `$sub_cached`] - The compiler now uses `br_if` logic within a `block` to short-circuit.
**Further Optimization:** Apply similar short-circuiting to shape checks in Inline Caches (reuse the loaded shape for the slow path to avoid redundant memory access).

## 4. Stack & Local Variable Management

### Reduce Temporary Locals
**Observation:** The compiler generates many temporary locals (`$temp_0`, etc.) for intermediate results.
**Optimization:**
-   Utilize the WebAssembly stack more effectively (chaining instructions).
-   Use `local.tee` or `let` blocks to handle intermediate values without assigning to scope-level nullable locals.

### Redundant `drop`
**Observation:** `(drop (ref.null none))` was common for void statements.
**Status:** [Partially Implemented] - `dropResult` flag now handles most cases, but some fallback cases may remain.

## 5. Object & Shape Optimizations

### Object Literal Construction
**Observation:** Object literals are built at runtime by incrementally extending shapes.
**Optimization:**
-   **Pre-computed Shapes:** Compute the final shape layout at compile time for static literals.
-   **Shape Caching:** Store the resulting shapes in globals for frequently executed literals.

### Inline Trivial Accessors
**Observation:** Deep property access involves multiple function calls.
**Optimization:**
-   Inline trivial property accessors (like `$get_field_cached` hits) to allow JIT optimizations (like hoisting checks).

## 6. Arithmetic Optimizations

### Specialized Int32 Arithmetic
**Observation:** Arithmetic is often boxed into `i31ref` or `BoxedI32` immediately.
**Optimization:**
-   Keep values as raw `i32` on the stack or in locals as long as possible, only boxing when necessary.
