import ts from 'typescript';

export function compile(source: string): string {
  const sourceFile = ts.createSourceFile(
    'temp.js',
    source,
    ts.ScriptTarget.Latest,
    true
  );

  let mainFunc: ts.FunctionDeclaration | undefined;

  ts.forEachChild(sourceFile, node => {
    if (ts.isFunctionDeclaration(node) && node.name?.text === 'main') {
      mainFunc = node;
    }
  });

  if (!mainFunc) {
    throw new Error('No main function found');
  }

  let body = '';
  // default return?
  // We will assume only one return statement for this basic prototype.
  let foundReturn = false;

  if (mainFunc.body) {
    mainFunc.body.statements.forEach(stmt => {
      if (ts.isReturnStatement(stmt) && stmt.expression) {
        if (ts.isNumericLiteral(stmt.expression)) {
            const val = Number(stmt.expression.text);
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
                 body = `(ref.i31 (i32.const ${stmt.expression.text}))`;
            } else if (Number.isInteger(val) && val >= minI32 && val <= maxI32) {
                 // BoxedI32
                 body = `(struct.new $BoxedI32 (i32.const ${stmt.expression.text}))`;
            } else {
                // Float or large integer treated as double
                body = `(struct.new $BoxedF64 (f64.const ${stmt.expression.text}))`;
            }
        } else if (ts.isStringLiteral(stmt.expression)) {
          body = `(struct.new $BoxedString (string.const "${stmt.expression.text}"))`;
        }
        foundReturn = true;
      }
    });
  }

  if (!foundReturn) {
      throw new Error('Unsupported main function return type or no return found');
  }

  return `(module
  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))

  (func $main (export "main") (result anyref)
    ${body}
  )
)`;
}
