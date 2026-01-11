# Compile JS to Wasm GC - Prototype 01

A basic compiler structure that compiles simple JavaScript to WebAssembly Text (WAT) format using Wasm GC and stringref features.

## Prerequisites

- Node.js
- TypeScript

## Usage

### Compilation

The compiler is located in `src/compiler.ts`. It exports a `compile` function that takes JavaScript source code string and returns a WAT string.

### Running Tests

To run the tests:

1.  Compile the TypeScript files and run the test runner:

    ```bash
    node node_modules/ts-node/dist/bin.js scripts/run_testdata.ts
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
    node bench_runner.js
    ```

    To run in JIT-less mode (skips WebAssembly):

    ```bash
    node --jitless bench_runner.js
    ```

This runs a few iterations of each benchmark (min of 5) for both Wasm (if available) and JS and compares the execution time.

## Benchmark Results

| Benchmark | JS (ms) | Wasm IC (ms) | Wasm No IC (ms) | Ratio Wasm(IC)/JS | Ratio Wasm(NoIC)/JS |
|---|---|---|---|---|---|
| fib.js | 55872.5120 | 5326.0084 | 5227.3772 | 0.10 | 0.09 |
| field_access.js | 4.5051 | 20.4472 | 28.2133 | 4.54 | 6.26 |
