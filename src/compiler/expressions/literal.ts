import ts from 'typescript';
import { CompilationContext, registerStringLiteral, registerShape } from '../context.ts';
import { compileExpression } from '../expression.ts';

export function compileLiteral(expr: ts.Expression, ctx: CompilationContext, dropResult: boolean): string {
    const fallbackPure = (code: string) => (dropResult ? `(nop)` : code);
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);

    if (ts.isNumericLiteral(expr)) {
        const val = Number(expr.text);
        const minI31 = -1073741824;
        const maxI31 = 1073741823;
        const minI32 = -2147483648;
        const maxI32 = 2147483647;

        let code;
        if (Number.isInteger(val) && val >= minI31 && val <= maxI31) {
            code = `(ref.i31 (i32.const ${expr.text}))`;
        } else if (Number.isInteger(val) && val >= minI32 && val <= maxI32) {
            code = `(struct.new $BoxedI32 (i32.const ${expr.text}))`;
        } else {
            code = `(struct.new $BoxedF64 (f64.const ${expr.text}))`;
        }
        return fallbackPure(code);
    } else if (ts.isStringLiteral(expr)) {
        const bytes = Buffer.from(expr.text, 'utf8');
        const len = bytes.length;
        if (len === 0) {
            return fallbackPure(`(array.new_fixed $String 0)`);
        }
        const segmentName = registerStringLiteral(expr.text);
        return fallbackPure(`(array.new_data $String ${segmentName} (i32.const 0) (i32.const ${len}))`);
    } else if (expr.kind === ts.SyntaxKind.NullKeyword) {
        return fallbackPure(`(ref.null any)`);
    } else if (expr.kind === ts.SyntaxKind.TrueKeyword) {
        return fallbackPure(`(ref.i31 (i32.const 1))`);
    } else if (expr.kind === ts.SyntaxKind.FalseKeyword) {
        return fallbackPure(`(ref.i31 (i32.const 0))`);
    } else if (ts.isObjectLiteralExpression(expr)) {
        const propNames: string[] = [];
        for (const prop of expr.properties) {
            if (ts.isPropertyAssignment(prop) && prop.name && ts.isIdentifier(prop.name)) {
                propNames.push(prop.name.text);
            }
        }

        const shapeGlobal = registerShape(propNames);
        const shapeCode = `(global.get ${shapeGlobal})`;

        const totalProps = propNames.length;
        if (totalProps === 0) {
            const code = `(call $new_object ${shapeCode} (i32.const 0))`;
            return dropResult ? `(drop ${code})` : code;
        }

        const objLocal = ctx.getTempLocal('(ref null $Object)');

        let setPropsCode = '';
        let offset = 0;
        for (const prop of expr.properties) {
            if (ts.isPropertyAssignment(prop) && prop.name && ts.isIdentifier(prop.name)) {
                const valCode = compileExpression(prop.initializer, ctx);

                let objAccess;
                if (offset === 0) {
                    objAccess = `(ref.as_non_null (local.tee ${objLocal} (call $new_object ${shapeCode} (i32.const ${totalProps}))))`;
                } else {
                    objAccess = `(ref.as_non_null (local.get ${objLocal}))`;
                }

                setPropsCode += `(call $set_storage ${objAccess} (i32.const ${offset}) ${valCode})\n`;
                offset++;
            }
        }

        const code = `(block (result (ref $Object))
         ${setPropsCode}
         (ref.as_non_null (local.get ${objLocal}))
      )`;
        return dropResult ? `(drop ${code})` : code;
    }

    throw new Error(`Unsupported literal kind: ${ts.SyntaxKind[expr.kind]}`);
}
