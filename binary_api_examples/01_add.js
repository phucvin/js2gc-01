import binaryen from "binaryen";
const module = new binaryen.Module();
// Create a function type for (i32, i32) => i32
const ii2i = binaryen.createType([binaryen.i32, binaryen.i32]);
// Define the add function
module.addFunction("add", ii2i, binaryen.i32, [], // No local variables
module.i32.add(module.local.get(0, binaryen.i32), module.local.get(1, binaryen.i32)));
module.addFunctionExport("add", "add");
console.log("--- 01_add.ts ---");
console.log(module.emitText());
module.dispose();
