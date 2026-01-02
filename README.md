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
Found 2 JS benchmarks in /app/benchmark: [ 'fib.js', 'field_access.js' ]

--- Benchmarking fib.js ---
Compiling to WAT...
Wasm Run 1: 5240.2458 ms
Wasm Run 2: 5214.2885 ms
Wasm Run 3: 5220.5750 ms
Wasm Run 4: 5241.9791 ms
Wasm Run 5: 5236.4678 ms
Wasm Output: 102334155
Wasm Best Duration: 5214.2885 ms
JS Run 1: 54933.2429 ms
JS Run 2: 54341.1627 ms
JS Run 3: 55437.2843 ms
JS Run 4: 55577.5332 ms
JS Run 5: 55959.0493 ms
JS Output: 102334155
JS Best Duration: 54341.1627 ms
Ratio (Wasm/JS): 0.10x (Lower is better)
Result: Wasm is 10.42x faster

--- Benchmarking field_access.js ---
Compiling to WAT...
Wasm Run 1: 37.8936 ms
Wasm Run 2: 20.3019 ms
Wasm Run 3: 20.2520 ms
Wasm Run 4: 20.2644 ms
Wasm Run 5: 20.2796 ms
Wasm Output: 1000000
Wasm Best Duration: 20.2520 ms
JS Run 1: 4.5422 ms
JS Run 2: 4.1979 ms
JS Run 3: 4.1953 ms
JS Run 4: 4.1738 ms
JS Run 5: 4.1994 ms
JS Output: 1000000
JS Best Duration: 4.1738 ms
Ratio (Wasm/JS): 4.85x (Lower is better)
Result: JS is 4.85x faster
```
