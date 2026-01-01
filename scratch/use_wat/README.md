# WAT Examples

This directory contains WebAssembly Text Format (WAT) examples demonstrating various features, including GC (structs, arrays).

## Structure

*   `*.wat`: The source WAT files.
*   `run.ts`: A script that:
    1.  Scans for all `.wat` files.
    2.  Parses and validates them using Binaryen.
    3.  Optimizes the modules.
    4.  Writes the optimized WAT to `*.wat.optimized`.
    5.  Compiles and runs the Wasm module (calling the `main` export).
    6.  Writes the result (integer) to `*.wat.out`.

## How to Run

Ensure you have dependencies installed (e.g., `npm install`).

Run the script:

```bash
npx ts-node-esm scratch/use_wat/run.ts
```
