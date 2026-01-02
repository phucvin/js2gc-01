import ts from 'typescript';
import { compileExpression } from './expression.ts';
import { CompilationContext } from './context.ts';

export function compileStatement(stmt: ts.Statement, ctx: CompilationContext): string {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        return `(return ${compileExpression(stmt.expression, ctx)})`;
    } else if (ts.isExpressionStatement(stmt)) {
        return compileExpression(stmt.expression, ctx);
    } else if (ts.isVariableStatement(stmt)) {
        let code = '';
        for (const decl of stmt.declarationList.declarations) {
            if (ts.isIdentifier(decl.name)) {
                const varName = decl.name.text;
                const localName = `$user_${varName}`;
                ctx.addLocal(localName, 'anyref');

                if (decl.initializer) {
                    const initVal = compileExpression(decl.initializer, ctx);
                    code += `(local.set ${localName} ${initVal})\n`;
                } else {
                    code += `(local.set ${localName} (ref.null any))\n`;
                }
            }
        }
        // Statements in compileBody are expected to leave a value to be dropped or be void.
        // However, VariableStatement in JS is void.
        // But our compileBody loop adds (drop) after every statement except the last one.
        // If we return (local.set ...), it consumes the value.
        // So we should append (ref.null any) so the loop can drop it.
        return code + '(ref.null any)';
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
