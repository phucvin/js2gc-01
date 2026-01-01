import binaryen from "binaryen";
const module = new binaryen.Module();
// Import: console.log(i32) -> void
module.addFunctionImport("log", "env", "log", binaryen.createType([binaryen.i32]), binaryen.none);
// Function: log_value(i32) -> void
module.addFunction("log_value", binaryen.createType([binaryen.i32]), binaryen.none, [], module.call("log", [module.local.get(0, binaryen.i32)], binaryen.none));
module.addFunctionExport("log_value", "log_value");
console.log("--- 06_imported_func.ts ---");
console.log(module.emitText());
module.dispose();
