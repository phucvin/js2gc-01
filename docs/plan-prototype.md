# Plan for Supporting Prototypes

## Overview

This plan outlines the steps to add prototype support to the JS-to-Wasm compiler. This includes modifying the object structure, updating property lookup logic to traverse the prototype chain, and supporting prototype definition in object literals.

## Steps

### 1. Modify Object Structure
-   **File**: `src/compiler/index.ts`
-   **Task**:
    -   Update the `$Object` struct definition to include a new field: `(field $proto (mut anyref))`.
    -   Update the `$new_object` helper function to accept an additional parameter `$proto` of type `anyref` and initialize the new field.
    -   Type definition:
        ```wat
        (type $Object (struct
          (field $shape (mut (ref $Shape)))
          (field $storage (mut (ref $Storage)))
          (field $proto (mut anyref))
        ))
        ```

### 2. Update Object Creation Call Sites
-   **File**: `src/compiler/expression.ts`
-   **Task**:
    -   Update `compileFunctionExpression`: When creating the environment object (which uses `$new_object`), pass `(ref.null any)` as the prototype.
    -   Update `compileExpressionValue` for `ts.ObjectLiteralExpression`:
        -   Scan properties for `__proto__`.
        -   If found, compile its value and pass it as the `$proto` argument to `$new_object`.
        -   If not found, pass `(ref.null any)`.
        -   Ensure `__proto__` is NOT added as a regular property in the storage/shape.

### 3. Implement Prototype Chain Lookup
-   **File**: `src/compiler/index.ts`
-   **Task**:
    -   Refactor `$get_field_resolve` to support inheritance.
    -   Current logic: Look up key in `$shape`. If found, return value. If not, return `null`.
    -   New logic:
        -   Look up key in current `$shape`.
        -   If found, return value.
        -   If not found:
            -   Load `$proto` from the object.
            -   If `$proto` is `null`, return `undefined` (or `ref.null any`).
            -   If `$proto` is not an `$Object` (should generally be objects, but check type if needed), return `undefined`.
            -   Update current object to `$proto`.
            -   Loop back to shape lookup.
    -   This turns the lookup into a loop walking up the chain.

### 4. Verification
-   **File**: `testdata/prototype.js`
-   **Task**:
    -   Create a test file demonstrating:
        -   Simple inheritance: `obj` inherits `prop` from `proto`.
        -   Chain: `obj -> proto1 -> proto2`.
        -   Shadowing: `obj` has `prop`, `proto` also has `prop`. `obj.prop` should be returned.
        -   `__proto__` syntax in literal: `var o = { __proto__: p }`.

### 5. Execution
-   Run `npm run test` (or `scripts/run_testdata.ts`) to verify.
