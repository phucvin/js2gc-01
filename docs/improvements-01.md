# Improvements 01

This document outlines potential improvements for the repository, focusing on code organization, documentation, testing, and automation.

## 1. Refactoring `src/compiler`

The current compiler implementation is functional but can be improved for maintainability and scalability.

### 1.1 Extract Runtime Helpers
**Issue:** `src/compiler/index.ts` contains a large block of string-concatenated WAT code for runtime helpers (`$new_object`, `$put_field`, `$get_field_resolve`, `$console_log`, etc.).
**Improvement:**
-   Move these runtime definitions into a separate file, e.g., `src/compiler/runtime.ts` or `src/compiler/builtins.ts`.
-   Consider defining them in a structured way (e.g., a map of function names to their WAT bodies) to allow easier management and potential selective inclusion (dead code elimination).
-   Alternatively, write them in a `.wat` file and load them as a string constant.

### 1.2 Modularize AST Compilation
**Issue:** `src/compiler/expression.ts` is growing large with many `if/else` blocks for different expression types.
**Improvement:**
-   Use a visitor pattern or a dispatch map keyed by `ts.SyntaxKind` to handle expression compilation.
-   Split complex expression compilers (like `BinaryExpression` or `CallExpression`) into their own functions or files.

### 1.3 WAT Generation
**Issue:** Manual string concatenation for WAT generation is error-prone and hard to read.
**Improvement:**
-   Create a `WatEmitter` class or helper module to manage indentation, S-expression formatting, and instruction emission.
-   Alternatively, use the `binaryen` JS API directly for code generation instead of text, which would validate types earlier and avoid parsing overhead, although this is a significant rewrite. Sticking to text generation with a better abstraction is a good middle ground.

## 2. Testing Infrastructure

### 2.1 Granular Unit Tests
**Issue:** Tests currently run on full `.js` files via `scripts/run_testdata.ts`. Debugging specific compiler logic (e.g., how a `for` loop is compiled) is difficult.
**Improvement:**
-   Add unit tests for `compileExpression` and `compileStatement`.
-   Use a test runner like `mocha` or `jest`.
-   Test cases should assert that specific JS snippets compile to expected WAT patterns or execute correctly in isolation.

### 2.2 Integration Test Runner
**Issue:** `scripts/run_testdata.ts` is a custom script.
**Improvement:**
-   Integrate it with the standard test runner.
-   Add capabilities to filter tests (e.g., `npm test -- -g "fib"`).

## 3. Automation and Scripts

### 3.1 Shared Utilities
**Issue:** `scripts/run_testdata.ts` and `scripts/run_benchmark.ts` share logic (compilation, file finding, Wasm execution helpers) but duplicate code.
**Improvement:**
-   Create `scripts/utils.ts` or `src/runner/utils.ts` to host shared logic:
    -   `compileToWasm(source: string, options)`
    -   `runWasm(binary: Uint8Array, imports)`
    -   `findFiles(dir: string, ext: string)`

### 3.2 Linting and Formatting
**Issue:** No linting configuration is present.
**Improvement:**
-   Add `eslint` and `prettier`.
-   Add `npm run lint` and `npm run format` scripts to `package.json`.
-   Enforce code style in CI/CD.

## 4. Documentation

### 4.1 Architecture Documentation
**Issue:** `README.md` is minimal. `docs/potential-optimizations-01.md` covers optimizations but not the system design.
**Improvement:**
-   Create `docs/architecture.md` describing:
    -   The compilation pipeline (Parse -> Traverse -> Generate WAT -> Binaryen Optimize -> Emit).
    -   The object model (Shapes, Storage, Prototypes).
    -   The calling convention (boxing/unboxing).

### 4.2 Developer Guide
**Issue:** No instructions for contributing.
**Improvement:**
-   Add `CONTRIBUTING.md`.
-   Explain how to add a new feature (e.g., "To add a new operator: 1. Update `expression.ts`, 2. Add helper in `runtime.ts`...").

## 5. Feature & Performance

### 5.1 Shared Runtime Module (High Priority)
**Issue:** As noted in `potential-optimizations-01.md`, every output file contains the full runtime.
**Improvement:**
-   Implement the "Shared Runtime Module" strategy.
-   Compile the runtime helpers once to `runtime.wasm`.
-   Link user code against this module or concatenate them intelligently.

### 5.2 CI/CD
**Issue:** No automated testing pipeline.
**Improvement:**
-   Add a `.github/workflows/test.yml` file to run tests and linters on PRs.
