import binaryen from "binaryen";

// GC Struct example using parseText
const wat = `
(module
  (type $struct_t (struct (field (mut i32)) (field (mut i32))))

  (func $mk_struct (result (ref $struct_t))
    (struct.new $struct_t
      (i32.const 10)
      (i32.const 20)
    )
  )

  (export "mk_struct" (func $mk_struct))
)
`;

// Note: GC features are enabled by default in recent binaryen or via parseText if syntax is present,
// but it is good practice to enable them explicitly if we were constructing it.
// When parsing, binaryen usually detects features or we can set them.
const module = binaryen.parseText(wat);
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

if (!module.validate()) {
    throw new Error("Invalid module");
}

process.stdout.write(module.emitText());
module.dispose();
