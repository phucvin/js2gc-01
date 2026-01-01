# Test Data

This directory contains test cases for the compiler.

## Structure

*   `*.js`: JavaScript source files to be compiled.
*   `_run.js`: Automation script to compile and run the tests.
*   `*.wat`: Generated WebAssembly Text format files.
*   `*.out`: Expected output from running the compiled Wasm.

## How to Run

To run all tests and update outputs:

```bash
node --experimental-wasm-stringref testdata/_run.js
```
