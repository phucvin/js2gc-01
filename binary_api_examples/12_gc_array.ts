import binaryen from "binaryen";

// Define an array type: array (mut i32)
const builder = new binaryen.TypeBuilder(1);
const typeIndex = 0;
const NotPacked = 0;

// setArrayType(index, elementType, elementPackedType, elementMutable)
builder.setArrayType(typeIndex, binaryen.i32, NotPacked, true);

const heapTypes = builder.buildAndDispose();
const arrayHeapType = heapTypes[typeIndex];
const arrayType = binaryen.getTypeFromHeapType(arrayHeapType, true);

const module = new binaryen.Module();
module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

// Function: mk_array(len: i32) -> (ref null $array)
module.addFunction(
  "mk_array",
  binaryen.createType([binaryen.i32]),
  arrayType,
  [],
  module.array.new_default(
    arrayHeapType,
    module.local.get(0, binaryen.i32)
  )
);

module.addFunctionExport("mk_array", "mk_array");

if (!module.validate()) {
    throw new Error("Invalid module");
}

process.stdout.write(module.emitText());
module.dispose();
