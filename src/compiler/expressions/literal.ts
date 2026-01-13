import ts from 'typescript';
import { CompilationContext, registerStringLiteral, registerShape } from '../context.ts';
import { compileExpression } from './index.ts';

export function compileNumericLiteral(expr: ts.NumericLiteral, ctx: CompilationContext, dropResult: boolean): string {
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
    return dropResult ? `(nop)` : code;
}

export function compileStringLiteral(expr: ts.StringLiteral, ctx: CompilationContext, dropResult: boolean): string {
    const bytes = Buffer.from(expr.text, 'utf8');
    const len = bytes.length;
    if (len === 0) {
      const code = `(array.new_fixed $String 0)`;
      return dropResult ? `(nop)` : code;
    }
    const segmentName = registerStringLiteral(expr.text);
    const code = `(array.new_data $String ${segmentName} (i32.const 0) (i32.const ${len}))`;
    return dropResult ? `(nop)` : code;
}

export function compileObjectLiteral(expr: ts.ObjectLiteralExpression, ctx: CompilationContext, dropResult: boolean): string {
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
