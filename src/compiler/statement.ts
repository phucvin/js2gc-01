import ts from 'typescript';
import { compileExpression } from './expression.ts';
import { CompilationContext } from './context.ts';

export function compileStatement(stmt: ts.Statement, ctx: CompilationContext): string {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        return `(return ${compileExpression(stmt.expression, ctx)})`;
    } else if (ts.isExpressionStatement(stmt)) {
        return compileExpression(stmt.expression, ctx);
    }
    return '';
}

export function compileBody(body: ts.Block | undefined, ctx: CompilationContext): string {
  if (!body) return '(ref.null any)';

  const statements = body.statements.map(stmt => compileStatement(stmt, ctx)).filter(s => s !== '');
  if (statements.length === 0) return '(ref.null any)';

  let code = '';
  for (let i = 0; i < statements.length - 1; i++) {
      code += statements[i] + '\n(drop)\n';
  }
  code += statements[statements.length - 1];

  return code;
}
