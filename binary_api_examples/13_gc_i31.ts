import binaryen from "binaryen";

// GC i31 example
const wat = `
(module
  (func $test_i31 (param $val i32) (result i32)
    (i31.get_s
      (ref.i31 (local.get $val))
    )
  )

  (export "test_i31" (func $test_i31))
)
`;

const module = binaryen.parseText(wat);
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

if (!module.validate()) {
    throw new Error("Invalid module");
}

process.stdout.write(module.emitText());
module.dispose();
