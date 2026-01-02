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

Running `testdata/add.wat`:

Command:
```bash
./wat_interpreter ../../testdata/add.wat
```

Output:
```
3
```
