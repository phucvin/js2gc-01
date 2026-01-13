import ts from 'typescript';
import { CompilationContext, registerGlobalCallSite, getPropertyId } from '../context.ts';

export function compileIdentifier(expr: ts.Identifier, ctx: CompilationContext, dropResult: boolean): string {
    const fallbackPure = (code: string) => (dropResult ? `(nop)` : code);
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);
    const options = ctx.getOptions();
    const enableIC = options.enableInlineCache !== false;

    const varName = expr.text;
    const localName = `$user_${varName}`;

    const res = ctx.lookup(localName);

    if (res.type === 'local') {
        return fallbackPure(`(local.get ${localName})`);
    } else if (res.type === 'captured') {
        const keyId = getPropertyId(localName);
        let code;
        if (enableIC) {
            const cacheGlobal = registerGlobalCallSite();
            code = `(call $get_field_cached (ref.cast (ref $Object) (local.get $env)) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
        } else {
            code = `(call $get_field_slow (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}))`;
        }
        return fallback(code);
    }

    throw new Error(`Unknown identifier: ${varName}`);
}
