import ts from 'typescript';
import { compileBody } from './statement.ts';
import { CompilationContext } from './context.ts';

export function compileFunction(func: ts.FunctionDeclaration): string {
    const name = func.name!.text;
    const isMain = name === 'main';
    const isTest = name === 'test';
    let exportClause = '';
    if (isMain) exportClause = '(export "main")';
    if (isTest) exportClause = '(export "test")';

    const ctx = new CompilationContext();

    // Compile body
    const body = compileBody(func.body, ctx);

    // Generate locals declaration
    let localsDecl = '';
    ctx.getLocals().forEach((type, name) => {
        localsDecl += `(local ${name} ${type})\n`;
    });

    return `
  (func $${name} ${exportClause} (result anyref)
    ${localsDecl}
    ${body}
  )`;
}
