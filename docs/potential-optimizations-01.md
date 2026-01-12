# Potential Optimizations

This document outlines potential optimizations identified by analyzing the generated WebAssembly (WAT) files in the `testdata/` directory.

## Runtime Optimizations

### 1. String Pooling and Constants
Currently, the `console.log` implementation (and likely other parts of the runtime) constructs new string objects every time it needs to print a constant string.

**Example from `add.wat` (and others):**
```wat
(call $print_string_helper
  (array.new_fixed $String 4
    (i32.const 110) (i32.const 117) (i32.const 108) (i32.const 108) ;; "null"
  )
)
```

**Optimization:**
-   Allocate constant strings (like "null", "[object Object]") once in a global or static array.
-   Reuse these references instead of allocating new arrays on every call.

### 2. Shared Runtime Module
Each generated WAT file includes a full copy of the runtime helper functions (`$console_log`, `$get_type_id`, `$add_slow`, `$new_root_shape`, etc.), even if they are identical across files.

**Optimization:**
-   Extract these helpers into a shared runtime module (e.g., `runtime.wasm`).
-   Import these functions in the generated code instead of embedding them.
-   This would significantly reduce the size of the generated binaries if they were to be distributed or loaded together.

### 3. Efficient String Construction (Implemented)
Strings are constructed using `array.new_data` from passive data segments, which is more compact and efficient than the previous character-by-character `array.new_fixed` approach.

**Old:**
```wat
(array.new_fixed $String 15 (i32.const 91) ... (i32.const 93))
```

**New:**
```wat
(data $str_data_0 "hello world")
...
(array.new_data $String $str_data_0 (i32.const 0) (i32.const 11))
```

*Note: Runtime internal strings (like "null") still use the old method and could be updated to use the same mechanism.*

## Compiler / Code Generation Optimizations

### 1. Object Literal Construction
Object literals are constructed at runtime by building the shape chain step-by-step.

**Current (`object_literal.wat`):**
```wat
(call $new_object
  (call $extend_shape
    (call $extend_shape (call $new_root_shape) ...)
    ...
  )
  ...
)
```

**Optimization:**
-   **Pre-computed Shapes:** For static object literals, the compiler can pre-compute the final shape layout.
-   **Shape Caching:** Store the resulting shape in a global variable if the object literal is in a frequently executed path (like a loop or a function called multiple times), avoiding the reconstruction of the linked list on every execution.

### 2. Redundant Type Casts (`ref.as_non_null`)
The generated code frequently casts a nullable reference to a non-nullable one immediately after assignment or generation, even when control flow guarantees non-nullability.

**Current:**
```wat
(local.set $temp_0 (call $new_object ...)) ;; Returns (ref $Object)
(call $set_storage (ref.as_non_null (local.get $temp_0)) ...)
```

**Optimization:**
-   Trust the type system: `$new_object` returns `(ref $Object)`, which is non-nullable. The local `$temp_0` might be typed as `(ref null $Object)`, necessitating the cast.
-   **Use Stack:** Instead of storing to a local and reading it back, keep the value on the stack.
    ```wat
    (call $set_storage (call $new_object ...) ...)
    ```
    If the value is needed multiple times, `local.tee` can be used, potentially with a more specific local type if possible.

### 3. Temporary Locals
The compiler generates many temporary locals (`$temp_0`, `$temp_1`, etc.) to hold intermediate results of expressions.

**Optimization:**
-   Utilize the WebAssembly stack machine more effectively. Chained calls (like `obj.method().field`) can often be emitted as a sequence of instructions without intermediate `local.set`/`local.get`.

### 4. Dispatch Logic in `console.log`
The `$console_log` function uses a cascade of `if/else` blocks with `ref.test` to determine the type of the value.

**Optimization:**
-   **Type IDs:** Since objects and boxed primitives seem to have distinct internal representations or tags, a dispatch table (using `br_table` on a type ID) could be faster than a linear sequence of checks, especially as the number of types grows.
-   **Polymorphism:** If the object model allows, implementing a "printable" interface or method on the base object structure could allow `call_ref` to dispatch to the correct print function directly.

## Specific Observations

-   **Inline Caching (`loop_field_access.wat`):** The inline cache implementation correctly uses `i32.and` for eager evaluation of shape checks, which is efficient.
-   **Closures (`closure.wat`):** Closure creation allocates both a struct and an object (for the environment). If the environment doesn't escape or is simple, it might be possible to flatten it or use `struct.new` directly without a wrapper object.

## Conclusion
The current implementation is functional and demonstrates good use of Wasm GC features (structs, arrays). The primary areas for optimization are code size reduction (via shared runtime and stack usage) and runtime performance (via string pooling and optimized object construction).
