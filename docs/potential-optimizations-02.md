# Potential Optimizations (Round 2)

Following an analysis of the generated WAT files in `testdata/`, several specific areas for optimization have been identified. These focus on code efficiency, size reduction, and runtime performance.

## 1. Short-Circuiting Logic in Inline Caches

**Observation:**
The current implementation of inline caches (e.g., `$add_cached`, `$get_field_cached`) uses `i32.and` to combine type checks. In WebAssembly, `i32.and` is a bitwise operator and evaluates both operands eagerly. This means that even if the first check fails, the second check (and any associated side effects or costs, though minimal here) is still performed.

**Example (`add.wat`):**
```wat
(func $add_cached ...
  (if (result anyref)
   (i32.and
    (i32.eq (call $get_type_id (local.get $lhs)) ...)
    (i32.eq (call $get_type_id (local.get $rhs)) ...)
   )
   (then ...)
   (else ...)
  )
)
```

**Proposed Optimization:**
Replace bitwise `i32.and` with nested `if` blocks or a sequence of `br_if` instructions to implementing short-circuiting. This avoids the second type check if the first one fails.

**Optimized Pattern:**
```wat
(block $slow_path
  (block $fast_path
    (br_if $slow_path (i32.ne (call $get_type_id (local.get $lhs)) ...))
    (br_if $slow_path (i32.ne (call $get_type_id (local.get $rhs)) ...))
    ;; Fast path code
    (return (call_ref $BinaryOpFunc ...))
  )
)
;; Slow path code
(call $add_slow ...)
```

## 2. Redundant Type Casts (`ref.as_non_null`)

**Observation:**
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

**Proposed Optimization:**
If the type of the local or the return type of the function providing the value is already a non-nullable reference (e.g., `(ref $Object)`), the explicit `ref.as_non_null` instruction should be omitted. This reduces code size and validation overhead.

## 3. Redundant Instructions (`drop (ref.null none)`)

**Status:** Partially Implemented / Mitigated
**Update:** The compiler now propagates a `dropResult` flag to expressions and statements. Void-returning functions like `console.log` and control flow structures like `if` now generate appropriate void-typed Wasm instructions when their result is not used, avoiding the generation of `(ref.null none)` followed by `drop`. However, some fallback cases or implicit returns might still trigger this pattern.

**Observation (Original):**
There are numerous occurrences of `(drop (ref.null none))` in the generated code. This likely results from compilation of statements that don't produce a value (like expression statements) where the compiler pushes a "void" value and then drops it.

**Example (`add.wat`):**
```wat
(drop
 (ref.null none)
)
```

**Proposed Optimization:**
The compiler should be aware of when it is in a "void" context and simply not emit the `ref.null none` followed by `drop`. Alternatively, a peephole optimization pass could remove these sequences.

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
