import binaryen from 'binaryen';

const module = new binaryen.Module();
module.setFeatures(binaryen.Features.BulkMemory);

module.setMemory(1, 1, 'memory');

// Function: copy_mem(dest: i32, src: i32, len: i32)
module.addFunction(
  'copy_mem',
  binaryen.createType([binaryen.i32, binaryen.i32, binaryen.i32]),
  binaryen.none,
  [],
  module.memory.copy(
    module.local.get(0, binaryen.i32),
    module.local.get(1, binaryen.i32),
    module.local.get(2, binaryen.i32),
    'memory',
    'memory',
  ),
);

module.addFunctionExport('copy_mem', 'copy_mem');

process.stdout.write(module.emitText());
module.dispose();
