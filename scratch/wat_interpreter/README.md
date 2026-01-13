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

## Testing

To run the test suite against `testdata/*.wat`:

```bash
python3 ../../scripts/run_testdata_with_wat_interpreter.py
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
