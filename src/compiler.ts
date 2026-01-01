import ts from 'typescript';
import binaryen from 'binaryen';

export function compile(source: string): string {
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
    const name = func.name!.text;
    const isMain = name === 'main';
    const exportClause = isMain ? '(export "main")' : '';

    // Compile body
    const body = compileBody(func.body);

    wasmFuncs += `
  (func $${name} ${exportClause} (result anyref)
    ${body}
  )`;
  }

  const wat = `(module
  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))
  (func $add (param $lhs anyref) (param $rhs anyref) (result anyref)
    (if (result anyref) (ref.test i31ref (local.get $lhs))
      (then
        (if (result anyref) (ref.test i31ref (local.get $rhs))
          (then
            (ref.i31 (i32.add
              (i31.get_s (ref.cast i31ref (local.get $lhs)))
              (i31.get_s (ref.cast i31ref (local.get $rhs)))
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
${wasmFuncs}
)`;

  const module = binaryen.parseText(wat);

  // Enable GC and other features
  module.setFeatures(
    binaryen.Features.GC |
    binaryen.Features.ReferenceTypes |
    binaryen.Features.Strings |
    binaryen.Features.Multivalue // Multivalue is often useful, but not strictly requested. GC implies RefTypes.
  );

  // Validate to ensure everything is correct before optimization
  if (!module.validate()) {
      module.dispose();
      throw new Error("Module failed validation");
  }

  module.optimize();

  const optimizedWat = module.emitText();
  module.dispose();

  return optimizedWat;
}

function compileBody(body: ts.Block | undefined): string {
  if (!body) return '(ref.null any)';

  let code = '(ref.null any)'; // Default return if no return statement found

  // We scan for the last return statement
  body.statements.forEach(stmt => {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        code = compileExpression(stmt.expression);
    }
  });

  return code;
}

function compileExpression(expr: ts.Expression): string {
  if (ts.isNumericLiteral(expr)) {
      const val = Number(expr.text);
      // Check for i31 range: signed 31-bit integer.
      // Range: [-2^30, 2^30 - 1]
      // -1073741824 to 1073741823
      const minI31 = -1073741824;
      const maxI31 = 1073741823;

      // Check for i32 range: signed 32-bit integer.
      // Range: [-2^31, 2^31 - 1]
      // -2147483648 to 2147483647
      const minI32 = -2147483648;
      const maxI32 = 2147483647;

      if (Number.isInteger(val) && val >= minI31 && val <= maxI31) {
           // i31
           return `(ref.i31 (i32.const ${expr.text}))`;
      } else if (Number.isInteger(val) && val >= minI32 && val <= maxI32) {
           // BoxedI32
           return `(struct.new $BoxedI32 (i32.const ${expr.text}))`;
      } else {
          // Float or large integer treated as double
          return `(struct.new $BoxedF64 (f64.const ${expr.text}))`;
      }
  } else if (ts.isStringLiteral(expr)) {
    return `(struct.new $BoxedString (string.const "${expr.text}"))`;
  } else if (ts.isCallExpression(expr)) {
      if (ts.isIdentifier(expr.expression)) {
          const funcName = expr.expression.text;
          return `(call $${funcName})`;
      }
  } else if (ts.isBinaryExpression(expr)) {
      if (expr.operatorToken.kind === ts.SyntaxKind.PlusToken) {
          const left = compileExpression(expr.left);
          const right = compileExpression(expr.right);
          return `(call $add ${left} ${right})`;
      }
  }

  throw new Error(`Unsupported expression kind: ${ts.SyntaxKind[expr.kind]}`);
}
