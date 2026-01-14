import ts from 'typescript';
import { CompilationContext, registerBinaryOpCallSite, getPropertyId } from '../context.ts';
import { compileExpression } from '../expression.ts';

export function compileBinaryExpression(
    expr: ts.BinaryExpression,
    ctx: CompilationContext,
    dropResult: boolean,
): string {
    const options = ctx.getOptions();
    const enableIC = options.enableInlineCache !== false;
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);

    if (expr.operatorToken.kind === ts.SyntaxKind.PlusToken) {
        const left = compileExpression(expr.left, ctx);
        const right = compileExpression(expr.right, ctx);
        let code;
        if (enableIC) {
            const siteName = registerBinaryOpCallSite();
            code = `(call $add_cached ${left} ${right} (global.get ${siteName}))`;
        } else {
            code = `(call $add_slow ${left} ${right})`;
        }
        return fallback(code);
    } else if (expr.operatorToken.kind === ts.SyntaxKind.MinusToken) {
        const left = compileExpression(expr.left, ctx);
        const right = compileExpression(expr.right, ctx);
        let code;
        if (enableIC) {
            const siteName = registerBinaryOpCallSite();
            code = `(call $sub_cached ${left} ${right} (global.get ${siteName}))`;
        } else {
            code = `(call $sub_slow ${left} ${right})`;
        }
        return fallback(code);
    } else if (expr.operatorToken.kind === ts.SyntaxKind.LessThanToken) {
        const left = compileExpression(expr.left, ctx);
        const right = compileExpression(expr.right, ctx);
        return fallback(`(call $less_than ${left} ${right})`);
    } else if (expr.operatorToken.kind === ts.SyntaxKind.EqualsToken) {
        if (ts.isIdentifier(expr.left)) {
            const varName = expr.left.text;
            const localName = `$user_${varName}`;

            const res = ctx.lookup(localName);
            if (res.type === 'global') {
                throw new Error(`Variable ${varName} not declared`);
            }

            const right = compileExpression(expr.right, ctx);

            if (res.type === 'local') {
                if (dropResult) {
                    return `(local.set ${localName} ${right})`;
                } else {
                    return `(local.tee ${localName} ${right})`;
                }
            } else {
                const keyId = getPropertyId(localName);

                if (dropResult) {
                    return `(call $put_field (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}) ${right})`;
                } else {
                    const temp = ctx.getTempLocal('anyref');
                    return `(block (result anyref) (call $put_field (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}) (local.tee ${temp} ${right})) (local.get ${temp}))`;
                }
            }
        } else if (ts.isPropertyAccessExpression(expr.left)) {
            if (ts.isIdentifier(expr.left.name)) {
                const keyId = getPropertyId(expr.left.name.text);
                const objCode = compileExpression(expr.left.expression, ctx);
                const valCode = compileExpression(expr.right, ctx);

                if (dropResult) {
                    return `(call $put_field (ref.cast (ref $Object) ${objCode}) (i32.const ${keyId}) ${valCode})`;
                } else {
                    const temp = ctx.getTempLocal('anyref');
                    return `(block (result anyref) (call $put_field (ref.cast (ref $Object) ${objCode}) (i32.const ${keyId}) (local.tee ${temp} ${valCode})) (local.get ${temp}))`;
                }
            }
        }
    }

    throw new Error(`Unsupported binary operator: ${ts.SyntaxKind[expr.operatorToken.kind]}`);
}
