import ts from 'typescript';
import { compileBody } from './statement.ts';
import { CompilationContext, type CompilerOptions } from './context.ts';

export function compileFunction(func: ts.FunctionDeclaration, options?: CompilerOptions): string {
    const name = func.name!.text;
    const isMain = name === 'main';
    const isTest = name === 'test';
    let exportClause = '';
    if (isMain) exportClause = '(export "main")';
    if (isTest) exportClause = '(export "test")';

    const ctx = new CompilationContext(options);

    // Scan parameters to add to locals
    func.parameters.forEach(param => {
        if (ts.isIdentifier(param.name)) {
            ctx.addLocal(`$user_${param.name.text}`, 'anyref');
        }
    });

    // Compile body
    const body = compileBody(func.body, ctx);

    // Generate locals declaration (exclude parameters)
    let localsDecl = '';
    ctx.getLocals().forEach((type, name) => {
        const isParam = func.parameters.some(p => ts.isIdentifier(p.name) && `$user_${p.name.text}` === name);
        if (!isParam) {
            localsDecl += `(local ${name} ${type})\n`;
        }
    });

    // Generate params declaration
    let paramsDecl = '';
    func.parameters.forEach(param => {
         if (ts.isIdentifier(param.name)) {
             paramsDecl += ` (param $user_${param.name.text} anyref)`;
         }
    });

    return `
  (func $${name} ${exportClause} ${paramsDecl} (result anyref)
    ${localsDecl}
    ${body}
  )`;
}
