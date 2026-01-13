import binaryen from 'binaryen';

const module = new binaryen.Module();
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

// Function: test_i31(val: i32) -> i32
module.addFunction(
  'test_i31',
  binaryen.createType([binaryen.i32]),
  binaryen.i32,
  [],
  module.i31.get_s(module.ref.i31(module.local.get(0, binaryen.i32))),
);

module.addFunctionExport('test_i31', 'test_i31');

if (!module.validate()) {
  throw new Error('Invalid module');
}

process.stdout.write(module.emitText());
module.dispose();
