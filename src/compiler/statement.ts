import ts from 'typescript';
import { compileExpression } from './expression.ts';
import { CompilationContext } from './context.ts';

export function compileStatement(stmt: ts.Statement, ctx: CompilationContext): string {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        return `(return ${compileExpression(stmt.expression, ctx)})`;
    } else if (ts.isExpressionStatement(stmt)) {
        return compileExpression(stmt.expression, ctx);
    } else if (ts.isVariableStatement(stmt)) {
        let code = '';
        for (const decl of stmt.declarationList.declarations) {
            if (ts.isIdentifier(decl.name)) {
                const varName = decl.name.text;
                const localName = `$user_${varName}`;
                ctx.addLocal(localName, 'anyref');

                if (decl.initializer) {
                    const initVal = compileExpression(decl.initializer, ctx);
                    code += `(local.set ${localName} ${initVal})\n`;
                } else {
                    code += `(local.set ${localName} (ref.null any))\n`;
                }
            }
        }
        // Statements in compileBody are expected to leave a value to be dropped or be void.
        // However, VariableStatement in JS is void.
        // But our compileBody loop adds (drop) after every statement except the last one.
        // If we return (local.set ...), it consumes the value.
        // So we should append (ref.null any) so the loop can drop it.
        return code + '(ref.null any)';
    } else if (ts.isIfStatement(stmt)) {
        const cond = compileExpression(stmt.expression, ctx);
        const thenBody = ts.isBlock(stmt.thenStatement)
            ? compileBody(stmt.thenStatement, ctx)
            : compileStatement(stmt.thenStatement, ctx);

        let elseBody = '(ref.null any)';
        if (stmt.elseStatement) {
            elseBody = ts.isBlock(stmt.elseStatement)
                ? compileBody(stmt.elseStatement, ctx)
                : compileStatement(stmt.elseStatement, ctx);
        }

        // We assume condition returns an i31ref (boolean).
        // If returns value, then/else branches must match.
        // Since we are in a statement context, usually we drop the result, but compileBody returns the last value.
        // If this IfStatement is the last statement in a function, it should return a value.
        // Wasm `if` returns a value if declared.
        // We will declare it to return `anyref` to be safe and compatible with our function signature.

        return `
        (if (result anyref) (i31.get_s (ref.cast (ref i31) ${cond}))
            (then ${thenBody})
            (else ${elseBody})
        )`;

    } else if (ts.isForStatement(stmt)) {
        // for (initializer; condition; incrementor) statement
        // (block $break
        //   initializer
        //   (loop $continue
        //     (br_if $break (i32.eqz (condition)))
        //     statement
        //     incrementor
        //     (br $continue)
        //   )
        // )

        let code = '';

        // Initializer
        if (stmt.initializer) {
            if (ts.isVariableDeclarationList(stmt.initializer)) {
                 // Reuse VariableStatement logic, but we need to handle it carefully.
                 // compileStatement expects a Statement. VariableDeclarationList is not a Statement.
                 // But VariableStatement contains VariableDeclarationList.
                 // We can synthesize a VariableStatement or just iterate declarations.
                 for (const decl of stmt.initializer.declarations) {
                    if (ts.isIdentifier(decl.name)) {
                        const varName = decl.name.text;
                        const localName = `$user_${varName}`;
                        ctx.addLocal(localName, 'anyref');
                        if (decl.initializer) {
                            const initVal = compileExpression(decl.initializer, ctx);
                            code += `(local.set ${localName} ${initVal})\n`;
                        } else {
                            code += `(local.set ${localName} (ref.null any))\n`;
                        }
                    }
                 }
            } else {
                code += compileExpression(stmt.initializer, ctx) + '\n(drop)\n';
            }
        }

        code += '(block $break\n';
        code += '  (loop $continue\n';

        // Condition
        if (stmt.condition) {
            const cond = compileExpression(stmt.condition, ctx);
            // Assumes cond returns an anyref that is an i31 (boolean-like)
            // We need to unbox it to i32 for br_if
            // If it's not i31, we treat it as true (skip break) unless it's null?
            // For now, assume strict i31 boolean from $less_than
            code += `    (br_if $break (i32.eqz (i31.get_s (ref.cast (ref i31) ${cond}))))\n`;
        }

        // Body
        // Statement can be Block or single statement.
        // If it's a block, compileBody handles it (returns sequence of instructions).
        // If it's a single statement, compileStatement handles it.
        // But compileStatement returns a string that might produce a value (ExpressionStatement).
        // We need to drop the value if it produces one.
        if (ts.isBlock(stmt.statement)) {
            // compileBody adds drops internally, but returns result of last statement.
            // We need to drop the result of the block.
             code += compileBody(stmt.statement, ctx) + '\n(drop)\n';
        } else {
             code += compileStatement(stmt.statement, ctx) + '\n(drop)\n';
        }

        // Incrementor
        if (stmt.incrementor) {
            code += compileExpression(stmt.incrementor, ctx) + '\n(drop)\n';
        }

        code += '    (br $continue)\n';
        code += '  )\n'; // End loop
        code += ')\n'; // End block

        // Loop statement itself doesn't return a value in JS (void), so we return (ref.null any)
        return code + '(ref.null any)';
    }
    return '';
}

export function compileBody(body: ts.Block | undefined, ctx: CompilationContext): string {
  if (!body) return '(ref.null any)';

  const statements = body.statements.map(stmt => compileStatement(stmt, ctx)).filter(s => s !== '');
  if (statements.length === 0) return '(ref.null any)';

  let code = '';
  for (let i = 0; i < statements.length - 1; i++) {
      code += statements[i] + '\n(drop)\n';
  }
  code += statements[statements.length - 1];

  return code;
}
