# Binaryen API Examples (TypeScript)

This directory contains examples of using `binaryen.js` with TypeScript to generate WebAssembly GC modules.

## Examples

*   `gc_struct.ts`: Demonstrates creating a Wasm Struct type, allocating it, and accessing fields.
*   `gc_array.ts`: Demonstrates creating a Wasm Array type, allocating it, and accessing elements.

## Running the Examples

You can run all examples automatically using the provided runner script:

```bash
npx ts-node-esm binaryen_api_examples/run_all.ts
```

Or run individual examples:

```bash
npx ts-node-esm binaryen_api_examples/gc_struct.ts
npx ts-node-esm binaryen_api_examples/gc_array.ts
```

## Outputs

Each example script produces two output files:
*   `*.wat`: The WebAssembly Text format representation of the generated module.
*   `*.out`: The output of running the generated Wasm module.
