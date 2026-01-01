import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Since the Binaryen JS API for constructing GC types programmatically seems unstable (crashes),
// we will demonstrate parsing WAT text which uses GC features.
// This is also a valid use of Binaryen (as a compiler/toolchain part).

const watText = `
(module
  (type $Point (struct (field (mut i32) (mut f64))))

  (func $make_and_get_x (param $val i32) (result i32)
    (struct.get $Point 0
      (struct.new $Point
        (local.get $val)
        (f64.const 20.5)
      )
    )
  )

  (export "make_and_get_x" (func $make_and_get_x))
)
`;

console.log("Parsing WAT text...");
const module = binaryen.parseText(watText);

// Enable GC features - explicitly needed?
// parseText usually sets features based on content or defaults?
// Let's ensure GC is on.
// Also need Reference Types for GC.
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

// Emit WAT (canonicalized)
const wat = module.emitText();
const watPath = path.join(__dirname, 'gc_struct.wat');
fs.writeFileSync(watPath, wat);
console.log(`WAT written to ${watPath}`);

// Compile to Binary
const binary = module.emitBinary();

// Instantiate and Run
async function run() {
    try {
        const compiled = await WebAssembly.compile(binary as any);
        const instance = await WebAssembly.instantiate(compiled, {});

        const make_and_get_x = (instance.exports as any).make_and_get_x as (val: number) => number;

        const inputVal = 42;
        const result = make_and_get_x(inputVal);

        const outPath = path.join(__dirname, 'gc_struct.out');
        const output = `Result: ${result}\n`;
        fs.writeFileSync(outPath, output);
        console.log(`Output written to ${outPath}`);
    } catch (e) {
        console.error("Execution failed:", e);
        process.exit(1);
    }
}

run();
