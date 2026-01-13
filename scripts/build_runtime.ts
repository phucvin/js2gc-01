import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { getRuntime } from '../src/compiler/runtime.ts';
import { registerStringLiteral, resetStringMap, stringDataSegments } from '../src/compiler/context.ts';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const runtimeDir = path.join(projectRoot, 'runtime');

if (!fs.existsSync(runtimeDir)) {
    fs.mkdirSync(runtimeDir);
}

function buildRuntime() {
    console.log("Building runtime...");

    // Reset context to ensure fresh state
    resetStringMap();
    const nullData = registerStringLiteral('null');
    const objData = registerStringLiteral('[object Object]');
    const dataSegmentsDecl = stringDataSegments.join('\n');

    const runtimeWat = `(module
    (type $Shape (struct
      (field $parent (ref null $Shape))
      (field $key i32)
      (field $offset i32)
      (field $proto anyref)
    ))

    (type $Storage (array (mut anyref)))

    (type $Object (struct
      (field $shape (mut (ref $Shape)))
      (field $storage (mut (ref $Storage)))
    ))

    (type $CallSite (struct
      (field $expected_shape (mut (ref null $Shape)))
      (field $offset (mut i32))
      (field $holder (mut anyref))
    ))

    (type $Closure (struct
      (field $func (ref func))
      (field $env anyref)
    ))

    (type $BinaryOpFunc (func (param anyref) (param anyref) (result anyref)))

    (type $BinaryOpCallSite (struct
      (field $type_lhs (mut i32))
      (field $type_rhs (mut i32))
      (field $target (mut (ref null $BinaryOpFunc)))
    ))

    (type $BoxedF64 (struct (field f64)))
    (type $BoxedI32 (struct (field i32)))
    (type $String (array (mut i8)))

    (import "env" "print_i32" (func $print_i32 (param i32)))
    (import "env" "print_f64" (func $print_f64 (param f64)))
    (import "env" "print_char" (func $print_char (param i32)))

    ${dataSegmentsDecl}

    ${getRuntime(true, nullData, objData)}

    (export "new_object" (func $new_object))
    (export "put_field" (func $put_field))
    (export "get_field_cached" (func $get_field_cached))
    (export "get_field_slow" (func $get_field_slow))
    (export "add_cached" (func $add_cached))
    (export "sub_cached" (func $sub_cached))
    (export "console_log" (func $console_log))
    (export "new_root_shape" (func $new_root_shape))
    )`;

    const module = binaryen.parseText(runtimeWat);
    module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory);

    if (!module.validate()) {
        console.error("Runtime validation failed");
        process.exit(1);
    }

    const binary = module.emitBinary();
    const wasmPath = path.join(runtimeDir, 'runtime.wasm');
    fs.writeFileSync(wasmPath, binary);
    console.log(`Runtime written to ${wasmPath}`);
    module.dispose();
}

buildRuntime();
