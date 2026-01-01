import binaryen from "binaryen";

// GC Array example
const wat = `
(module
  (type $arr_t (array (mut i32)))

  (func $mk_array (param $len i32) (result (ref $arr_t))
    (array.new_default $arr_t
      (local.get $len)
    )
  )

  (export "mk_array" (func $mk_array))
)
`;

const module = binaryen.parseText(wat);
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

if (!module.validate()) {
    throw new Error("Invalid module");
}

process.stdout.write(module.emitText());
module.dispose();
