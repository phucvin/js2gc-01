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
      }
  }

  throw new Error(`Unsupported expression kind: ${ts.SyntaxKind[expr.kind]}`);
}
