import binaryen from "binaryen";
const module = new binaryen.Module();
// Function: factorial(i32) -> i32
// Iterative factorial
// Locals: 0: n (param), 1: result, 2: i
module.addFunction("factorial", binaryen.createType([binaryen.i32]), binaryen.i32, [binaryen.i32, binaryen.i32], // locals: var 1 (result), var 2 (i)
module.block(null, [
    module.local.set(1, module.i32.const(1)), // result = 1
    module.local.set(2, module.i32.const(1)), // i = 1
    // Block "loop_out" wraps the loop so we can break out of it
    module.block("loop_out", [
        module.loop("loop", module.block(null, [
            // if i > n, break to loop_out
            module.br_if("loop_out", module.i32.gt_u(module.local.get(2, binaryen.i32), module.local.get(0, binaryen.i32))),
            // result = result * i
            module.local.set(1, module.i32.mul(module.local.get(1, binaryen.i32), module.local.get(2, binaryen.i32))),
            // i = i + 1
            module.local.set(2, module.i32.add(module.local.get(2, binaryen.i32), module.i32.const(1))),
            // continue loop
            module.br("loop")
        ]))
    ]),
    module.local.get(1, binaryen.i32)
]));
module.addFunctionExport("factorial", "factorial");
console.log("--- 03_loops.ts ---");
console.log(module.emitText());
module.dispose();
