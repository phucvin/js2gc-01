# Binaryen API Examples

This directory contains TypeScript examples demonstrating how to use the `binaryen.js` API to programmatically construct WebAssembly modules.

## Prerequisites

- Node.js
- Dependencies installed (`npm install`)
- `ts-node` available (via `npx` or global install)

## Directory Structure

- `*.ts`: Individual example files showing different Wasm features.
- `run.ts`: Automation script to execute all examples.
- `*.out`: Generated output files (WebAssembly Text format) from the examples.

## How to Run

To run all examples and generate the `.out` files, execute the following command from the repository root:

```bash
npx ts-node binary_api_examples/run.ts
```

This script will:
1. Find all `.ts` example files in this directory.
2. Execute each one using `ts-node`.
3. Save the standard output (which typically contains the emitted `.wat` text) to a corresponding `.out` file (e.g., `01_add.ts` -> `01_add.out`).

## Examples List

1. `01_add.ts`: Basic integer addition.
2. `02_if_else.ts`: Control flow with `if` and `else`.
3. `03_loops.ts`: Loops and blocks.
4. `04_memory.ts`: Linear memory operations (`load`, `store`).
5. `05_function_call.ts`: Calling other functions within the module.
6. `06_imported_func.ts`: Importing functions from the host environment.
7. `07_global_var.ts`: Using global variables.
8. `08_block_break.ts`: Blocks and branching out (`br`, `br_if`).
9. `09_table_call.ts`: Indirect function calls using tables (`call_indirect`).
10. `10_bulk_memory.ts`: Bulk memory operations (`memory.copy`).
