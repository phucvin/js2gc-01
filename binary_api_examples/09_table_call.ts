import binaryen from "binaryen";

const module = new binaryen.Module();

// Define two functions to call indirectly
const f1 = module.addFunction("f1", binaryen.createType([]), binaryen.i32, [], module.i32.const(10));
const f2 = module.addFunction("f2", binaryen.createType([]), binaryen.i32, [], module.i32.const(20));

// Add table
// Table elements must be funcref (or anyfunc)
// binaryen.funcref might not be directly exposed as a value type constant in older definitions or might be just 'funcref'
// In binaryen.js, types are integers. binaryen.anyref / funcref etc.
// Let's use binaryen.funcref if available, or check docs/types.
// Usually table takes 'funcref'.
// binaryen.js often uses simple integers for basic types.
// For table type, it's typically binaryen.funcref in recent versions.

// Checking if binaryen.funcref exists or is the right one.
// If strictly needed, I'll use simple integer if funcref is not defined, but it should be.
// But wait, the reviewer said "binaryen.funcref" is the correct one.
// I will use that.

module.addTable("table", 2, 2, binaryen.funcref || binaryen.anyfunc);
module.addActiveElementSegment("table", "table", ["f1", "f2"], module.i32.const(0));

// Function: call_indirect(index: i32) -> i32
module.addFunction(
  "call_indirect",
  binaryen.createType([binaryen.i32]),
  binaryen.i32,
  [],
  module.call_indirect(
    "table",
    module.local.get(0, binaryen.i32),
    [], // params
    binaryen.i32 // result
  )
);

module.addFunctionExport("call_indirect", "call_indirect");

console.log("--- 09_table_call.ts ---");
console.log(module.emitText());
module.dispose();
