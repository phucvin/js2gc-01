# Potential Optimizations (Round 3)

Analysis of the generated WAT files in `testdata/` reveals several opportunities for advanced optimizations, particularly focusing on type system usage, constant handling, and instruction selection.

## 1. Optimize Type Checks with `br_on_cast`

**Observation**:
The `console.log` implementation (and likely other polymorphic functions) uses a sequence of `ref.test` followed by `ref.cast`.

```wat
(if (ref.test (ref $BoxedI32) (local.get $val))
  (then
    (call $print_i32
      (struct.get $BoxedI32 0
        (ref.cast (ref $BoxedI32) (local.get $val)) ;; Redundant type check implied here
      )
    )
  )
)
```

**Improvement**:
Use `br_on_cast` (or `br_on_cast_fail`) to combine the check and the cast. This reduces code size and execution overhead.

```wat
(block $not_i32
  (call $print_i32
    (struct.get $BoxedI32 0
      (br_on_cast $not_i32 (local.get $val) (ref $BoxedI32)) ;; Branches to $not_i32 if cast fails
      ;; If we are here, the value is casted and on the stack
    )
  )
  (return) ;; or break
)
;; Handle next type
```

## 2. Constant String Deduplication

**Observation**:
Functions like `$console_log` generate new string arrays for constant values every time they are called.

```wat
(call $print_string_helper
  (array.new_fixed $String 4
    (i32.const 110) ;; 'n'
    (i32.const 117) ;; 'u'
    (i32.const 108) ;; 'l'
    (i32.const 108) ;; 'l'
  )
)
```

**Improvement**:
Allocate constant strings ("null", "true", "false", "[object Object]") once during module initialization (e.g., in a `$start` function or lazy-initialized global) and store them in immutable globals.

## 3. Compact String Initialization with `array.new_data`

**Observation**:
String literals are currently compiled using `array.new_fixed`, which requires an `i32.const` instruction for every byte. This bloats the binary size for longer strings.

```wat
(array.new_fixed $String 11
  (i32.const 104) ;; 'h'
  (i32.const 101) ;; 'e'
  ...
)
```

**Improvement**:
Use data segments and `array.new_data` to initialize strings from static data.

```wat
(data $hello_data "hello world")
...
(array.new_data $String $hello_data (i32.const 0) (i32.const 11))
```

## 4. Short-Circuiting Shape Checks in Inline Caches

**Observation**:
The inline cache mechanism loads the object's shape to compare it, and if the check fails, falls back to `$get_field_slow`. The slow path likely re-loads the shape from the object.

```wat
(if (ref.eq (struct.get $Object $shape (local.get $obj)) (struct.get $CallSite $expected_shape ...))
  (then ...)
)
(call $get_field_slow (local.get $obj) ...)
```

**Improvement**:
Reuse the loaded shape using `local.tee` or by passing it to the slow path helper. This avoids a redundant memory access on cache misses.

## 5. Avoid Redundant `ref.as_non_null`

**Observation**:
The compiler frequently emits `ref.as_non_null` on values that are locally known to be non-null, or immediately after a constructor call that returns a non-null reference (assigned to a nullable local).

```wat
(local.set $temp_0 (call $new_object ...)) ;; returns (ref $Object)
(call $set_storage (ref.as_non_null (local.get $temp_0)) ...)
```

**Improvement**:
1. Use `(ref $T)` typed locals where possible (requires initialization).
2. Use `local.tee` to pass the result of `$new_object` directly to `$set_storage` before storing it in `$temp_0`, utilizing the stack's non-nullable type info.
3. Use `let` blocks to introduce strictly-typed locals for temporary values.

## 6. Optimize `struct.get` chains

**Observation**:
Deep property access or nested struct access often involves multiple function calls and temporary locals.

**Improvement**:
Inline trivial property accessors (like `$get_field_cached` for hit cases) to allow the engine's JIT to see the direct `struct.get` chain, enabling better optimization (e.g., hoisting checks out of loops).

## 7. Use Non-Nullable Fields in Structures

**Observation**:
The `$Closure` struct uses `funcref` (nullable) for the function pointer.
`(type $Closure (struct (field $func funcref) ...))`

**Improvement**:
If closures always have a function, use `(ref func)` or a specific function type. This avoids runtime null checks when invoking the closure.

## 8. Specialized Int32 Arithmetic

**Observation**:
Arithmetic operations often box operands into `i31ref` or `BoxedI32` even for local calculations that don't escape.

**Improvement**:
Keep values as raw `i32` on the stack or in `i32` locals as long as possible. Only box them when they need to be stored in an `anyref` container or passed to a polymorphic function.
