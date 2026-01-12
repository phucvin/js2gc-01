# Potential Optimizations 02

This document details the optimizations identified and applied to the WAT files in the `testdata/` directory.

## Findings and Applied Optimizations

### 1. `add_cached` Short-Circuiting

**Found in:** `add.wat`, `add_int_string.wat`, `binary_cache.wat`, `closure.wat`, `closure_return.wat`, `let_primitives.wat`, `loop_field_access.wat`, `method_call.wat`, `method_this.wat`

**Description:**
The original implementation of `$add_cached` used a bitwise `i32.and` to check if both operands matched the cached types. This resulted in eager evaluation of both type checks.

**Optimization:**
Replaced the single `i32.and` condition with a sequence of `br_if` instructions in a block. If the first type check fails, it immediately branches to the slow path, avoiding the second check.

**Original Code:**
```wat
(func $add_cached ...
 (if (result anyref)
  (i32.and
   (i32.eq (call $get_type_id (local.get $lhs)) ...)
   (i32.eq (call $get_type_id (local.get $rhs)) ...)
  )
  (then (call_ref ...))
  (else (call $add_slow ...))
 )
)
```

**Optimized Code:**
```wat
(func $add_cached ...
 (block $slow
  (br_if $slow (i32.ne (call $get_type_id (local.get $lhs)) ...))
  (br_if $slow (i32.ne (call $get_type_id (local.get $rhs)) ...))
  (return (call_ref ...))
 )
 (call $add_slow ...)
)
```

### 2. Removal of Redundant `drop` Instructions

**Found in:** Files generated from code with ignored expressions (e.g., `loop_field_access.wat`).

**Description:**
The compiler often emits `(drop (ref.null none))` for statements that are just expression statements returning `undefined` (which maps to `ref.null none` in some contexts) or empty blocks.

**Optimization:**
Removed `(drop (ref.null none))` sequences as they have no side effects and consume no stack values (since `ref.null` produces one and `drop` consumes it, the net effect is zero, but instruction overhead exists).

### 3. Potential (But Not Applied) Optimizations

#### a. `local.tee` for Object Initialization
**Pattern:**
```wat
(local.set $temp (call $new_object ...))
(call $set_storage (ref.as_non_null (local.get $temp)) ...)
```
**Optimization:**
Could be replaced with:
```wat
(call $set_storage (local.tee $temp (call $new_object ...)) ...)
```
This avoids one `local.get` and potentially the `ref.as_non_null` if types are handled correctly. This was not applied automatically due to the complexity of safely modifying nested expressions via regex.

#### b. String Constant Hoisting
**Pattern:**
`console.log("literal")` generates:
```wat
(call $print_string_helper (array.new_fixed $String ... (i32.const 108) ...))
```
**Optimization:**
Constant strings should be allocated once (in a data segment or a global initialized on module start) and reused, rather than allocating a new array on every call.

#### c. Inline Trivial Functions
Functions like `$a` and `$b` in `add.wat` which return constant values could be inlined.

## Verification

The optimized files were verified using `scripts/run_optimized_wat.ts`, which runs the `.optimized.wat` files and compares their output against the original `.out` files. All 21 files passed verification.
