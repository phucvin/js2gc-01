import binaryen from "binaryen";

const module = new binaryen.Module();

// Function: test_break(i32) -> i32
// If input > 10, break block with 100, else return input
module.addFunction(
  "test_break",
  binaryen.createType([binaryen.i32]),
  binaryen.i32,
  [],
  module.block("my_block", [
    module.br_if(
      "my_block",
      module.i32.gt_u(module.local.get(0, binaryen.i32), module.i32.const(10)),
      module.i32.const(100) // Value to return if break is taken
    ),
    module.local.get(0, binaryen.i32) // Value if break not taken
  ], binaryen.i32) // Block returns i32
);

module.addFunctionExport("test_break", "test_break");

process.stdout.write(module.emitText());
module.dispose();
