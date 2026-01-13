import ts from 'typescript';
import { CompilationContext } from './context.ts';
import { compileLiteralExpression } from './expressions/literal.ts';
import { compileBinaryExpression, compilePostfixUnaryExpression } from './expressions/binary.ts';
import { compileCallExpression } from './expressions/call.ts';
import { compileFunctionExpression, resetClosureCounter } from './expressions/function.ts';
import { compileObjectLiteralExpression, compilePropertyAccessExpression } from './expressions/object.ts';
import { compileIdentifier, compileThisKeyword } from './expressions/identifier.ts';

// Export reset for index.ts to call
export { resetClosureCounter };

export function compileExpression(
  expr: ts.Expression,
  ctx: CompilationContext,
  dropResult: boolean = false,
): string {
  // Handle console.log specifically to support void return
  if (
    ts.isCallExpression(expr) &&
    ts.isPropertyAccessExpression(expr.expression) &&
    ts.isIdentifier(expr.expression.expression) &&
    expr.expression.expression.text === 'console' &&
    expr.expression.name.text === 'log'
  ) {
    if (expr.arguments.length > 0) {
      const arg = compileExpression(expr.arguments[0], ctx);
      const callCode = `(call $console_log ${arg})`;
      if (dropResult) return callCode;
      return `(block (result anyref) ${callCode} (ref.null any))`;
    } else {
      if (dropResult) return `(nop)`;
      return `(ref.null any)`;
    }
  }

  const literal = compileLiteralExpression(expr, ctx, dropResult);
  if (literal !== null) return literal;

  if (ts.isBinaryExpression(expr)) {
      return compileBinaryExpression(expr, ctx, dropResult);
  }

  if (ts.isPostfixUnaryExpression(expr)) {
      return compilePostfixUnaryExpression(expr, ctx, dropResult);
  }

  if (ts.isCallExpression(expr)) {
      return compileCallExpression(expr, ctx, dropResult);
  }

  if (ts.isObjectLiteralExpression(expr)) {
      return compileObjectLiteralExpression(expr, ctx, dropResult);
  }

  if (ts.isArrowFunction(expr) || ts.isFunctionExpression(expr)) {
      const code = compileFunctionExpression(expr, ctx);
      // See note in expression.ts about pure fallback
      return dropResult ? `(nop)` : code;
  }

  if (ts.isIdentifier(expr)) {
      return compileIdentifier(expr, ctx, dropResult);
  }

  if (expr.kind === ts.SyntaxKind.ThisKeyword) {
      return compileThisKeyword(expr as ts.ThisExpression, ctx, dropResult);
  }

  if (ts.isPropertyAccessExpression(expr)) {
      return compilePropertyAccessExpression(expr, ctx, dropResult);
  }

  throw new Error(`Unsupported expression kind: ${ts.SyntaxKind[expr.kind]}`);
}
