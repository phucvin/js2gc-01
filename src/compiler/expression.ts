import ts from 'typescript';
import { getPropertyId, CompilationContext } from './context.ts';

export function compileExpression(expr: ts.Expression, ctx: CompilationContext): string {
  if (ts.isNumericLiteral(expr)) {
      const val = Number(expr.text);
      const minI31 = -1073741824;
      const maxI31 = 1073741823;
      const minI32 = -2147483648;
      const maxI32 = 2147483647;

      if (Number.isInteger(val) && val >= minI31 && val <= maxI31) {
           return `(ref.i31 (i32.const ${expr.text}))`;
      } else if (Number.isInteger(val) && val >= minI32 && val <= maxI32) {
           return `(struct.new $BoxedI32 (i32.const ${expr.text}))`;
      } else {
          return `(struct.new $BoxedF64 (f64.const ${expr.text}))`;
      }
  } else if (ts.isStringLiteral(expr)) {
    return `(struct.new $BoxedString (string.const "${expr.text}"))`;
  } else if (ts.isObjectLiteralExpression(expr)) {
      // 1. Construct shape
      // (call $extend_shape (call $extend_shape (call $new_root_shape) key1 0) key2 1)
      let shapeCode = `(call $new_root_shape)`;
      let offset = 0;
      for (const prop of expr.properties) {
          if (ts.isPropertyAssignment(prop) && prop.name && ts.isIdentifier(prop.name)) {
              const keyId = getPropertyId(prop.name.text);
              shapeCode = `(call $extend_shape ${shapeCode} (i32.const ${keyId}) (i32.const ${offset}))`;
              offset++;
          }
      }

      // 2. Create object and store in temp local
      const objLocal = ctx.getTempLocal('(ref null $Object)');

      // 3. Set properties
      let setPropsCode = '';
      offset = 0;
      for (const prop of expr.properties) {
          if (ts.isPropertyAssignment(prop) && prop.name && ts.isIdentifier(prop.name)) {
              const valCode = compileExpression(prop.initializer, ctx);
              setPropsCode += `(call $set_storage (ref.as_non_null (local.get ${objLocal})) (i32.const ${offset}) ${valCode})\n`;
              offset++;
          }
      }

      // Combine: set local, set props, return local
      return `(block (result (ref $Object))
         (local.set ${objLocal} (call $new_object ${shapeCode} (i32.const ${offset})))
         ${setPropsCode}
         (ref.as_non_null (local.get ${objLocal}))
      )`;

  } else if (ts.isCallExpression(expr)) {
      if (ts.isIdentifier(expr.expression)) {
          const funcName = expr.expression.text;
          return `(call $${funcName})`;
      } else if (ts.isPropertyAccessExpression(expr.expression) &&
                 ts.isIdentifier(expr.expression.expression) &&
                 expr.expression.expression.text === 'console' &&
                 expr.expression.name.text === 'log') {
          if (expr.arguments.length > 0) {
              const arg = compileExpression(expr.arguments[0], ctx);
              return `(call $console_log ${arg})`;
          } else {
              return `(ref.null any)`;
          }
      }
  } else if (ts.isBinaryExpression(expr)) {
      if (expr.operatorToken.kind === ts.SyntaxKind.PlusToken) {
          const left = compileExpression(expr.left, ctx);
          const right = compileExpression(expr.right, ctx);
          return `(call $add ${left} ${right})`;
      } else if (expr.operatorToken.kind === ts.SyntaxKind.LessThanToken) {
          const left = compileExpression(expr.left, ctx);
          const right = compileExpression(expr.right, ctx);
          return `(call $less_than ${left} ${right})`;
      } else if (expr.operatorToken.kind === ts.SyntaxKind.EqualsToken) {
          // Assignment
          if (ts.isIdentifier(expr.left)) {
              const varName = expr.left.text;
              const localName = `$user_${varName}`;
              if (!ctx.hasLocal(localName)) {
                  throw new Error(`Variable ${varName} not declared`);
              }
              const right = compileExpression(expr.right, ctx);
              return `(local.tee ${localName} ${right})`;
          }
      }
  } else if (ts.isPostfixUnaryExpression(expr)) {
      if (expr.operator === ts.SyntaxKind.PlusPlusToken) {
          if (ts.isIdentifier(expr.operand)) {
              const varName = expr.operand.text;
              const localName = `$user_${varName}`;
              if (!ctx.hasLocal(localName)) {
                  throw new Error(`Variable ${varName} not declared`);
              }
              const tempLocal = ctx.getTempLocal('anyref');
              return `(block (result anyref)
                  (local.set ${tempLocal} (local.get ${localName}))
                  (local.set ${localName} (call $add (local.get ${tempLocal}) (ref.i31 (i32.const 1))))
                  (local.get ${tempLocal})
              )`;
          }
      }
  } else if (ts.isPropertyAccessExpression(expr)) {
      if (ts.isIdentifier(expr.name)) {
          const keyId = getPropertyId(expr.name.text);
          const objCode = compileExpression(expr.expression, ctx);

          // Initialize the call site
          // Note: In a real compiler, we would hoist this initialization or use a global.
          // For now, we'll initialize it locally, which is suboptimal but works for demonstration if we had persistent locals.
          // Actually, `ctx.getTempLocal` reuses locals, so we need to be careful.
          // To implement inline cache properly, the CallSite must persist across executions of this code point.
          // Since we compile to a single function body mostly, we can't easily allocate static globals per callsite yet without more complex codegen.
          // However, the task assumes we support inline cache.
          // Let's create a new local variable for each property access that is NOT a temp local, effectively acting as a function-scoped cache.
          // But wait, `ctx` doesn't support allocating "persistent" locals per AST node easily.
          // We can allocate a unique local for this specific property access.

          const cacheLocal = ctx.getUniqueLocalName('$cache_');
          // Start with nullable type to avoid validation errors about initialization
          ctx.addLocal(cacheLocal, '(ref null $CallSite)');

          return `(block (result anyref)
             (if (ref.is_null (local.get ${cacheLocal}))
               (then (local.set ${cacheLocal} (call $new_callsite)))
             )
             (call $get_field_cached (ref.cast (ref $Object) ${objCode}) (ref.as_non_null (local.get ${cacheLocal})) (i32.const ${keyId}))
          )`;
      }
  } else if (ts.isIdentifier(expr)) {
      const varName = expr.text;
      const localName = `$user_${varName}`;
      if (ctx.hasLocal(localName)) {
          return `(local.get ${localName})`;
      }
      throw new Error(`Unknown identifier: ${varName}`);
  }

  throw new Error(`Unsupported expression kind: ${ts.SyntaxKind[expr.kind]}`);
}
