import binaryen from 'binaryen';

const wat = `(module
  (type $String (array (mut i8)))
  (data $hello "hello")
  (func $main (result (ref $String))
    (array.new_data $String $hello (i32.const 0) (i32.const 5))
  )
)`;

try {
  const module = binaryen.parseText(wat);
  module.setFeatures(
    binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory,
  );
  if (module.validate()) {
    console.log('Validation successful');
    console.log(module.emitText());
  } else {
    console.log('Validation failed');
  }
  module.dispose();
} catch (e) {
  console.error(e);
}
