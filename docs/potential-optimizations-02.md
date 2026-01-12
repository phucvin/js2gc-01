# Potential Optimizations (Round 2)

Following an analysis of the generated WAT files in `testdata/`, several specific areas for optimization have been identified. These focus on code efficiency, size reduction, and runtime performance.

## 1. Short-Circuiting Logic in Inline Caches [Implemented]

**Status:** Implemented
**Update:** The compiler now uses `br_if` logic within a `block` to implement short-circuiting in `$add_cached` and `$sub_cached`. This provides a cleaner control flow structure than nested `if` blocks.

**Observation (Original):**
The current implementation of inline caches (e.g., `$add_cached`, `$get_field_cached`) uses `i32.and` to combine type checks. In WebAssembly, `i32.and` is a bitwise operator and evaluates both operands eagerly.

**Optimized Pattern:**
```wat
(block $slow
  (br_if $slow (i32.ne (call $get_type_id (local.get $lhs)) ...))
  (br_if $slow (i32.ne (call $get_type_id (local.get $rhs)) ...))
  (return (call_ref $BinaryOpFunc ...))
)
(call $add_slow ...)
```

## 2. Redundant Type Casts (`ref.as_non_null`) [Implemented]

**Status:** Implemented
**Update:** The compiler now optimizes the initialization of object literals and closures by using `local.tee` to pass the newly created object (which is non-nullable) directly to the first `call $set_storage`, avoiding one `local.get`.
However, `ref.as_non_null` is still required in some contexts (like arguments to functions expecting non-nullable references) because `local.tee` returns the type of the local (which is nullable `(ref null $Object)`), not the type of the operand, according to Wasm validation rules.
We also completely removed `local.set` / `struct.new` sequence for empty object literals and closures with no captures, directly inlining the `call $new_object`.
And for `CallExpression`, `MethodCall`, and `IndirectCall`, we successfully removed `ref.as_non_null` when passing the result of `local.tee` to `struct.get` (which accepts nullable references).

**Observation (Original):**
The compiler frequently generates `ref.as_non_null` casts for values that are structurally guaranteed to be non-nullable, particularly results from `struct.new` or `array.new`.

**Example (`object_literal.wat`):**
```wat
(local.set $temp_0
 (call $new_object ...) ;; Returns (ref $Object)
)
(call $set_storage
 (ref.as_non_null (local.get $temp_0)) ;; Redundant cast
 ...
)
```

**Optimized Pattern:**
```wat
(call $set_storage
  (ref.as_non_null (local.tee $temp_0 (call $new_object ...)))
  ...
)
```
(Note: `ref.as_non_null` is preserved here for type safety with `call`, but `local.get` is saved. For `struct.get`, `ref.as_non_null` is removed.)

## 3. Redundant Instructions (`drop (ref.null none)`) [Implemented]

**Status:** Partially Implemented / Mitigated
**Update:** The compiler now propagates a `dropResult` flag to expressions and statements. Void-returning functions like `console.log` and control flow structures like `if` now generate appropriate void-typed Wasm instructions when their result is not used, avoiding the generation of `(ref.null none)` followed by `drop`. However, some fallback cases or implicit returns might still trigger this pattern.

**Observation (Original):**
There are numerous occurrences of `(drop (ref.null none))` in the generated code. This likely results from compilation of statements that don't produce a value (like expression statements) where the compiler pushes a "void" value and then drops it.

## 4. Unnecessary Locals and `local.set`/`local.get`

**Observation:**
The compiler tends to assign intermediate results to temporary locals (`$temp_0`, etc.) even when the value is used immediately and could remain on the stack.

**Example (`method_call.wat`):**
```wat
(local.set $temp_2 (local.get $user_obj))
(local.set $temp_3
 (ref.cast (ref $Closure)
  (call $get_field_cached
   (ref.cast (ref $Object) (local.get $temp_2))
   ...
  )
 )
)
```

**Proposed Optimization:**
Implement better stack management in the compiler to chain expressions. For example, `local.get $user_obj` could be used directly by `$get_field_cached` without the intermediate `$temp_2`.

## 5. String Construction Inefficiency

**Observation:**
Strings are constructed by creating an array and populating it with immediate constants for every character.

**Example (`string.wat`):**
```wat
(array.new_fixed $String 11
 (i32.const 104) ;; 'h'
 (i32.const 101) ;; 'e'
 ...
)
```

**Proposed Optimization:**
For static strings, use data segments and `array.new_data` (if supported by the target Wasm GC version) or `memory.init` to copy generic bytes into the array. This is much more compact for longer strings.

## 6. Code Bloat / Shared Runtime

**Observation:**
Every WAT file contains the full definition of all runtime types (`$Shape`, `$Object`, `$Closure`, etc.) and helper functions (`$console_log`, `$add_slow`, etc.), regardless of whether they are all used.

**Proposed Optimization:**
-   **Dead Code Elimination:** Only emit types and helpers that are actually referenced by the user's code.
-   **Shared Library:** As mentioned in previous optimizations, moving these to a separate runtime module that is imported would drastically reduce the size of individual compiled modules.
