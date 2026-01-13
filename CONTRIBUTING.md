# Contributing

We welcome contributions to the JS-to-Wasm GC compiler!

## Getting Started

1.  **Install Dependencies**:
    ```bash
    npm install
    ```

2.  **Run Tests**:
    ```bash
    npm test
    ```
    This runs `scripts/run_testdata.ts`, which compiles and executes all examples in `testdata/`.

3.  **Run Benchmarks**:
    ```bash
    npm run benchmark
    ```

4.  **Lint & Format**:
    ```bash
    npm run lint
    npm run format
    ```

## Development Workflow

### Project Structure

*   `src/compiler/`: Source code for the compiler.
    *   `index.ts`: Entry point.
    *   `expression.ts`: Expression compilation (literals, binary ops, calls).
    *   `statement.ts`: Statement compilation (if, loops, var decls).
    *   `runtime.ts`: Wasm runtime helper strings.
    *   `context.ts`: Compilation context (symbol table, scope).
*   `testdata/`: JavaScript files for end-to-end testing.
*   `scripts/`: Automation scripts.

### Adding a New Feature

**Example: Adding a new Binary Operator (e.g., `*`)**

1.  **Update `src/compiler/expressions/binary.ts`**:
    *   Add a case for `ts.SyntaxKind.AsteriskToken` in `compileBinaryExpression`.
    *   Emit a call to a runtime helper (e.g., `$mul_slow` or `$mul_cached`).

2.  **Update `src/compiler/runtime.ts`**:
    *   Implement the runtime helper `$mul_slow` (handling types).
    *   Register it in `getRuntimeFunctions`.

3.  **Add a Test Case**:
    *   Create `testdata/multiply.js` with code using `*`.
    *   Run `npm test` to verify.

### Code Style

*   Use `prettier` for formatting.
*   Follow TypeScript best practices.
*   Avoid adding dependencies unless necessary.

## debugging

*   Use `console.log` in your JS test files.
*   Inspect the generated `.wat` files in `testdata/` to understand the compiler output.
