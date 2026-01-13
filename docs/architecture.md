# Architecture

## Overview

This project implements a compiler that transforms a subset of JavaScript (TypeScript AST) into WebAssembly (Wasm) with Garbage Collection (GC) extensions. It targets execution on Wasm engines that support the GC proposal (e.g., V8, Wasmtime).

## Pipeline

1.  **Parsing**: The input JavaScript code is parsed using the TypeScript compiler API (`ts.createSourceFile`).
2.  **Compilation Context**: A `CompilationContext` manages the scope, locals, captured variables for closures, and string/shape pools.
3.  **Traveral & Code Generation**:
    -   The AST is traversed recursively.
    -   Statements and expressions are translated into WebAssembly Text format (WAT) strings.
    -   Runtime helpers (e.g., object creation, field access) are injected.
4.  **Binaryen Optimization**: The generated WAT is parsed by `binaryen`, validated, and optimized (currently minimal optimization).
5.  **Emission**: The final Wasm binary is emitted.

## Object Model

The runtime implements a dynamic object system using Wasm GC structs and arrays.

### Types

-   **$Object**: A struct containing a `$shape` and `$storage`.
-   **$Shape**: A linked list (struct) describing the object layout (Hidden Class). It maps property names (ids) to storage offsets.
-   **$Storage**: An array of `anyref` storing the property values.
-   **$String**: An array of `i8` (UTF-8 bytes).
-   **$Closure**: A struct containing a function reference and an environment object.

### Inline Caching

Property access (`obj.prop`) and binary operations (`a + b`) use Inline Caching (IC) to optimize performance.

-   **CallSites**: Global structs store the last seen shape/type and the target offset/function.
-   **Fast Path**: The compiled code checks if the current object's shape matches the cached shape. If so, it accesses the storage directly.
-   **Slow Path**: If the check fails, it calls a runtime helper to resolve the property, update the cache, and return the value.

## Calling Convention

-   **Boxing**: All values are passed as `anyref`.
    -   Small integers -> `i31ref`.
    -   Doubles -> `$BoxedF64` struct.
    -   Large integers -> `$BoxedI32` struct.
    -   Objects/Strings -> Cast to `$Object` / `$String`.
-   **Return**: Functions return `anyref`. `undefined` is represented as `null`.

## Runtime

The runtime (`src/compiler/runtime.ts`) provides helper functions for:
-   `$new_object`: creating objects.
-   `$put_field` / `$get_field`: property access.
-   `$add`, `$sub`: arithmetic operations with type dispatch.
-   `$console_log`: printing values.
