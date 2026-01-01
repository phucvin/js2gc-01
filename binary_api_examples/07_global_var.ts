import binaryen from "binaryen";

const module = new binaryen.Module();

// Global: counter (mutable i32, init 0)
module.addGlobal(
  "counter",
  binaryen.i32,
  true,
  module.i32.const(0)
);

// Function: increment() -> i32
module.addFunction(
  "increment",
  binaryen.createType([]),
  binaryen.i32,
  [],
  module.block(null, [
    module.global.set(
      "counter",
      module.i32.add(
        module.global.get("counter", binaryen.i32),
        module.i32.const(1)
      )
    ),
    module.global.get("counter", binaryen.i32)
  ])
);

module.addFunctionExport("increment", "increment");

console.log("--- 07_global_var.ts ---");
console.log(module.emitText());
module.dispose();
