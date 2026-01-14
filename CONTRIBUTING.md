# Contributing

We welcome contributions!

## Setup

1.  **Install Dependencies**:
    ```bash
    npm install
    ```
2.  **Run Tests**:
    ```bash
    npm test
    ```

## Development Workflow

1.  **Create a Branch**: `git checkout -b my-feature`
2.  **Make Changes**: Modify `src/compiler/` or `scripts/`.
3.  **Lint & Format**:
    ```bash
    npm run lint
    npm run format
    ```
4.  **Add Test Case**: Add a new `.js` file in `testdata/`.
5.  **Verify**: Run `npm test` to ensure your new case passes and no regressions.

## Project Structure

-   `src/compiler/`: Compiler source code.
    -   `index.ts`: Entry point.
    -   `expression.ts`: Expression compilation dispatch.
    -   `expressions/`: Specific expression compilers.
    -   `statement.ts`: Statement compilation.
    -   `runtime.ts`: Wasm runtime helpers.
    -   `context.ts`: Compilation context and scope management.
-   `scripts/`: Automation scripts (build, test, benchmark).
-   `testdata/`: Integration test cases.
-   `benchmark/`: Performance benchmarks.

## Adding a New Feature

Example: Adding a new binary operator (e.g., `*`).

1.  **Update `src/compiler/expressions/binary.ts`**:
    -   Handle `ts.SyntaxKind.AsteriskToken`.
    -   Generate a call to a runtime helper (e.g., `$mul`).
2.  **Update `src/compiler/runtime.ts`**:
    -   Define `$mul` (and `$mul_slow` / `$mul_cached` if needed).
    -   Add `elem declare func` for the new helper.
3.  **Add Test**:
    -   Create `testdata/mul.js` with `console.log(2 * 3);`.
    -   Run `npm test`.
