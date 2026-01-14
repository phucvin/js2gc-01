import ts from 'typescript';
import { CompilationContext, registerGlobalCallSite, getPropertyId, registerBinaryOpCallSite } from '../context.ts';
import { compileExpression } from '../expression.ts';

export function compilePostfixUnary(
    expr: ts.PostfixUnaryExpression,
    ctx: CompilationContext,
    dropResult: boolean,
): string {
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);
    const options = ctx.getOptions();
    const enableIC = options.enableInlineCache !== false;

    if (expr.operator === ts.SyntaxKind.PlusPlusToken) {
        if (ts.isIdentifier(expr.operand)) {
            const varName = expr.operand.text;
            const localName = `$user_${varName}`;
            const res = ctx.lookup(localName);
            if (res.type === 'global') {
                throw new Error(`Variable ${varName} not declared`);
            }

            if (res.type === 'local') {
                const tempLocal = ctx.getTempLocal('anyref');
                let addCall;
                if (enableIC) {
                    const siteName = registerBinaryOpCallSite();
                    addCall = `(call $add_cached (local.get ${tempLocal}) (ref.i31 (i32.const 1)) (global.get ${siteName}))`;
                } else {
                    addCall = `(call $add_slow (local.get ${tempLocal}) (ref.i31 (i32.const 1)))`;
                }

                const code = `(block (result anyref)
                  (local.set ${tempLocal} (local.get ${localName}))
                  (local.set ${localName} ${addCall})
                  (local.get ${tempLocal})
              )`;
                return fallback(code);
            } else {
                const tempLocal = ctx.getTempLocal('anyref');
                const keyId = getPropertyId(localName);

                let envGet;
                if (enableIC) {
                    const cacheGlobalGet = registerGlobalCallSite();
                    envGet = `(call $get_field_cached (ref.cast (ref $Object) (local.get $env)) (global.get ${cacheGlobalGet}) (i32.const ${keyId}))`;
                } else {
                    envGet = `(call $get_field_slow (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}))`;
                }

                let addCall;
                if (enableIC) {
                    const siteName = registerBinaryOpCallSite();
                    addCall = `(call $add_cached (local.get ${tempLocal}) (ref.i31 (i32.const 1)) (global.get ${siteName}))`;
                } else {
                    addCall = `(call $add_slow (local.get ${tempLocal}) (ref.i31 (i32.const 1)))`;
                }

                const code = `(block (result anyref)
                   (local.set ${tempLocal} ${envGet})
                   (call $put_field (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}) ${addCall})
                   (local.get ${tempLocal})
              )`;
                return fallback(code);
            }
        }
    }
    throw new Error(`Unsupported postfix unary operator: ${ts.SyntaxKind[expr.operator]}`);
}

export function compilePropertyAccess(
    expr: ts.PropertyAccessExpression,
    ctx: CompilationContext,
    dropResult: boolean,
): string {
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);
    const options = ctx.getOptions();
    const enableIC = options.enableInlineCache !== false;

    if (ts.isIdentifier(expr.name)) {
        const keyId = getPropertyId(expr.name.text);
        const objCode = compileExpression(expr.expression, ctx);
        let code;
        if (enableIC) {
            const cacheGlobal = registerGlobalCallSite();
            code = `(call $get_field_cached (ref.cast (ref $Object) ${objCode}) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
        } else {
            code = `(call $get_field_slow (ref.cast (ref $Object) ${objCode}) (i32.const ${keyId}))`;
        }
        return fallback(code);
    }
    throw new Error(`Unsupported property access expression`);
}
