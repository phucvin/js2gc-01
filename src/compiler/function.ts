import ts from 'typescript';
import { compileBody } from './statement.ts';

export function compileFunction(func: ts.FunctionDeclaration): string {
    const name = func.name!.text;
    const isMain = name === 'main';
    const isTest = name === 'test';
    let exportClause = '';
    if (isMain) exportClause = '(export "main")';
    if (isTest) exportClause = '(export "test")';

    // Compile body
    const body = compileBody(func.body);

    return `
  (func $${name} ${exportClause} (result anyref)
    ${body}
  )`;
}
