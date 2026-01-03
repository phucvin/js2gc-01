# Compile JS to Wasm GC - Prototype 01

A basic compiler structure that compiles simple JavaScript to WebAssembly Text (WAT) format using Wasm GC and stringref features.

## Prerequisites

- Node.js (with `--experimental-wasm-stringref` support)
- TypeScript

## Usage

### Compilation

The compiler is located in `src/compiler.ts`. It exports a `compile` function that takes JavaScript source code string and returns a WAT string.

### Running Tests

To run the tests:

1.  Compile the TypeScript files and run the test runner:

    ```bash
    node --experimental-wasm-stringref node_modules/ts-node/dist/bin.js scripts/run_testdata.ts
    ```

    The runner will:
    -   Scan `testdata/` for `.js` files.
    -   Compile each file to WAT.
    -   Use `binaryen` to convert WAT to Wasm binary.
    -   Execute the Wasm binary.
    -   Write the output to `.out` files in `testdata/`.

## Benchmarks

To run benchmarks:

1.  Build the benchmark runner:

    ```bash
    node scripts/build_benchmark.js
    ```

    This creates a self-contained `bench_runner.js` file.

2.  Run the benchmark:

    ```bash
    node --experimental-wasm-stringref bench_runner.js
    ```

    To run in JIT-less mode (skips WebAssembly):

    ```bash
    node --jitless bench_runner.js
    ```

This runs a few iterations of each benchmark (min of 5) for both Wasm (if available) and JS and compares the execution time.

## Benchmark Results

| Benchmark | JS (ms) | Wasm IC (ms) | Wasm No IC (ms) | Ratio Wasm(IC)/JS | Ratio Wasm(NoIC)/JS |
|---|---|---|---|---|---|
| fib.js | 621.5900 | 1229.2600 | 1352.9100 | 1.98 | 2.18 |
| field_access.js | 1.5000 | 3.0300 | 3.8000 | 2.02 | 2.53 |
