import ts from 'typescript';

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
    const isTest = name === 'test';
    let exportClause = '';
    if (isMain) exportClause = '(export "main")';
    if (isTest) exportClause = '(export "test")';

    // Compile body
    const body = compileBody(func.body);

    wasmFuncs += `
  (func $${name} ${exportClause} (result anyref)
    ${body}
  )`;
  }

  return `(module
  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))
  (import "env" "print_i32" (func $print_i32 (param i32)))
  (import "env" "print_f64" (func $print_f64 (param f64)))
  (import "env" "print_string" (func $print_string (param (ref string))))

  (func $console_log (param $val anyref) (result anyref)
    (if (ref.is_null (local.get $val))
      (then
        (call $print_string (string.const "null"))
      )
      (else
        (if (ref.test (ref i31) (local.get $val))
          (then
            (call $print_i32 (i31.get_s (ref.cast (ref i31) (local.get $val))))
          )
          (else
            (if (ref.test (ref $BoxedI32) (local.get $val))
              (then
                (call $print_i32 (struct.get $BoxedI32 0 (ref.cast (ref $BoxedI32) (local.get $val))))
              )
              (else
                (if (ref.test (ref $BoxedF64) (local.get $val))
                  (then
                    (call $print_f64 (struct.get $BoxedF64 0 (ref.cast (ref $BoxedF64) (local.get $val))))
                  )
                  (else
                    (if (ref.test (ref $BoxedString) (local.get $val))
                      (then
                        (call $print_string (struct.get $BoxedString 0 (ref.cast (ref $BoxedString) (local.get $val))))
                      )
                    )
                  )
                )
              )
            )
          )
        )
      )
    )
    (ref.null any)
  )

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
${wasmFuncs}
)`;
}

function compileBody(body: ts.Block | undefined): string {
  if (!body) return '(ref.null any)';

  let code = '(ref.null any)'; // Default return if no return statement found

  body.statements.forEach(stmt => {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        code = compileExpression(stmt.expression);
    } else if (ts.isExpressionStatement(stmt)) {
        const exprCode = compileExpression(stmt.expression);
        code = exprCode;
    }
  });

  return code;
}

function compileExpression(expr: ts.Expression): string {
  if (ts.isNumericLiteral(expr)) {
      const val = Number(expr.text);
      const minI31 = -1073741824;
      const maxI31 = 1073741823;
      const minI32 = -2147483648;
      const maxI32 = 2147483647;

      if (Number.isInteger(val) && val >= minI31 && val <= maxI31) {
           return `(ref.i31 (i32.const ${expr.text}))`;
      } else if (Number.isInteger(val) && val >= minI32 && val <= maxI32) {
           return `(struct.new $BoxedI32 (i32.const ${expr.text}))`;
      } else {
          return `(struct.new $BoxedF64 (f64.const ${expr.text}))`;
      }
  } else if (ts.isStringLiteral(expr)) {
    return `(struct.new $BoxedString (string.const "${expr.text}"))`;
  } else if (ts.isCallExpression(expr)) {
      if (ts.isIdentifier(expr.expression)) {
          const funcName = expr.expression.text;
          return `(call $${funcName})`;
      } else if (ts.isPropertyAccessExpression(expr.expression) &&
                 ts.isIdentifier(expr.expression.expression) &&
                 expr.expression.expression.text === 'console' &&
                 expr.expression.name.text === 'log') {
          if (expr.arguments.length > 0) {
              const arg = compileExpression(expr.arguments[0]);
              return `(call $console_log ${arg})`;
          } else {
              return `(ref.null any)`;
          }
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
