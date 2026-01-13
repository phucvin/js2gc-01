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

```bash
npm test
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
npm run benchmark
```

This runs a few iterations of each benchmark (min of 5) for both Wasm (if available) and JS and compares the execution time.

## Benchmark Results

| Benchmark | JS (ms) | Wasm IC (ms) | Wasm No IC (ms) | Ratio Wasm(IC)/JS | Ratio Wasm(NoIC)/JS |
|---|---|---|---|---|---|
| fib.js | 30.6023 | 3567.7165 | 3269.2640 | 116.58 | 106.83 |
| field_access.js | 31.0499 | 48.6630 | 32.3404 | 1.57 | 1.04 |