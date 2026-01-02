# WAT Interpreter

A simple C++ interpreter for a subset of WebAssembly Text (WAT), using an Indexed RPN AST structure.
It supports basic instructions and some Wasm GC features (structs, i31ref).

## Building

```bash
./build.sh
```

This will produce a `wat_interpreter` binary.

## Usage

```bash
./wat_interpreter <path_to_wat_file>
```

## Example

Running `testdata/int_i31.wat`:

Command:
```bash
./wat_interpreter ../../testdata/int_i31.wat
```

Output:
```
100
```
