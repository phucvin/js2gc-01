# Potential Optimizations

This document outlines potential optimizations identified by analyzing the generated WebAssembly (WAT) files in the `testdata/` directory.

## Runtime Optimizations

### 1. String Pooling and Constants
**Observation:**
The runtime (e.g., `console.log`) constructs new string objects every time it needs to print a constant string (like "null", "true", "[object Object]").

**Optimization:**
-   **Deduplication:** Allocate constant strings once in a global or static array during module initialization.
-   **Reuse:** Reuse these references instead of allocating new arrays on every call.

### 2. Efficient String Construction
**Observation:**
Strings are currently constructed character-by-character using `array.new_fixed` with immediate `i32.const` values, which bloats the binary size for longer strings.


**Status:**
Implemented.

**Optimization:**
-   **Data Segments:** Use `array.new_data` (if supported) or `memory.init` to initialize arrays from a passive data segment. This is more compact for longer strings.

### 3. Shared Runtime Module
**Observation:**
Each generated WAT file includes a full copy of the runtime helper functions (`$console_log`, `$get_type_id`, `$add_slow`, etc.) and type definitions.

**Optimization:**
-   **Shared Library:** Extract these helpers into a shared runtime module (e.g., `runtime.wasm`) and import them. This significantly reduces the size of generated binaries.
-   **Dead Code Elimination:** Only emit types and helpers that are actually referenced by the user's code.

### 4. Dispatch Logic in `console.log` (Polymorphism)
**Observation:**
`$console_log` uses a cascade of `if/else` blocks with `ref.test`.

**Optimization:**
-   **`br_on_cast`:** Use `br_on_cast` to combine the check and the cast, branching to specific handlers.
-   **Dispatch Table:** For many types, a dispatch table based on type ID could be faster.

### 5. Inline Cache Improvements
**Observation:**
The inline cache mechanism loads the object's shape to compare it. If the check fails, it often falls back to a slow path that re-loads the shape.

**Status:**
Short-circuiting logic using `br_if` has been implemented for basic checks, replacing eager `i32.and`.

**Optimization:**
-   **Reuse Loaded Shape:** Reuse the loaded shape (via `local.tee`) when passing control to the slow path helper to avoid redundant memory access.

## Compiler / Code Generation Optimizations

### 1. Object Literal Construction
**Observation:**
Object literals are constructed at runtime by building the shape chain step-by-step.

**Optimization:**
-   **Pre-computed Shapes:** For static object literals, pre-compute the final shape layout.
-   **Shape Caching:** Store the resulting shape in a global variable if the object literal is in a frequently executed path.
-   **Inlining:** The compiler currently inlines empty object creation. This can be extended to populated objects.

### 2. Redundant Type Casts (`ref.as_non_null`)
**Observation:**
The compiler emits `ref.as_non_null` on values locally known to be non-nullable (e.g., immediately after `struct.new` or `array.new`).

**Status:**
Partially implemented. `local.tee` is now used for object literal and closure initialization. `local.set`/`struct.new` sequences for empty objects have been removed.

**Optimization:**
-   **Stack Usage:** Use `local.tee` to pass the result of constructors directly to consumers on the stack, utilizing the non-nullable return type of the constructor.
-   **Strict Locals:** Use `(ref $T)` typed locals or `let` blocks where possible to maintain non-nullability without casts.

### 3. Temporary Locals and Stack Usage
**Observation:**
The compiler generates many temporary locals (`$temp_0`, etc.) to hold intermediate results.

**Optimization:**
-   **Chaining:** Utilize the WebAssembly stack machine more effectively. Chain calls (like `obj.method().field`) without intermediate `local.set`/`local.get`.
-   **Drop Redundancy:** Ensure void-returning statements do not generate `(ref.null none)` followed by `drop` (Partially mitigated by `dropResult` flag).

### 4. Optimize Type Checks with `br_on_cast`
**Observation:**
Polymorphic code often checks a type with `ref.test` then casts with `ref.cast`.

**Optimization:**
-   Use `br_on_cast` to perform both in one step, branching on success or failure as appropriate for the control flow.

### 5. Optimize `struct.get` chains
**Observation:**
Deep property access involves multiple function calls.

**Optimization:**
-   Inline trivial property accessors to allow the engine's JIT to optimize the `struct.get` chain directly.

### 6. Use Non-Nullable Fields in Structures
**Observation:**
Structures like `$Closure` use nullable fields (`funcref`) even when they are always populated.

**Optimization:**
-   Use `(ref func)` or specific function types in struct definitions to avoid runtime null checks.

### 7. Specialized Int32 Arithmetic
**Observation:**
Arithmetic operations often box operands into `i31ref` or `BoxedI32` unnecessarily for local calculations.

**Optimization:**
-   Keep values as raw `i32` on the stack or in locals as long as possible. Only box when storing to `anyref` or passing to generic functions.
