# Architecture

This document describes the high-level architecture of the `js2gc` compiler.

## Pipeline

The compilation process follows these steps:

1.  **Parsing**: The TypeScript compiler API is used to parse the input JavaScript code into an AST.
2.  **Compilation Context**: A `CompilationContext` is created to track scopes, locals, and captured variables.
3.  **Code Generation**: The AST is traversed, and WebAssembly Text (WAT) is generated.
    *   Statements are compiled via `src/compiler/statement.ts`.
    *   Expressions are compiled via `src/compiler/expression.ts` (and sub-modules).
4.  **Runtime Injection**: The generated WAT is wrapped in a module that includes standard runtime types and helper functions (from `src/compiler/runtime.ts`).
5.  **Binaryen Optimization**: The WAT is parsed by `binaryen.js`, validated, and optimized (currently limited optimizations).
6.  **Emission**: The final WebAssembly binary is emitted.

## Object Model

The compiler implements a dynamic object model using Wasm GC structs and arrays.

### Structs

*   **$Object**: The main object structure.
    *   `$shape`: A reference to a `$Shape` struct describing the object's layout.
    *   `$storage`: An array of `anyref` storing the property values.
*   **$Shape**: Describes the property layout (Hidden Class).
    *   `$parent`: Link to the previous shape (transition chain).
    *   `$key`: The property name ID (integer) added at this transition.
    *   `$offset`: The index in the `$storage` array where this property is stored.
    *   `$proto`: The prototype object for this shape.

### Inline Caching

Property access is optimized using Monomorphic Inline Caches (MIC).

*   **$CallSite**: A struct stored in a global variable for each property access site.
    *   `$expected_shape`: The shape seen previously.
    *   `$offset`: The cached storage index.
    *   `$holder`: The object in the prototype chain that holds the property (or `null` if it's the receiver).

When a property access occurs:
1.  The fast path (`$get_field_cached`) checks if the object's shape matches `$expected_shape`.
2.  If it matches, it directly accesses the `$storage` at `$offset`.
3.  If it misses, it calls `$get_field_slow`, which walks the shape and prototype chain, updates the cache, and returns the value.

## Calling Convention

*   **Values**: All values are passed as `anyref`.
    *   Integers are passed as `i31ref` (unboxed) or `$BoxedI32`.
    *   Floats are passed as `$BoxedF64`.
    *   Strings are `$String` (array of i8).
    *   Objects are `$Object`.
*   **Closures**: Functions are represented as `$Closure` structs containing:
    *   `$func`: The Wasm function reference.
    *   `$env`: The environment object (an `$Object` or array) capturing variables.

## Directory Structure

*   `src/compiler/`: Core compiler logic.
    *   `index.ts`: Entry point.
    *   `context.ts`: Scope and symbol management.
    *   `runtime.ts`: Runtime helpers and type definitions.
    *   `expression.ts` & `expressions/`: Expression compilation.
    *   `statement.ts`: Statement compilation.
*   `scripts/`: Automation scripts (`run_testdata.ts`, `run_benchmark.ts`).
*   `testdata/`: JavaScript test cases.
