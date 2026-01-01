import binaryen from "binaryen";

const module = new binaryen.Module();

// Set up memory: 1 initial page, 1 max page
module.setMemory(1, 1, "memory");

// Function: store_and_load(offset: i32, value: i32) -> i32
module.addFunction(
  "store_and_load",
  binaryen.createType([binaryen.i32, binaryen.i32]),
  binaryen.i32,
  [],
  module.block(null, [
    module.i32.store(0, 0, // bytes=4, align=0 (default)
      module.local.get(0, binaryen.i32), // pointer
      module.local.get(1, binaryen.i32), // value
      "memory"
    ),
    module.i32.load(0, 0, // bytes=4, align=0
      module.local.get(0, binaryen.i32),
      "memory"
    )
  ])
);

module.addFunctionExport("store_and_load", "store_and_load");

console.log("--- 04_memory.ts ---");
console.log(module.emitText());
module.dispose();
