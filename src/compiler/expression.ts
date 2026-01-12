import ts from 'typescript';
import { getPropertyId, CompilationContext, registerGlobalCallSite, registerGeneratedFunction, registerBinaryOpCallSite } from './context.ts';
import { compileBody } from './statement.ts';

let closureCounter = 0;

function resetClosureCounter() {
    closureCounter = 0;
}

// Export reset for index.ts to call
export { resetClosureCounter };

function compileFunctionExpression(node: ts.FunctionExpression | ts.ArrowFunction, ctx: CompilationContext): string {
    const closureCtx = new CompilationContext(ctx);

    // Register $this if it is a FunctionExpression (not arrow function)
    if (ts.isFunctionExpression(node)) {
        closureCtx.addLocal('$this', 'anyref');
    }

    // Scan parameters to add to locals
    node.parameters.forEach(param => {
        if (ts.isIdentifier(param.name)) {
            closureCtx.addLocal(`$user_${param.name.text}`, 'anyref');
        }
    });

    let bodyCode = '';
    if (ts.isBlock(node.body)) {
        bodyCode = compileBody(node.body, closureCtx);
    } else {
        const exprCode = compileExpression(node.body, closureCtx);
        bodyCode = exprCode;
    }

    const capturedVars = closureCtx.getCapturedVars();

    let envCreationCode = `(call $new_root_shape)`;
    let offset = 0;
    for (const varName of capturedVars) {
        const keyId = getPropertyId(varName);
        envCreationCode = `(call $extend_shape ${envCreationCode} (i32.const ${keyId}) (i32.const ${offset}))`;
        offset++;
    }

    const envLocal = ctx.getTempLocal('(ref null $Object)');
    let envSetupCode = `(local.set ${envLocal} (call $new_object ${envCreationCode} (i32.const ${offset})))\n`;

    offset = 0;
    for (const varName of capturedVars) {
        const lookup = ctx.lookup(varName);
        let valCode = '';
        if (lookup.type === 'local') {
            valCode = `(local.get ${varName})`;
        } else if (lookup.type === 'captured') {
             // Access captured variable from current environment
             // We can respect options here too, but captured vars are internal implementation details mostly.
             // However, get_field_slow vs cached could be relevant.
             // But for captured vars, we know the shape is immutable/fixed for closures? No, closures use $Object.
             // But the environment object shape is constructed right there.
             // The environment object IS an $Object.
             // Is it worth optimizing env access? Probably yes.
             // If options.enableInlineCache is false, we should use slow path.

             const options = ctx.getOptions();
             const keyId = getPropertyId(varName);

             if (options.enableInlineCache !== false) {
                 const cacheGlobal = registerGlobalCallSite();
                 valCode = `(call $get_field_cached (local.get $env) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
             } else {
                 valCode = `(call $get_field_slow (local.get $env) (i32.const ${keyId}))`;
             }

        } else {
             throw new Error(`Captured variable ${varName} not found in scope`);
        }

        envSetupCode += `(call $set_storage (ref.as_non_null (local.get ${envLocal})) (i32.const ${offset}) ${valCode})\n`;
        offset++;
    }

    const funcName = `closure_${closureCounter++}`;

    // Add $this parameter
    let paramsDecl = '(param $env anyref) (param $this anyref)';
    node.parameters.forEach(param => {
         if (ts.isIdentifier(param.name)) {
             paramsDecl += ` (param $user_${param.name.text} anyref)`;
         }
    });

    let localsDecl = '';
    closureCtx.getLocals().forEach((type, name) => {
        const isParam = node.parameters.some(p => ts.isIdentifier(p.name) && `$user_${p.name.text}` === name);
        // Exclude $this from locals (it is a param)
        const isThis = name === '$this';
        if (!isParam && !isThis) {
            localsDecl += `(local ${name} ${type})\n`;
        }
    });

    const funcWat = `
    (func $${funcName} ${paramsDecl} (result anyref)
       ${localsDecl}
       ${bodyCode}
    )`;

    registerGeneratedFunction(funcWat);
    registerGeneratedFunction(`(elem declare func $${funcName})`);

    return `(block (result (ref $Closure))
        ${envSetupCode}
        (struct.new $Closure (ref.func $${funcName}) (ref.as_non_null (local.get ${envLocal})))
    )`;
}

export function compileExpression(expr: ts.Expression, ctx: CompilationContext): string {
  const options = ctx.getOptions();
  const enableIC = options.enableInlineCache !== false;

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
      const bytes = Buffer.from(expr.text, 'utf8');
      const byteStr = Array.from(bytes).map(b => `(i32.const ${b})`).join(' ');
      return `(array.new_fixed $String ${bytes.length} ${byteStr})`;
  } else if (ts.isObjectLiteralExpression(expr)) {
      let shapeCode = `(call $new_root_shape)`;
      let offset = 0;
      for (const prop of expr.properties) {
          if (ts.isPropertyAssignment(prop) && prop.name && ts.isIdentifier(prop.name)) {
              const keyId = getPropertyId(prop.name.text);
              shapeCode = `(call $extend_shape ${shapeCode} (i32.const ${keyId}) (i32.const ${offset}))`;
              offset++;
          }
      }

      const objLocal = ctx.getTempLocal('(ref null $Object)');

      let setPropsCode = '';
      offset = 0;
      for (const prop of expr.properties) {
          if (ts.isPropertyAssignment(prop) && prop.name && ts.isIdentifier(prop.name)) {
              const valCode = compileExpression(prop.initializer, ctx);
              setPropsCode += `(call $set_storage (ref.as_non_null (local.get ${objLocal})) (i32.const ${offset}) ${valCode})\n`;
              offset++;
          }
      }

      return `(block (result (ref $Object))
         (local.set ${objLocal} (call $new_object ${shapeCode} (i32.const ${offset})))
         ${setPropsCode}
         (ref.as_non_null (local.get ${objLocal}))
      )`;

  } else if (ts.isCallExpression(expr)) {
      if (ts.isIdentifier(expr.expression)) {
          const funcName = expr.expression.text;
          const lookup = ctx.lookup(`$user_${funcName}`);

          if (lookup.type === 'local' || lookup.type === 'captured') {
               const closureExpr = compileExpression(expr.expression, ctx);
               const args = expr.arguments.map(arg => compileExpression(arg, ctx));

               const closureLocal = ctx.getTempLocal('(ref null $Closure)');
               const sigName = `$ClosureSig${args.length}`;

               let argsCode = '';
               args.forEach(argCode => {
                   argsCode += argCode + ' ';
               });

               return `(block (result anyref)
                   (local.set ${closureLocal} (ref.cast (ref $Closure) ${closureExpr}))
                   (call_ref ${sigName}
                       (struct.get $Closure $env (ref.as_non_null (local.get ${closureLocal})))
                       (ref.null any) ;; $this for simple function call
                       ${argsCode}
                       (ref.cast (ref ${sigName}) (struct.get $Closure $func (ref.as_non_null (local.get ${closureLocal}))))
                   )
               )`;
          } else {
             return `(call $${funcName} ${expr.arguments.map(a => compileExpression(a, ctx)).join(' ')})`;
          }
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
      } else if (ts.isPropertyAccessExpression(expr.expression) && ts.isIdentifier(expr.expression.name)) {
          // Method call obj.method(...)
          const objExpr = expr.expression.expression;
          const propName = expr.expression.name.text;
          const keyId = getPropertyId(propName);

          const objCode = compileExpression(objExpr, ctx);
          const args = expr.arguments.map(arg => compileExpression(arg, ctx));

          const objLocal = ctx.getTempLocal('anyref');
          const closureLocal = ctx.getTempLocal('(ref null $Closure)');
          const sigName = `$ClosureSig${args.length}`;

          let argsCode = '';
          args.forEach(argCode => {
               argsCode += argCode + ' ';
          });

          // Logic:
          // 1. Evaluate obj -> objLocal
          // 2. Get field propName from objLocal -> closureLocal (cast to closure)
          // 3. Call closure with objLocal as $this

          let getFieldCode = '';
          if (enableIC) {
              const cacheGlobal = registerGlobalCallSite();
              getFieldCode = `(call $get_field_cached (ref.cast (ref $Object) (local.get ${objLocal})) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
          } else {
              getFieldCode = `(call $get_field_slow (ref.cast (ref $Object) (local.get ${objLocal})) (i32.const ${keyId}))`;
          }

          return `(block (result anyref)
              (local.set ${objLocal} ${objCode})
              (local.set ${closureLocal} (ref.cast (ref $Closure) ${getFieldCode}))
              (call_ref ${sigName}
                  (struct.get $Closure $env (ref.as_non_null (local.get ${closureLocal})))
                  (local.get ${objLocal}) ;; pass obj as $this
                  ${argsCode}
                  (ref.cast (ref ${sigName}) (struct.get $Closure $func (ref.as_non_null (local.get ${closureLocal}))))
              )
          )`;
      } else {
          // Indirect call
          const closureExpr = compileExpression(expr.expression, ctx);
          const args = expr.arguments.map(arg => compileExpression(arg, ctx));
          const closureLocal = ctx.getTempLocal('(ref null $Closure)');
          const sigName = `$ClosureSig${args.length}`;

          let argsCode = '';
          args.forEach(argCode => {
               argsCode += argCode + ' ';
          });

          return `(block (result anyref)
              (local.set ${closureLocal} (ref.cast (ref $Closure) ${closureExpr}))
              (call_ref ${sigName}
                   (struct.get $Closure $env (ref.as_non_null (local.get ${closureLocal})))
                   (ref.null any) ;; $this for indirect call
                   ${argsCode}
                   (ref.cast (ref ${sigName}) (struct.get $Closure $func (ref.as_non_null (local.get ${closureLocal}))))
               )
          )`;
      }
  } else if (ts.isBinaryExpression(expr)) {
      if (expr.operatorToken.kind === ts.SyntaxKind.PlusToken) {
          const left = compileExpression(expr.left, ctx);
          const right = compileExpression(expr.right, ctx);
          if (enableIC) {
              const siteName = registerBinaryOpCallSite();
              return `(call $add_cached ${left} ${right} (global.get ${siteName}))`;
          } else {
              return `(call $add_slow ${left} ${right})`;
          }
      } else if (expr.operatorToken.kind === ts.SyntaxKind.MinusToken) {
          const left = compileExpression(expr.left, ctx);
          const right = compileExpression(expr.right, ctx);
          if (enableIC) {
              const siteName = registerBinaryOpCallSite();
              return `(call $sub_cached ${left} ${right} (global.get ${siteName}))`;
          } else {
              return `(call $sub_slow ${left} ${right})`;
          }
      } else if (expr.operatorToken.kind === ts.SyntaxKind.LessThanToken) {
          const left = compileExpression(expr.left, ctx);
          const right = compileExpression(expr.right, ctx);
          return `(call $less_than ${left} ${right})`;
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
                   return `(local.tee ${localName} ${right})`;
              } else {
                   const keyId = getPropertyId(localName);
                   return `(call $put_field (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}) ${right})`;
              }
          } else if (ts.isPropertyAccessExpression(expr.left)) {
              if (ts.isIdentifier(expr.left.name)) {
                  const keyId = getPropertyId(expr.left.name.text);
                  const objCode = compileExpression(expr.left.expression, ctx);
                  const valCode = compileExpression(expr.right, ctx);
                  return `(call $put_field (ref.cast (ref $Object) ${objCode}) (i32.const ${keyId}) ${valCode})`;
              }
          }
      }
  } else if (ts.isPostfixUnaryExpression(expr)) {
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

                  return `(block (result anyref)
                      (local.set ${tempLocal} (local.get ${localName}))
                      (local.set ${localName} ${addCall})
                      (local.get ${tempLocal})
                  )`;
              } else {
                  const tempLocal = ctx.getTempLocal('anyref');
                  const keyId = getPropertyId(localName);
                  // Captured access also needs to respect IC option?
                  // Earlier I implemented env access logic in compileFunctionExpression.
                  // But here it's accessing captured var in PostfixUnary.
                  // Wait, compileExpression for Identifier handles captured access.
                  // But PostfixUnary manually generates get/set.

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

                  return `(block (result anyref)
                       (local.set ${tempLocal} ${envGet})
                       (call $put_field (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}) ${addCall})
                       (drop)
                       (local.get ${tempLocal})
                  )`;
              }
          }
      }
  } else if (ts.isPropertyAccessExpression(expr)) {
      if (ts.isIdentifier(expr.name)) {
          const keyId = getPropertyId(expr.name.text);
          const objCode = compileExpression(expr.expression, ctx);
          if (enableIC) {
              const cacheGlobal = registerGlobalCallSite();
              return `(call $get_field_cached (ref.cast (ref $Object) ${objCode}) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
          } else {
              return `(call $get_field_slow (ref.cast (ref $Object) ${objCode}) (i32.const ${keyId}))`;
          }
      }
  } else if (ts.isIdentifier(expr)) {
      const varName = expr.text;
      const localName = `$user_${varName}`;

      const res = ctx.lookup(localName);

      if (res.type === 'local') {
          return `(local.get ${localName})`;
      } else if (res.type === 'captured') {
          const keyId = getPropertyId(localName);
          if (enableIC) {
              const cacheGlobal = registerGlobalCallSite();
              return `(call $get_field_cached (ref.cast (ref $Object) (local.get $env)) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
          } else {
              return `(call $get_field_slow (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}))`;
          }
      }

      throw new Error(`Unknown identifier: ${varName}`);
  } else if (ts.isArrowFunction(expr) || ts.isFunctionExpression(expr)) {
      return compileFunctionExpression(expr, ctx);
  } else if (expr.kind === ts.SyntaxKind.ThisKeyword) {
      try {
          const res = ctx.lookup('$this');
          if (res.type === 'local') {
              return `(local.get $this)`;
          } else if (res.type === 'captured') {
               // Captured $this (e.g. inside ArrowFunction)
               // Access it from env
               const keyId = getPropertyId('$this');
               if (enableIC) {
                   const cacheGlobal = registerGlobalCallSite();
                   return `(call $get_field_cached (ref.cast (ref $Object) (local.get $env)) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
               } else {
                   return `(call $get_field_slow (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}))`;
               }
          }
      } catch (e) {
          // If not found (e.g. top level or not available), return null (or global object if we had one)
          return `(ref.null any)`;
      }
      return `(ref.null any)`;
  }

  throw new Error(`Unsupported expression kind: ${ts.SyntaxKind[expr.kind]}`);
}
