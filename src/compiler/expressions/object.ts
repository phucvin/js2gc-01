import ts from 'typescript';
import { CompilationContext, registerShape, getPropertyId, registerGlobalCallSite } from '../context.ts';
import { compileExpression } from '../expression.ts';

export function compileObjectLiteralExpression(
  expr: ts.ObjectLiteralExpression,
  ctx: CompilationContext,
  dropResult: boolean,
): string {
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
          // We must use ref.as_non_null because local.tee returns the type of the local (nullable),
          // but set_storage expects a non-nullable reference.
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

export function compilePropertyAccessExpression(
    expr: ts.PropertyAccessExpression,
    ctx: CompilationContext,
    dropResult: boolean,
): string {
    const options = ctx.getOptions();
    const enableIC = options.enableInlineCache !== false;
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);

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
    throw new Error(`Unsupported property access: ${expr.getText()}`);
}
