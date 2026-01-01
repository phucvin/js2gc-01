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

  // Very basic type inference based on the return statement
  let returnType = 'void';
  let body = '';

  if (mainFunc.body) {
    mainFunc.body.statements.forEach(stmt => {
      if (ts.isReturnStatement(stmt) && stmt.expression) {
        if (ts.isNumericLiteral(stmt.expression)) {
          returnType = 'f64';
          body = `(struct.new $BoxedNumber (f64.const ${stmt.expression.text}))`;
        } else if (ts.isStringLiteral(stmt.expression)) {
          returnType = '(ref string)';
          body = `(struct.new $BoxedString (string.const "${stmt.expression.text}"))`;
        }
      }
    });
  }

  if (returnType === 'void') {
     throw new Error('Unsupported main function return type');
  }

  return `(module
  (type $BoxedNumber (struct (field f64)))
  (type $BoxedString (struct (field (ref string))))
  (func $main (export "main") (result anyref)
    ${body}
  )
)`;
}
