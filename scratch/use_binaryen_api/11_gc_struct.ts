import binaryen from 'binaryen';

// Define a struct type: struct { field 0: i32 (mutable), field 1: i32 (mutable) }
// We use TypeBuilder because struct types are heap types.
const builder = new binaryen.TypeBuilder(1);
const typeIndex = 0; // The index of the type we are building

// Define the struct
// setStructType(index, fields)
// fields is an array of objects: { type, packedType, mutable }
// binaryen.PackedType.NotPacked is 0
const NotPacked = 0;

builder.setStructType(typeIndex, [
  { type: binaryen.i32, packedType: NotPacked, mutable: true },
  { type: binaryen.i32, packedType: NotPacked, mutable: true },
]);

// Build the types
const heapTypes = builder.buildAndDispose();
const structHeapType = heapTypes[typeIndex];

// Create a reference type from the heap type (nullable)
const structType = binaryen.getTypeFromHeapType(structHeapType, true);

const module = new binaryen.Module();
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

// Function: mk_struct() -> (ref null $struct)
module.addFunction(
  'mk_struct',
  binaryen.createType([]),
  structType,
  [],
  module.struct.new([module.i32.const(10), module.i32.const(20)], structHeapType),
);

module.addFunctionExport('mk_struct', 'mk_struct');

if (!module.validate()) {
  throw new Error('Invalid module');
}

process.stdout.write(module.emitText());
module.dispose();
