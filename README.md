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
    npm install typescript
    npx tsc -p tsconfig.build.json
    node --experimental-wasm-stringref dist/scripts/run_testdata.js
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
npm install typescript
npx tsc -p tsconfig.build.json
node --experimental-wasm-stringref dist/scripts/run_benchmark.js
```

This runs a few iterations of each benchmark (min of 5) for both Wasm and JS and compares the execution time.

## Benchmark Results

| Benchmark | JS (ms) | Wasm IC (ms) | Wasm No IC (ms) | Ratio Wasm(IC)/JS | Ratio Wasm(NoIC)/JS |
|---|---|---|---|---|---|
| fib.js | 444.7162 | 42.8224 | 50.0957 | 0.10 | 0.11 |
| field_access.js | 4.2910 | 20.9166 | 31.5153 | 4.87 | 7.34 |
