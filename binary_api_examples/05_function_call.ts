import binaryen from "binaryen";

const module = new binaryen.Module();

// Helper function: square(i32) -> i32
module.addFunction(
  "square",
  binaryen.createType([binaryen.i32]),
  binaryen.i32,
  [],
  module.i32.mul(module.local.get(0, binaryen.i32), module.local.get(0, binaryen.i32))
);

// Main function: sum_of_squares(a: i32, b: i32) -> i32
module.addFunction(
  "sum_of_squares",
  binaryen.createType([binaryen.i32, binaryen.i32]),
  binaryen.i32,
  [],
  module.i32.add(
    module.call("square", [module.local.get(0, binaryen.i32)], binaryen.i32),
    module.call("square", [module.local.get(1, binaryen.i32)], binaryen.i32)
  )
);

module.addFunctionExport("sum_of_squares", "sum_of_squares");

process.stdout.write(module.emitText());
module.dispose();
