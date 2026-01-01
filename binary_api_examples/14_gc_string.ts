import binaryen from "binaryen";

// GC Stringref example
const wat = `
(module
  (func $str_len (param $s stringref) (result i32)
    (string.measure_utf8 (local.get $s))
  )

  (export "str_len" (func $str_len))
)
`;

const module = binaryen.parseText(wat);
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.Strings);

if (!module.validate()) {
    throw new Error("Invalid module");
}

process.stdout.write(module.emitText());
module.dispose();
