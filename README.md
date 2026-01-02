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
Wasm Run 1: 5557.2238 ms
Wasm Run 2: 5486.5175 ms
Wasm Run 3: 6264.6425 ms
Wasm Run 4: 5478.7530 ms
Wasm Run 5: 5216.0597 ms
Wasm Output: 102334155
Wasm Best Duration: 5216.0597 ms
JS Run 1: 57815.6742 ms
JS Run 2: 54508.8058 ms
JS Run 3: 55819.7594 ms
JS Run 4: 54744.1415 ms
JS Run 5: 57831.8373 ms
JS Output: 102334155
JS Best Duration: 54508.8058 ms
Ratio (Wasm/JS): 0.10x (Lower is better)
Result: Wasm is 10.45x faster

--- Benchmarking field_access.js ---
Compiling to WAT...
Wasm Run 1: 37.2790 ms
Wasm Run 2: 20.6344 ms
Wasm Run 3: 20.4614 ms
Wasm Run 4: 20.3718 ms
Wasm Run 5: 20.2747 ms
Wasm Output: 1000000
Wasm Best Duration: 20.2747 ms
JS Run 1: 4.6383 ms
JS Run 2: 4.1625 ms
JS Run 3: 4.0761 ms
JS Run 4: 4.1181 ms
JS Run 5: 4.0641 ms
JS Output: 1000000
JS Best Duration: 4.0641 ms
Ratio (Wasm/JS): 4.99x (Lower is better)
Result: JS is 4.99x faster
```
