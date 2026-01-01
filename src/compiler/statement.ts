import ts from 'typescript';
import { compileExpression } from './expression.ts';

export function compileStatement(stmt: ts.Statement): string {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        return compileExpression(stmt.expression);
    } else if (ts.isExpressionStatement(stmt)) {
        return compileExpression(stmt.expression);
    }
    return '';
}

export function compileBody(body: ts.Block | undefined): string {
  if (!body) return '(ref.null any)';

  let code = '(ref.null any)'; // Default return if no return statement found

  body.statements.forEach(stmt => {
    const res = compileStatement(stmt);
    if (res) code = res;
  });

  return code;
}
