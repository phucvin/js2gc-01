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
| fib.js | 52.0147 | 3539.2465 | 3674.7785 | 68.04 | 70.65 |
| field_access.js | 47.5827 | 33.5830 | 27.3252 | 0.71 | 0.57 |
