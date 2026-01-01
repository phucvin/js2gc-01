import binaryen from "binaryen";

const module = new binaryen.Module();

// Function: is_even(i32) -> i32 (1 if even, 0 if odd)
module.addFunction(
  "is_even",
  binaryen.createType([binaryen.i32]),
  binaryen.i32,
  [],
  module.if(
    module.i32.eq(
      module.i32.rem_s(module.local.get(0, binaryen.i32), module.i32.const(2)),
      module.i32.const(0)
    ),
    module.i32.const(1),
    module.i32.const(0)
  )
);

module.addFunctionExport("is_even", "is_even");

console.log("--- 02_if_else.ts ---");
console.log(module.emitText());
module.dispose();
