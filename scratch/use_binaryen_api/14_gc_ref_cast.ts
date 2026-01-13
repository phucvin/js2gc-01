import binaryen from 'binaryen';

const module = new binaryen.Module();
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

// Example: Cast anyref to i31ref and back (or just test it)
// Function: test_cast(any: anyref) -> i31ref
module.addFunction(
  'test_cast',
  binaryen.createType([binaryen.anyref]),
  binaryen.i31ref,
  [],
  module.ref.cast(module.local.get(0, binaryen.anyref), binaryen.i31ref),
);

module.addFunctionExport('test_cast', 'test_cast');

if (!module.validate()) {
  throw new Error('Invalid module');
}

process.stdout.write(module.emitText());
module.dispose();
