import ts from 'typescript';
import { getPropertyId, CompilationContext, registerGlobalCallSite, registerGeneratedFunction, registerBinaryOpCallSite, registerStringLiteral, registerShape } from './context.ts';
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
    const totalCaptured = capturedVars.length;

    const envShapeGlobal = registerShape(capturedVars);
    const envCreationCode = `(global.get ${envShapeGlobal})`;

    const funcName = `closure_${closureCounter++}`;

    const envLocal = ctx.getTempLocal('(ref null $Object)');
    let envSetupCode = '';

    let offset = 0;
    for (const varName of capturedVars) {
        const lookup = ctx.lookup(varName);
        let valCode = '';
        if (lookup.type === 'local') {
            valCode = `(local.get ${varName})`;
        } else if (lookup.type === 'captured') {
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

        let envAccess;
        if (offset === 0) {
             // We must use ref.as_non_null because local.tee returns the type of the local (nullable).
             envAccess = `(ref.as_non_null (local.tee ${envLocal} (call $new_object ${envCreationCode} (i32.const ${totalCaptured}))))`;
        } else {
             envAccess = `(ref.as_non_null (local.get ${envLocal}))`;
        }

        envSetupCode += `(call $set_storage ${envAccess} (i32.const ${offset}) ${valCode})\n`;
        offset++;
    }

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

    if (totalCaptured === 0) {
        return `(struct.new $Closure (ref.func $${funcName}) (call $new_object ${envCreationCode} (i32.const 0)))`;
    }

    return `(block (result (ref $Closure))
        ${envSetupCode}
        (struct.new $Closure (ref.func $${funcName}) (local.get ${envLocal}))
    )`;
}

export function compileExpression(expr: ts.Expression, ctx: CompilationContext, dropResult: boolean = false): string {
    // Handle console.log specifically to support void return
    if (ts.isCallExpression(expr) &&
        ts.isPropertyAccessExpression(expr.expression) &&
        ts.isIdentifier(expr.expression.expression) &&
        expr.expression.expression.text === 'console' &&
        expr.expression.name.text === 'log') {

        if (expr.arguments.length > 0) {
            const arg = compileExpression(expr.arguments[0], ctx);
            const callCode = `(call $console_log ${arg})`;
            if (dropResult) return callCode;
            return `(block (result anyref) ${callCode} (ref.null any))`;
        } else {
            if (dropResult) return `(nop)`;
            return `(ref.null any)`;
        }
    }

    const code = compileExpressionValue(expr, ctx, dropResult);
    return code;
}

function compileExpressionValue(expr: ts.Expression, ctx: CompilationContext, dropResult: boolean): string {
  const options = ctx.getOptions();
  const enableIC = options.enableInlineCache !== false;

  // For expressions that don't support optimized dropResult handling, we fall back to manual drop.
  // Helper to handle fallback
  const fallback = (code: string) => dropResult ? `(drop ${code})` : code;
  // Fallback for side-effect free expressions
  const fallbackPure = (code: string) => dropResult ? `(nop)` : code;

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

  } else if (ts.isCallExpression(expr)) {
      // Direct console.log is handled in compileExpression wrapper.
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
             const code = `(call $${funcName} ${expr.arguments.map(a => compileExpression(a, ctx)).join(' ')})`;
             return fallback(code);
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
          const args = expr.arguments.map(arg => compileExpression(arg, ctx));
          const closureLocal = ctx.getTempLocal('(ref null $Closure)');
          const sigName = `$ClosureSig${args.length}`;

          let argsCode = '';
          args.forEach(argCode => {
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
  } else if (ts.isBinaryExpression(expr)) {
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

                  // Removed drop after put_field call since put_field is now void
                  const code = `(block (result anyref)
                       (local.set ${tempLocal} ${envGet})
                       (call $put_field (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}) ${addCall})
                       (local.get ${tempLocal})
                  )`;
                  return fallback(code);
              }
          }
      }
  } else if (ts.isPropertyAccessExpression(expr)) {
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
  } else if (ts.isIdentifier(expr)) {
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
  } else if (ts.isArrowFunction(expr) || ts.isFunctionExpression(expr)) {
      const code = compileFunctionExpression(expr, ctx);
      return fallbackPure(code); // Function creation is technically pure-ish if not assigned?
      // Wait, it creates a closure object on heap. That has side effects (allocation).
      // But if we drop it, we don't care. It's not observable.
      // So fallbackPure is okay.
  } else if (expr.kind === ts.SyntaxKind.ThisKeyword) {
      try {
          const res = ctx.lookup('$this');
          if (res.type === 'local') {
              return fallbackPure(`(local.get $this)`);
          } else if (res.type === 'captured') {
               const keyId = getPropertyId('$this');
               let code;
               if (enableIC) {
                   const cacheGlobal = registerGlobalCallSite();
                   code = `(call $get_field_cached (ref.cast (ref $Object) (local.get $env)) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
               } else {
                   code = `(call $get_field_slow (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}))`;
               }
               return fallback(code);
          }
      } catch (e) {
          return fallbackPure(`(ref.null any)`);
      }
      return fallbackPure(`(ref.null any)`);
  }

  throw new Error(`Unsupported expression kind: ${ts.SyntaxKind[expr.kind]}`);
}
