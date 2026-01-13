import ts from 'typescript';
import { CompilationContext, registerGlobalCallSite, getPropertyId } from './context.ts';
import { compileLiteral } from './expressions/literal.ts';
import { compileBinaryExpression } from './expressions/binary.ts';
import { compileCallExpression } from './expressions/call.ts';
import { compileFunctionExpression, resetClosureCounter } from './expressions/function.ts';
import { compileIdentifier } from './expressions/identifier.ts';
import { compilePostfixUnary, compilePropertyAccess } from './expressions/object.ts';

// Export reset for index.ts
export { resetClosureCounter };

export function compileExpression(expr: ts.Expression, ctx: CompilationContext, dropResult: boolean = false): string {
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

    return compileExpressionValue(expr, ctx, dropResult);
}

function compileExpressionValue(expr: ts.Expression, ctx: CompilationContext, dropResult: boolean): string {
    const fallbackPure = (code: string) => (dropResult ? `(nop)` : code);
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);
    const options = ctx.getOptions();
    const enableIC = options.enableInlineCache !== false;

    if (
        ts.isNumericLiteral(expr) ||
        ts.isStringLiteral(expr) ||
        expr.kind === ts.SyntaxKind.NullKeyword ||
        expr.kind === ts.SyntaxKind.TrueKeyword ||
        expr.kind === ts.SyntaxKind.FalseKeyword ||
        ts.isObjectLiteralExpression(expr)
    ) {
        return compileLiteral(expr, ctx, dropResult);
    } else if (ts.isCallExpression(expr)) {
        return compileCallExpression(expr, ctx, dropResult);
    } else if (ts.isBinaryExpression(expr)) {
        return compileBinaryExpression(expr, ctx, dropResult);
    } else if (ts.isPostfixUnaryExpression(expr)) {
        return compilePostfixUnary(expr, ctx, dropResult);
    } else if (ts.isPropertyAccessExpression(expr)) {
        return compilePropertyAccess(expr, ctx, dropResult);
    } else if (ts.isIdentifier(expr)) {
        return compileIdentifier(expr, ctx, dropResult);
    } else if (ts.isArrowFunction(expr) || ts.isFunctionExpression(expr)) {
        return fallbackPure(compileFunctionExpression(expr, ctx));
    } else if (expr.kind === ts.SyntaxKind.ThisKeyword) {
        try {
            const res = ctx.lookup('$this');
            if (res.type === 'local') {
                return fallbackPure(`(local.get $this)`);
            } else if (res.type === 'captured') {
                const keyId = getPropertyId('$this');
                let code;
                if (enableIC) {
                    const cacheGlobal = registerGlobalCallSite();
                    code = `(call $get_field_cached (ref.cast (ref $Object) (local.get $env)) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
                } else {
                    code = `(call $get_field_slow (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}))`;
                }
                return fallback(code);
            }
        } catch (e) {
            return fallbackPure(`(ref.null any)`);
        }
        return fallbackPure(`(ref.null any)`);
    }

    throw new Error(`Unsupported expression kind: ${ts.SyntaxKind[expr.kind]}`);
}
