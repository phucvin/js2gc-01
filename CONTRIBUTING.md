# Contributing

We welcome contributions to the project!

## Setup

1.  Install dependencies:
    ```bash
    npm install
    ```
2.  Install `binaryen` (handled by npm) and ensuring Node.js is available.

## Running Tests

*   Run all test cases in `testdata/`:
    ```bash
    npm test
    ```
*   Run benchmarks:
    ```bash
    npm run benchmark
    ```

## Development Workflow

1.  **Code Style**: We use `eslint` and `prettier`.
    ```bash
    npm run lint
    npm run format
    ```
2.  **Adding a New Feature**:
    *   If adding a new expression type (e.g. `await`), update `src/compiler/expression.ts`.
    *   If adding a new statement (e.g. `try/catch`), update `src/compiler/statement.ts`.
    *   If adding a runtime helper, update `src/compiler/runtime.ts`.
3.  **Testing**:
    *   Add a new `.js` file in `testdata/` demonstrating the feature.
    *   Run `npm test` to verify it compiles and executes correctly.

## Project Structure

*   `src/compiler/`: Compiler source code.
*   `scripts/`: Build and test scripts.
*   `docs/`: Documentation.
