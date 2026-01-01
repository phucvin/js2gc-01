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
    (if (ref.test i31ref (local.get $val))
      (then
        (call $print_i32 (i31.get_s (ref.cast i31ref (local.get $val))))
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
    (ref.null any)
  )

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
}

function compileBody(body: ts.Block | undefined): string {
  if (!body) return '(ref.null any)';

  // If there are multiple statements, we should probably wrap them in a block?
  // Wasm functions have an implicit block.
  // But if we return the last value, we need to make sure previous values are dropped if they leave values on stack.
  // The current compiler seems to return 'anyref'.
  // console.log returns 'anyref' (ref.null any).
  // If we have stmt1; stmt2;
  // We want to generate: stmt1 drop stmt2
  // Or just result of stmt2 if it is the return.

  const compiledStatements: string[] = [];

  body.statements.forEach(stmt => {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        compiledStatements.push(compileExpression(stmt.expression));
    } else if (ts.isExpressionStatement(stmt)) {
        const exprCode = compileExpression(stmt.expression);
        // If it's not the last statement, we might need to drop?
        // But our expressions (console.log) return a value.
        // We should drop it if we are ignoring it.
        // For simplicity in this prototype, let's assume we just sequence them.
        // If we sequence them, the values stack up.
        // (call $console_log ...) leaves a ref.null on stack.
        // If we have multiple statements, we need to drop the intermediate ones.
        compiledStatements.push(`(drop ${exprCode})`);
    }
  });

  if (compiledStatements.length === 0) {
      return '(ref.null any)';
  }

  // The last statement shouldn't be dropped if it is intended to be the return value.
  // But wait, ExpressionStatement implies it is not returned.
  // Only ReturnStatement is returned.
  // If the last statement was an ExpressionStatement, we wrapped it in drop.
  // So the function returns nothing (void).
  // But the function signature says (result anyref).
  // So we must return something.
  // If the last statement was a return, we are good (it pushed a value).
  // If the last statement was an expression statement, we dropped it. We need to push ref.null.

  // Let's refine:
  // We need to concat them.
  // If the last one was a return, it provides the value.
  // If the last one was NOT a return, we need to provide a default value.

  // However, we don't track here easily which one was return.
  // Let's re-iterate.

  let instructions = "";
  let hasReturn = false;

  body.statements.forEach((stmt, index) => {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        instructions += compileExpression(stmt.expression) + "\n";
        hasReturn = true;
        // In a real compiler, we would stop here (unreachable code after return).
    } else if (ts.isExpressionStatement(stmt)) {
        const exprCode = compileExpression(stmt.expression);
        instructions += `(drop ${exprCode})\n`;
    }
  });

  if (!hasReturn) {
      instructions += "(ref.null any)";
  }

  return instructions;
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
