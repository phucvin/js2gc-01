import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Demonstrating Array GC features using Binaryen.
// Using parseText for stability.

const watText = `
(module
  ;; Define an array type: array of i32
  (type $IntArray (array (mut i32)))

  ;; Function to create an array of size 3, fill it, and return the element at index 1
  (func $test_array (result i32)
    (local $arr (ref $IntArray))

    ;; Create new array of size 3 initialized with 0
    (local.set $arr
      (array.new_default $IntArray (i32.const 3))
    )

    ;; Set index 0 to 10
    (array.set $IntArray
      (local.get $arr)
      (i32.const 0)
      (i32.const 10)
    )

    ;; Set index 1 to 20
    (array.set $IntArray
      (local.get $arr)
      (i32.const 1)
      (i32.const 20)
    )

    ;; Get index 1
    (array.get $IntArray
      (local.get $arr)
      (i32.const 1)
    )
  )

  (export "test_array" (func $test_array))
)
`;

console.log("Parsing WAT text for Array example...");
const module = binaryen.parseText(watText);

// Enable GC and ReferenceTypes
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

// Validate
console.log("Validating module...");
if (!module.validate()) {
    console.error("Module validation failed");
    process.exit(1);
}

// Optimize
console.log("Optimizing module...");
module.optimize();

// Emit WAT
const wat = module.emitText();
const watPath = path.join(__dirname, 'gc_array.wat');
fs.writeFileSync(watPath, wat);
console.log(`WAT written to ${watPath}`);

// Compile to Binary
const binary = module.emitBinary();

// Instantiate and Run
async function run() {
    try {
        const compiled = await WebAssembly.compile(binary as any);
        const instance = await WebAssembly.instantiate(compiled, {});

        const test_array = (instance.exports as any).test_array as () => number;

        const result = test_array();

        const outPath = path.join(__dirname, 'gc_array.out');
        const output = `Result: ${result}\n`;
        fs.writeFileSync(outPath, output);
        console.log(`Output written to ${outPath}`);
    } catch (e) {
        console.error("Execution failed:", e);
        process.exit(1);
    }
}

run();
