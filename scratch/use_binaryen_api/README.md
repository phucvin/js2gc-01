# Binaryen API Examples

This directory contains TypeScript examples demonstrating how to use the `binaryen.js` API to programmatically construct WebAssembly modules.

## Prerequisites

- Node.js
- Dependencies installed (`npm install`)
- `ts-node` available (via `npx` or global install)

## Directory Structure

- `*.ts`: Individual example files showing different Wasm features.
- `_run.js`: Automation script to execute all examples.
- `*.out`: Generated output files (WebAssembly Text format) from the examples.

## How to Run

To run all examples and generate the `.out` files, execute the following command from the repository root:

```bash
node scratch/use_binaryen_api/_run.js
```

This script will:
1. Find all `.ts` example files in this directory.
2. Execute each one using `npx ts-node`.
3. Save the standard output (which typically contains the emitted `.wat` text) to a corresponding `.out` file (e.g., `01_add.ts` -> `01_add.out`).
