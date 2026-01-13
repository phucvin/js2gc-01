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
import {
  RUNTIME_TYPES,
  RUNTIME_CLOSURE_SIGS,
  RUNTIME_IMPORTS,
  RUNTIME_GLOBALS_DECL,
  RUNTIME_ELEMS,
  getRuntimeInit,
  getRuntimeHelpers,
} from './runtime.ts';

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

  const wat = `(module
  ${RUNTIME_TYPES}
  ${RUNTIME_CLOSURE_SIGS}
  ${RUNTIME_IMPORTS}
  ${RUNTIME_ELEMS}
  ${globalsDecl}
  ${dataSegmentsDecl}
  ${RUNTIME_GLOBALS_DECL}
  ${getRuntimeInit(nullData, objData)}
  ${getRuntimeHelpers(enableInlineCache)}
  ${wasmFuncs}
)`;

  // console.log(wat);

  const module = binaryen.parseText(wat);
  module.setFeatures(
    binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory,
  );

  module.runPasses(['remove-unused-brs', 'remove-unused-names', 'remove-unused-module-elements']);

  if (!module.validate()) {
    throw new Error('Validation failed');
  }

  const finalizedWat = module.emitText();
  module.dispose();

  return finalizedWat;
}
