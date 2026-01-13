import binaryen from 'binaryen';
import {
  RUNTIME_TYPES,
  RUNTIME_CLOSURE_SIGS,
  RUNTIME_IMPORTS,
  RUNTIME_GLOBALS_DECL,
  RUNTIME_ELEMS,
  getRuntimeInit,
  getRuntimeHelpers,
} from '../src/compiler/runtime.ts';
import * as fs from 'fs';
import * as path from 'path';

function buildRuntime() {
  // For the standalone runtime, we don't have user-defined data segments yet (null/objData).
  // But runtime_init sets globals using them.
  // We can treat them as imports or define them here.
  // Since they are "pooled constants", they should probably be part of the runtime.
  // Let's create dummy segments for now, or just empty strings.
  // Actually, runtime_init depends on specific data segments being present.

  // To make it truly shared, we might need the user module to import the globals?
  // Or the runtime exports the globals?

  // Approach:
  // 1. runtime.wasm exports functions like $new_object, $console_log.
  // 2. runtime.wasm manages its own heap/globals.
  // 3. User module imports these functions.

  // However, GC types ($Object, $Shape) must be shared.
  // Wasm GC currently doesn't support "importing types" easily across modules without matching definitions.
  // So both modules must define the same types (isorecursive).

  // This step is complex. I'll create a script to compile the runtime helpers to a module
  // to prove we can generate valid WAT/Wasm for them in isolation.

  const nullData = '\\00\\00\\00\\00'; // "null" length 4
  const objData = '\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00\\00'; // "[object Object]" length 15 (dummy)

  const wat = `(module
    ${RUNTIME_TYPES}
    ${RUNTIME_CLOSURE_SIGS}
    ${RUNTIME_IMPORTS}
    ${RUNTIME_ELEMS}
    ${RUNTIME_GLOBALS_DECL}

    (data $d_null "${nullData}")
    (data $d_obj "${objData}")

    ${getRuntimeInit('$d_null', '$d_obj')}
    ${getRuntimeHelpers(true)}

    (export "new_object" (func $new_object))
    (export "console_log" (func $console_log))
    ;; Add other exports as needed
  )`;

  const module = binaryen.parseText(wat);
  module.setFeatures(
    binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory,
  );

  if (!module.validate()) {
      console.error("Runtime validation failed");
      module.dispose();
      process.exit(1);
  }

  const binary = module.emitBinary();
  module.dispose();

  fs.writeFileSync('runtime/runtime.wasm', binary);
  console.log("Runtime built to runtime/runtime.wasm");
}

buildRuntime();
