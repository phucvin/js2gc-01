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

```bash
node --experimental-wasm-stringref node_modules/ts-node/dist/bin.js scripts/run_benchmark.ts
```

This runs a few iterations of each benchmark (min of 5) for both Wasm and JS and compares the execution time.

Latest run:
```
Found 1 JS benchmarks in /app/benchmark: [ 'fib.js' ]

--- Benchmarking fib.js ---
Compiling to WAT...
Wasm Output: 832040
Wasm Duration (min of 5): 44.4756 ms
JS Output: 832040
JS Duration (min of 5): 473.7671 ms
Ratio (Wasm/JS): 0.09x (Lower is better)
Result: Wasm is 10.65x faster
```
