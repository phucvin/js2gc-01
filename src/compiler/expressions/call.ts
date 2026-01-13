import ts from 'typescript';
import { CompilationContext, registerGlobalCallSite, getPropertyId } from '../context.ts';
import { compileExpression } from '../expression.ts';

export function compileCallExpression(
  expr: ts.CallExpression,
  ctx: CompilationContext,
  dropResult: boolean,
): string {
    const options = ctx.getOptions();
    const enableIC = options.enableInlineCache !== false;
    const fallback = (code: string) => (dropResult ? `(drop ${code})` : code);

    // Direct console.log is handled in compileExpression wrapper, but if we get here, it wasn't caught?
    // Actually compileExpression delegates to this only if it's not console.log?
    // The main loop calls specific handlers.

    if (ts.isIdentifier(expr.expression)) {
      const funcName = expr.expression.text;
      const lookup = ctx.lookup(`$user_${funcName}`);

      if (lookup.type === 'local' || lookup.type === 'captured') {
        const closureExpr = compileExpression(expr.expression, ctx);
        const args = expr.arguments.map((arg) => compileExpression(arg, ctx));

        const closureLocal = ctx.getTempLocal('(ref null $Closure)');
        const sigName = `$ClosureSig${args.length}`;

        let argsCode = '';
        args.forEach((argCode) => {
          argsCode += argCode + ' ';
        });

        const code = `(block (result anyref)
                   (call_ref ${sigName}
                       (struct.get $Closure $env (local.tee ${closureLocal} (ref.cast (ref $Closure) ${closureExpr})))
                       (ref.null any) ;; $this for simple function call
                       ${argsCode}
                       (ref.cast (ref ${sigName}) (struct.get $Closure $func (local.get ${closureLocal})))
                   )
               )`;
        return fallback(code);
      } else {
        const code = `(call $${funcName} ${expr.arguments.map((a) => compileExpression(a, ctx)).join(' ')})`;
        return fallback(code);
      }
    } else if (
      ts.isPropertyAccessExpression(expr.expression) &&
      ts.isIdentifier(expr.expression.expression) &&
      expr.expression.expression.text === 'Object' &&
      expr.expression.name.text === 'create'
    ) {
      // Object.create(proto)
      const protoExpr = expr.arguments[0];
      const protoCode = compileExpression(protoExpr, ctx);
      const objLocal = ctx.getTempLocal('(ref null $Object)');

      // 1. Create a new shape with the proto
      // We need a runtime function to create a new root shape given a prototype.
      // (call $new_root_shape (proto))
      // 2. Create the object with that shape
      // (call $new_object (shape) 0)

      const code = `(block (result (ref $Object))
              (local.set ${objLocal} (call $new_object
                  (call $new_root_shape (ref.cast (ref $Object) ${protoCode}))
                  (i32.const 0)
              ))
              (ref.as_non_null (local.get ${objLocal}))
          )`;
      return dropResult ? `(drop ${code})` : code;
    } else if (
      ts.isPropertyAccessExpression(expr.expression) &&
      ts.isIdentifier(expr.expression.name)
    ) {
      // Method call obj.method(...)
      const objExpr = expr.expression.expression;
      const propName = expr.expression.name.text;
      const keyId = getPropertyId(propName);

      const objCode = compileExpression(objExpr, ctx);
      const args = expr.arguments.map((arg) => compileExpression(arg, ctx));

      const objLocal = ctx.getTempLocal('anyref');
      const closureLocal = ctx.getTempLocal('(ref null $Closure)');
      const sigName = `$ClosureSig${args.length}`;

      let argsCode = '';
      args.forEach((argCode) => {
        argsCode += argCode + ' ';
      });

      let getFieldCode = '';
      if (enableIC) {
        const cacheGlobal = registerGlobalCallSite();
        getFieldCode = `(call $get_field_cached (ref.cast (ref $Object) (local.get ${objLocal})) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
      } else {
        getFieldCode = `(call $get_field_slow (ref.cast (ref $Object) (local.get ${objLocal})) (i32.const ${keyId}))`;
      }

      const code = `(block (result anyref)
              (local.set ${objLocal} ${objCode})
              (call_ref ${sigName}
                  (struct.get $Closure $env (local.tee ${closureLocal} (ref.cast (ref $Closure) ${getFieldCode})))
                  (local.get ${objLocal}) ;; pass obj as $this
                  ${argsCode}
                  (ref.cast (ref ${sigName}) (struct.get $Closure $func (local.get ${closureLocal})))
              )
          )`;
      return fallback(code);
    } else {
      // Indirect call
      const closureExpr = compileExpression(expr.expression, ctx);
      const args = expr.arguments.map((arg) => compileExpression(arg, ctx));
      const closureLocal = ctx.getTempLocal('(ref null $Closure)');
      const sigName = `$ClosureSig${args.length}`;

      let argsCode = '';
      args.forEach((argCode) => {
        argsCode += argCode + ' ';
      });

      const code = `(block (result anyref)
              (call_ref ${sigName}
                   (struct.get $Closure $env (local.tee ${closureLocal} (ref.cast (ref $Closure) ${closureExpr})))
                   (ref.null any) ;; $this for indirect call
                   ${argsCode}
                   (ref.cast (ref ${sigName}) (struct.get $Closure $func (local.get ${closureLocal})))
               )
          )`;
      return fallback(code);
    }
}
