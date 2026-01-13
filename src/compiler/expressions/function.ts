import ts from 'typescript';
import {
    getPropertyId,
    CompilationContext,
    registerGlobalCallSite,
    registerGeneratedFunction,
    registerShape,
} from '../context.ts';
import { compileBody } from '../statement.ts';
import { compileExpression } from '../expression.ts';

let closureCounter = 0;

export function resetClosureCounter() {
    closureCounter = 0;
}

export function compileFunctionExpression(node: ts.FunctionExpression | ts.ArrowFunction, ctx: CompilationContext): string {
    const closureCtx = new CompilationContext(ctx);

    // Register $this if it is a FunctionExpression (not arrow function)
    if (ts.isFunctionExpression(node)) {
        closureCtx.addLocal('$this', 'anyref');
    }

    // Scan parameters to add to locals
    node.parameters.forEach((param) => {
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
                valCode = `(call $get_field_cached (ref.cast (ref $Object) (local.get $env)) (global.get ${cacheGlobal}) (i32.const ${keyId}))`;
            } else {
                valCode = `(call $get_field_slow (ref.cast (ref $Object) (local.get $env)) (i32.const ${keyId}))`;
            }
        } else {
            throw new Error(`Captured variable ${varName} not found in scope`);
        }

        let envAccess;
        if (offset === 0) {
            envAccess = `(ref.as_non_null (local.tee ${envLocal} (call $new_object ${envCreationCode} (i32.const ${totalCaptured}))))`;
        } else {
            envAccess = `(ref.as_non_null (local.get ${envLocal}))`;
        }

        envSetupCode += `(call $set_storage ${envAccess} (i32.const ${offset}) ${valCode})\n`;
        offset++;
    }

    // Add $this parameter
    let paramsDecl = '(param $env anyref) (param $this anyref)';
    node.parameters.forEach((param) => {
        if (ts.isIdentifier(param.name)) {
            paramsDecl += ` (param $user_${param.name.text} anyref)`;
        }
    });

    let localsDecl = '';
    closureCtx.getLocals().forEach((type, name) => {
        const isParam = node.parameters.some((p) => ts.isIdentifier(p.name) && `$user_${p.name.text}` === name);
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
