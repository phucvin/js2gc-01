import ts from 'typescript';
import binaryen from 'binaryen';
import { compileFunction } from './function.ts';
import { resetPropertyMap, resetGlobalCallSites, globalCallSites, generatedFunctions, resetGeneratedFunctions, binaryOpCallSites, type CompilerOptions, resetStringMap, stringDataSegments, registerStringLiteral, resetShapeCache, shapeGlobals } from './context.ts';
import { resetClosureCounter } from './expression.ts';

// Export for other files to use if needed
export type { CompilerOptions };

export function compile(source: string, options?: CompilerOptions): string {
  // Default options
  const compilerOptions: CompilerOptions = {
      enableInlineCache: true,
      enableStringRef: false,
      ...options
  };

  const enableInlineCache = compilerOptions.enableInlineCache !== false;

  resetPropertyMap();
  resetGlobalCallSites();
  resetGeneratedFunctions();
  resetClosureCounter();
  resetStringMap();
  resetShapeCache();

  const nullData = registerStringLiteral("null");
  const objData = registerStringLiteral("[object Object]");

  const sourceFile = ts.createSourceFile(
    'temp.js',
    source,
    ts.ScriptTarget.Latest,
    true
  );

  const functions: ts.FunctionDeclaration[] = [];

  ts.forEachChild(sourceFile, node => {
    if (ts.isFunctionDeclaration(node) && node.name) {
      functions.push(node);
    }
  });

  const mainFunc = functions.find(f => f.name?.text === 'main');

  if (!mainFunc) {
    throw new Error('No main function found');
  }

  let wasmFuncs = '';

  for (const func of functions) {
    wasmFuncs += compileFunction(func, compilerOptions);
  }

  // Append generated closure functions
  if (generatedFunctions.length > 0) {
      wasmFuncs += '\n' + generatedFunctions.join('\n');
  }

  // Generate globals
  let globalsDecl = '';

  if (globalCallSites.length > 0) {
      for (const siteName of globalCallSites) {
          globalsDecl += `(global ${siteName} (mut (ref $CallSite)) (struct.new $CallSite (ref.null $Shape) (i32.const -1)))\n`;
      }
  }

  if (binaryOpCallSites.length > 0) {
      for (const siteName of binaryOpCallSites) {
          globalsDecl += `(global ${siteName} (mut (ref $BinaryOpCallSite)) (struct.new $BinaryOpCallSite (i32.const 0) (i32.const 0) (ref.null $BinaryOpFunc)))\n`;
      }
  }

  // Append shape globals
  if (shapeGlobals.length > 0) {
      globalsDecl += '\n' + shapeGlobals.join('\n');
  }

  // Generate data segments
  const dataSegmentsDecl = stringDataSegments.join('\n');

  // Define some closure types for call_ref
  const closureSigs = `
  (type $ClosureSig0 (func (param anyref) (param anyref) (result anyref)))
  (type $ClosureSig1 (func (param anyref) (param anyref) (param anyref) (result anyref)))
  (type $ClosureSig2 (func (param anyref) (param anyref) (param anyref) (param anyref) (result anyref)))
  (type $ClosureSig3 (func (param anyref) (param anyref) (param anyref) (param anyref) (param anyref) (result anyref)))
  (type $ClosureSig4 (func (param anyref) (param anyref) (param anyref) (param anyref) (param anyref) (param anyref) (result anyref)))
  (type $ClosureSig5 (func (param anyref) (param anyref) (param anyref) (param anyref) (param anyref) (param anyref) (param anyref) (result anyref)))
  `;

  const wat = `(module
  (rec
    (type $Shape (struct
      (field $parent (ref null $Shape))
      (field $key i32)
      (field $offset i32)
    ))

    (type $Storage (array (mut anyref)))

    (type $Object (struct
      (field $shape (mut (ref $Shape)))
      (field $storage (mut (ref $Storage)))
    ))

    ${enableInlineCache ? `(type $CallSite (struct
      (field $expected_shape (mut (ref null $Shape)))
      (field $offset (mut i32))
    ))` : ''}

    (type $Closure (struct
      (field $func (ref func))
      (field $env anyref)
    ))

    (type $BinaryOpFunc (func (param anyref) (param anyref) (result anyref)))

    ${enableInlineCache ? `(type $BinaryOpCallSite (struct
      (field $type_lhs (mut i32))
      (field $type_rhs (mut i32))
      (field $target (mut (ref null $BinaryOpFunc)))
    ))` : ''}
  )

  ${closureSigs}

  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $String (array (mut i8)))

  (import "env" "print_i32" (func $print_i32 (param i32)))
  (import "env" "print_f64" (func $print_f64 (param f64)))
  (import "env" "print_char" (func $print_char (param i32)))

  (elem declare func $add_i32_i32 $add_f64_f64 $add_i32_f64 $add_f64_i32 $add_unsupported)
  (elem declare func $sub_i32_i32 $sub_f64_f64 $sub_i32_f64 $sub_f64_i32 $sub_unsupported)

  ${globalsDecl}
  ${dataSegmentsDecl}

  ;; String Pooling for Runtime Constants
  (global $g_str_null (mut (ref null $String)) (ref.null $String))
  (global $g_str_obj (mut (ref null $String)) (ref.null $String))

  (func $runtime_init
    (global.set $g_str_null (array.new_data $String ${nullData} (i32.const 0) (i32.const 4)))
    (global.set $g_str_obj (array.new_data $String ${objData} (i32.const 0) (i32.const 15)))
  )
  (start $runtime_init)

  (func $new_root_shape (result (ref $Shape))
    (struct.new $Shape
      (ref.null $Shape)
      (i32.const -1)
      (i32.const -1)
    )
  )

  (func $extend_shape (param $parent (ref $Shape)) (param $key i32) (param $offset i32) (result (ref $Shape))
    (struct.new $Shape
      (local.get $parent)
      (local.get $key)
      (local.get $offset)
    )
  )

  (func $new_object (param $shape (ref $Shape)) (param $size i32) (result (ref $Object))
    (struct.new $Object
      (local.get $shape)
      (array.new_default $Storage (local.get $size))
    )
  )

  (func $set_storage (param $obj (ref $Object)) (param $idx i32) (param $val anyref)
    (array.set $Storage (struct.get $Object $storage (local.get $obj))
      (local.get $idx)
      (local.get $val)
    )
  )

  (func $put_field (param $obj (ref $Object)) (param $key i32) (param $val anyref)
    (local $shape (ref $Shape))
    (local $offset i32)
    (local $old_storage (ref $Storage))
    (local $new_storage (ref $Storage))
    (local $old_len i32)

    (local.set $shape (struct.get $Object $shape (local.get $obj)))
    (local.set $offset (call $lookup_in_shape (local.get $shape) (local.get $key)))

    (if (i32.ne (local.get $offset) (i32.const -1))
      (then
        ;; Field exists, just update storage
        (array.set $Storage (struct.get $Object $storage (local.get $obj)) (local.get $offset) (local.get $val))
      )
      (else
        ;; Field does not exist, extend shape
        ;; 1. Calculate new offset (current storage length)
        (local.set $old_storage (struct.get $Object $storage (local.get $obj)))
        (local.set $old_len (array.len (local.get $old_storage)))
        (local.set $offset (local.get $old_len))

        ;; 2. Extend shape
        (local.set $shape (call $extend_shape (local.get $shape) (local.get $key) (local.get $offset)))
        (struct.set $Object $shape (local.get $obj) (local.get $shape))

        ;; 3. Allocate new storage (len + 1)
        (local.set $new_storage (array.new_default $Storage (i32.add (local.get $old_len) (i32.const 1))))

        ;; 4. Copy old storage to new
        (array.copy $Storage $Storage (local.get $new_storage) (i32.const 0) (local.get $old_storage) (i32.const 0) (local.get $old_len))

        ;; 5. Set new value
        (array.set $Storage (local.get $new_storage) (local.get $offset) (local.get $val))

        ;; 6. Update object storage
        (struct.set $Object $storage (local.get $obj) (local.get $new_storage))
      )
    )
  )

  (func $lookup_in_shape (param $shape (ref $Shape)) (param $key i32) (result i32)
    (local $curr (ref null $Shape))
    (local.set $curr (local.get $shape))

    (loop $search
      (if (ref.is_null (local.get $curr))
        (then (return (i32.const -1)))
      )

      (if (i32.eq (struct.get $Shape $key (local.get $curr)) (local.get $key))
        (then (return (struct.get $Shape $offset (local.get $curr))))
      )

      (local.set $curr (struct.get $Shape $parent (local.get $curr)))
      (br $search)
    )
    (i32.const -1)
  )

  (func $get_field_resolve (param $obj (ref $Object)) (param $shape (ref $Shape)) ${enableInlineCache ? '(param $cache (ref $CallSite))' : ''} (param $key i32) (result anyref)
    (local $offset i32)

    (local.set $offset (call $lookup_in_shape (local.get $shape) (local.get $key)))

    (if (i32.ge_s (local.get $offset) (i32.const 0))
      (then
        ${enableInlineCache ? `
        (struct.set $CallSite $expected_shape (local.get $cache) (local.get $shape))
        (struct.set $CallSite $offset (local.get $cache) (local.get $offset))
        ` : ''}
        (return (array.get $Storage (struct.get $Object $storage (local.get $obj)) (local.get $offset)))
      )
    )
    (ref.null any)
  )

  (func $get_field_slow (param $obj (ref $Object)) ${enableInlineCache ? '(param $cache (ref $CallSite))' : ''} (param $key i32) (result anyref)
    (call $get_field_resolve
        (local.get $obj)
        (struct.get $Object $shape (local.get $obj))
        ${enableInlineCache ? '(local.get $cache)' : ''}
        (local.get $key)
    )
  )

  ${enableInlineCache ? `(func $get_field_cached (param $obj (ref $Object)) (param $cache (ref $CallSite)) (param $key i32) (result anyref)
    (local $shape (ref $Shape))
    (local.set $shape (struct.get $Object $shape (local.get $obj)))

    (if (ref.eq
          (local.get $shape)
          (struct.get $CallSite $expected_shape (local.get $cache))
        )
      (then
        (return (array.get $Storage
          (struct.get $Object $storage (local.get $obj))
          (struct.get $CallSite $offset (local.get $cache))
        ))
      )
    )
    (call $get_field_resolve (local.get $obj) (local.get $shape) (local.get $cache) (local.get $key))
  )` : ''}

  (func $print_string_helper (param $str (ref $String))
    (local $len i32)
    (local $i i32)
    (local.set $len (array.len (local.get $str)))
    (local.set $i (i32.const 0))
    (loop $l
      (if (i32.lt_u (local.get $i) (local.get $len))
        (then
          (call $print_char (array.get_u $String (local.get $str) (local.get $i)))
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $l)
        )
      )
    )
  )

  (func $console_log (param $val anyref)
    (block $null
      (br_on_null $null (local.get $val))

      (block $i31 (result (ref i31))
        (block $boxed_i32 (result (ref $BoxedI32))
          (block $boxed_f64 (result (ref $BoxedF64))
            (block $string (result (ref $String))
               (block $object (result (ref $Object))
                  (local.get $val)
                  (br_on_cast $i31 anyref (ref i31))
                  (br_on_cast $boxed_i32 anyref (ref $BoxedI32))
                  (br_on_cast $boxed_f64 anyref (ref $BoxedF64))
                  (br_on_cast $string anyref (ref $String))
                  (br_on_cast $object anyref (ref $Object))
                  drop
                  return
               )
               drop
               (call $print_string_helper (ref.as_non_null (global.get $g_str_obj)))
               (call $print_char (i32.const 10))
               return
            )
            (call $print_string_helper)
            (call $print_char (i32.const 10))
            return
          )
          (call $print_f64 (struct.get $BoxedF64 0))
          return
        )
        (call $print_i32 (struct.get $BoxedI32 0))
        return
      )
      (call $print_i32 (i31.get_s))
      return
    )
    (call $print_string_helper (ref.as_non_null (global.get $g_str_null)))
    (call $print_char (i32.const 10))
  )

  (func $get_type_id (param $val anyref) (result i32)
      (if (ref.is_null (local.get $val)) (then (return (i32.const 0))))
      (if (ref.test (ref i31) (local.get $val)) (then (return (i32.const 1))))
      (if (ref.test (ref $BoxedF64) (local.get $val)) (then (return (i32.const 2))))
      ;; 0 is unknown/null
      (i32.const 0)
  )

  (func $add_i32_i32 (type $BinaryOpFunc)
    (ref.i31 (i32.add
        (i31.get_s (ref.cast (ref i31) (local.get 0)))
        (i31.get_s (ref.cast (ref i31) (local.get 1)))
    ))
  )

  (func $add_f64_f64 (type $BinaryOpFunc)
    (struct.new $BoxedF64 (f64.add
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 0)))
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 1)))
    ))
  )

  (func $add_i32_f64 (type $BinaryOpFunc)
    (struct.new $BoxedF64 (f64.add
        (f64.convert_i32_s (i31.get_s (ref.cast (ref i31) (local.get 0))))
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 1)))
    ))
  )

  (func $add_f64_i32 (type $BinaryOpFunc)
    (struct.new $BoxedF64 (f64.add
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 0)))
        (f64.convert_i32_s (i31.get_s (ref.cast (ref i31) (local.get 1))))
    ))
  )

  (func $add_unsupported (type $BinaryOpFunc)
    (ref.null any)
  )

  (func $add_slow (param $lhs anyref) (param $rhs anyref) ${enableInlineCache ? '(param $cache (ref $BinaryOpCallSite))' : ''} (result anyref)
      (local $t_lhs i32)
      (local $t_rhs i32)
      (local $target (ref null $BinaryOpFunc))

      (local.set $t_lhs (call $get_type_id (local.get $lhs)))
      (local.set $t_rhs (call $get_type_id (local.get $rhs)))

      ;; Default to add_unsupported
      (local.set $target (ref.func $add_unsupported))

      (if (i32.eq (local.get $t_lhs) (i32.const 1)) ;; i31
          (then
              (if (i32.eq (local.get $t_rhs) (i32.const 1))
                  (then (local.set $target (ref.func $add_i32_i32)))
                  (else (if (i32.eq (local.get $t_rhs) (i32.const 2))
                      (then (local.set $target (ref.func $add_i32_f64)))
                  ))
              )
          )
          (else (if (i32.eq (local.get $t_lhs) (i32.const 2)) ;; f64
              (then
                  (if (i32.eq (local.get $t_rhs) (i32.const 1))
                      (then (local.set $target (ref.func $add_f64_i32)))
                      (else (if (i32.eq (local.get $t_rhs) (i32.const 2))
                          (then (local.set $target (ref.func $add_f64_f64)))
                      ))
                  )
              )
          ))
      )

      ${enableInlineCache ? `
      ;; Update cache
      (struct.set $BinaryOpCallSite $type_lhs (local.get $cache) (local.get $t_lhs))
      (struct.set $BinaryOpCallSite $type_rhs (local.get $cache) (local.get $t_rhs))
      (struct.set $BinaryOpCallSite $target (local.get $cache) (local.get $target))
      ` : ''}

      (call_ref $BinaryOpFunc (local.get $lhs) (local.get $rhs) (local.get $target))
  )

  ${enableInlineCache ? `(func $add_cached (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
      (block $slow
        (br_if $slow (i32.ne (call $get_type_id (local.get $lhs)) (struct.get $BinaryOpCallSite $type_lhs (local.get $cache))))
        (br_if $slow (i32.ne (call $get_type_id (local.get $rhs)) (struct.get $BinaryOpCallSite $type_rhs (local.get $cache))))
        (return (call_ref $BinaryOpFunc (local.get $lhs) (local.get $rhs) (struct.get $BinaryOpCallSite $target (local.get $cache))))
      )
      (call $add_slow (local.get $lhs) (local.get $rhs) (local.get $cache))
  )` : ''}

  (func $sub_i32_i32 (type $BinaryOpFunc)
    (ref.i31 (i32.sub
        (i31.get_s (ref.cast (ref i31) (local.get 0)))
        (i31.get_s (ref.cast (ref i31) (local.get 1)))
    ))
  )

  (func $sub_f64_f64 (type $BinaryOpFunc)
    (struct.new $BoxedF64 (f64.sub
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 0)))
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 1)))
    ))
  )

  (func $sub_i32_f64 (type $BinaryOpFunc)
    (struct.new $BoxedF64 (f64.sub
        (f64.convert_i32_s (i31.get_s (ref.cast (ref i31) (local.get 0))))
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 1)))
    ))
  )

  (func $sub_f64_i32 (type $BinaryOpFunc)
    (struct.new $BoxedF64 (f64.sub
        (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get 0)))
        (f64.convert_i32_s (i31.get_s (ref.cast (ref i31) (local.get 1))))
    ))
  )

  (func $sub_unsupported (type $BinaryOpFunc)
    (ref.null any)
  )

  (func $sub_slow (param $lhs anyref) (param $rhs anyref) ${enableInlineCache ? '(param $cache (ref $BinaryOpCallSite))' : ''} (result anyref)
      (local $t_lhs i32)
      (local $t_rhs i32)
      (local $target (ref null $BinaryOpFunc))

      (local.set $t_lhs (call $get_type_id (local.get $lhs)))
      (local.set $t_rhs (call $get_type_id (local.get $rhs)))

      ;; Default to sub_unsupported
      (local.set $target (ref.func $sub_unsupported))

      (if (i32.eq (local.get $t_lhs) (i32.const 1)) ;; i31
          (then
              (if (i32.eq (local.get $t_rhs) (i32.const 1))
                  (then (local.set $target (ref.func $sub_i32_i32)))
                  (else (if (i32.eq (local.get $t_rhs) (i32.const 2))
                      (then (local.set $target (ref.func $sub_i32_f64)))
                  ))
              )
          )
          (else (if (i32.eq (local.get $t_lhs) (i32.const 2)) ;; f64
              (then
                  (if (i32.eq (local.get $t_rhs) (i32.const 1))
                      (then (local.set $target (ref.func $sub_f64_i32)))
                      (else (if (i32.eq (local.get $t_rhs) (i32.const 2))
                          (then (local.set $target (ref.func $sub_f64_f64)))
                      ))
                  )
              )
          ))
      )

      ${enableInlineCache ? `
      ;; Update cache
      (struct.set $BinaryOpCallSite $type_lhs (local.get $cache) (local.get $t_lhs))
      (struct.set $BinaryOpCallSite $type_rhs (local.get $cache) (local.get $t_rhs))
      (struct.set $BinaryOpCallSite $target (local.get $cache) (local.get $target))
      ` : ''}

      (call_ref $BinaryOpFunc (local.get $lhs) (local.get $rhs) (local.get $target))
  )

  ${enableInlineCache ? `(func $sub_cached (param $lhs anyref) (param $rhs anyref) (param $cache (ref $BinaryOpCallSite)) (result anyref)
      (block $slow
        (br_if $slow (i32.ne (call $get_type_id (local.get $lhs)) (struct.get $BinaryOpCallSite $type_lhs (local.get $cache))))
        (br_if $slow (i32.ne (call $get_type_id (local.get $rhs)) (struct.get $BinaryOpCallSite $type_rhs (local.get $cache))))
        (return (call_ref $BinaryOpFunc (local.get $lhs) (local.get $rhs) (struct.get $BinaryOpCallSite $target (local.get $cache))))
      )
      (call $sub_slow (local.get $lhs) (local.get $rhs) (local.get $cache))
  )` : ''}

  (func $add (param $lhs anyref) (param $rhs anyref) (result anyref)
    (if (result anyref) (ref.test (ref i31) (local.get $lhs))
      (then
        (if (result anyref) (ref.test (ref i31) (local.get $rhs))
          (then
            (ref.i31 (i32.add
              (i31.get_s (ref.cast (ref i31) (local.get $lhs)))
              (i31.get_s (ref.cast (ref i31) (local.get $rhs)))
            ))
          )
          (else
            (ref.null any)
          )
        )
      )
      (else
        (ref.null any)
      )
    )
  )

  (func $less_than (param $lhs anyref) (param $rhs anyref) (result anyref)
    (if (result anyref) (ref.test (ref i31) (local.get $lhs))
      (then
        (if (result anyref) (ref.test (ref i31) (local.get $rhs))
          (then
            (ref.i31 (i32.lt_s
              (i31.get_s (ref.cast (ref i31) (local.get $lhs)))
              (i31.get_s (ref.cast (ref i31) (local.get $rhs)))
            ))
          )
          (else
            (ref.i31 (i32.const 0))
          )
        )
      )
      (else
        (ref.i31 (i32.const 0))
      )
    )
  )
${wasmFuncs}
)`;

  // console.log(wat);

  const module = binaryen.parseText(wat);
  module.setFeatures(
    binaryen.Features.GC |
    binaryen.Features.ReferenceTypes |
    binaryen.Features.BulkMemory
  );

  module.runPasses([
    "remove-unused-brs",
    "remove-unused-names",
    "remove-unused-module-elements",
  ]);

  if (!module.validate()) {
    throw new Error('Validation failed');
  }

  const finalizedWat = module.emitText();
  module.dispose();

  return finalizedWat;
}
