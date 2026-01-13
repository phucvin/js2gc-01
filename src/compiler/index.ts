import ts from 'typescript';
import binaryen from 'binaryen';
import { compileFunction } from './function.ts';
import {
    resetPropertyMap,
    resetGlobalCallSites,
    globalCallSites,
    generatedFunctions,
    resetGeneratedFunctions,
    binaryOpCallSites,
    type CompilerOptions,
    resetStringMap,
    stringDataSegments,
    registerStringLiteral,
    resetShapeCache,
    shapeGlobals,
} from './context.ts';
import { resetClosureCounter } from './expression.ts';
import { getRuntime } from './runtime.ts';

// Export for other files to use if needed
export type { CompilerOptions };

export function compile(source: string, options?: CompilerOptions): string {
    // Default options
    const compilerOptions: CompilerOptions = {
        enableInlineCache: true,
        ...options,
    };

    const enableInlineCache = compilerOptions.enableInlineCache !== false;

    resetPropertyMap();
    resetGlobalCallSites();
    resetGeneratedFunctions();
    resetClosureCounter();
    resetStringMap();
    resetShapeCache();

    const nullData = registerStringLiteral('null');
    const objData = registerStringLiteral('[object Object]');

    const sourceFile = ts.createSourceFile('temp.js', source, ts.ScriptTarget.Latest, true);

    const functions: ts.FunctionDeclaration[] = [];

    ts.forEachChild(sourceFile, (node) => {
        if (ts.isFunctionDeclaration(node) && node.name) {
            functions.push(node);
        }
    });

    const mainFunc = functions.find((f) => f.name?.text === 'main');

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
            globalsDecl += `(global ${siteName} (mut (ref $CallSite)) (struct.new $CallSite (ref.null $Shape) (i32.const -1) (ref.null any)))\n`;
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
      (field $proto anyref)
    ))

    (type $Storage (array (mut anyref)))

    (type $Object (struct
      (field $shape (mut (ref $Shape)))
      (field $storage (mut (ref $Storage)))
    ))

    ${
        enableInlineCache
            ? `(type $CallSite (struct
      (field $expected_shape (mut (ref null $Shape)))
      (field $offset (mut i32))
      (field $holder (mut anyref))
    ))`
            : ''
    }

    (type $Closure (struct
      (field $func (ref func))
      (field $env anyref)
    ))

    (type $BinaryOpFunc (func (param anyref) (param anyref) (result anyref)))

    ${
        enableInlineCache
            ? `(type $BinaryOpCallSite (struct
      (field $type_lhs (mut i32))
      (field $type_rhs (mut i32))
      (field $target (mut (ref null $BinaryOpFunc)))
    ))`
            : ''
    }
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

  ${getRuntime(enableInlineCache, nullData, objData)}
${wasmFuncs}
)`;

    // console.log(wat);

    const module = binaryen.parseText(wat);
    module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory);

    module.runPasses(['remove-unused-brs', 'remove-unused-names', 'remove-unused-module-elements']);

    if (!module.validate()) {
        throw new Error('Validation failed');
    }

    const finalizedWat = module.emitText();
    module.dispose();

    return finalizedWat;
}
