# JS Interpreter

A simple C++ interpreter for a subset of JavaScript, using an Indexed RPN AST structure.

## Building

```bash
./build.sh
```

This will produce a `js_interpreter` binary.

## Usage

```bash
./js_interpreter <path_to_js_file>
```

## Example

Running `testdata/add.js`:

```javascript
// testdata/add.js
function a() { return 1; }
function b() { return 2; }
function main() { return a() + b(); }

export function test() { console.log(main()); }
```

Command:
```bash
./js_interpreter ../../testdata/add.js
```

Output:
```
3
```
