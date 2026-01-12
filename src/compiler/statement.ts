import ts from 'typescript';
import { compileExpression } from './expression.ts';
import { CompilationContext } from './context.ts';

export function compileStatement(stmt: ts.Statement, ctx: CompilationContext, dropResult: boolean = false): string {
    if (ts.isReturnStatement(stmt) && stmt.expression) {
        return `(return ${compileExpression(stmt.expression, ctx)})`;
    } else if (ts.isExpressionStatement(stmt)) {
        return compileExpression(stmt.expression, ctx, dropResult);
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

        if (dropResult) {
            return code;
        }
        return code + '(ref.null any)';
    } else if (ts.isIfStatement(stmt)) {
        const cond = compileExpression(stmt.expression, ctx);

        const thenBody = ts.isBlock(stmt.thenStatement)
            ? compileBody(stmt.thenStatement, ctx, dropResult)
            : compileStatement(stmt.thenStatement, ctx, dropResult);

        let elseBody = '';
        if (stmt.elseStatement) {
            elseBody = ts.isBlock(stmt.elseStatement)
                ? compileBody(stmt.elseStatement, ctx, dropResult)
                : compileStatement(stmt.elseStatement, ctx, dropResult);
        } else {
             // If no else, and we expect a value, we must return null
             if (!dropResult) {
                 elseBody = '(ref.null any)';
             } else {
                 // if dropResult, else body can be empty
                 elseBody = '(nop)';
             }
        }

        if (dropResult) {
            return `
            (if (i31.get_s (ref.cast (ref i31) ${cond}))
                (then ${thenBody})
                (else ${elseBody})
            )`;
        } else {
            return `
            (if (result anyref) (i31.get_s (ref.cast (ref i31) ${cond}))
                (then ${thenBody})
                (else ${elseBody})
            )`;
        }

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
                // Initializer expression, drop result
                code += compileExpression(stmt.initializer, ctx, true) + '\n';
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
        // We always want to drop the result of the body in a loop (statement context).
        if (ts.isBlock(stmt.statement)) {
             code += compileBody(stmt.statement, ctx, true) + '\n';
        } else {
             code += compileStatement(stmt.statement, ctx, true) + '\n';
        }

        // Incrementor
        if (stmt.incrementor) {
            code += compileExpression(stmt.incrementor, ctx, true) + '\n';
        }

        code += '    (br $continue)\n';
        code += '  )\n'; // End loop
        code += ')\n'; // End block

        if (dropResult) {
            return code;
        }
        return code + '(ref.null any)';
    }
    return '';
}

export function compileBody(body: ts.Block | undefined, ctx: CompilationContext, dropResult: boolean = false): string {
  if (!body) {
      return dropResult ? '' : '(ref.null any)';
  }

  // Filter out empty statements but we can't filter compiled strings directly as we need index
  const statements = body.statements;

  if (statements.length === 0) {
      return dropResult ? '' : '(ref.null any)';
  }

  let code = '';
  for (let i = 0; i < statements.length; i++) {
      const isLast = i === statements.length - 1;
      // If it's the last statement, we respect dropResult.
      // If it's not the last, we always drop (dropResult=true).
      const shouldDrop = isLast ? dropResult : true;

      const stmtCode = compileStatement(statements[i], ctx, shouldDrop);
      if (stmtCode !== '') {
          code += stmtCode + '\n';
      }
  }

  // If code is empty and we expect a value, return null
  if (code === '' && !dropResult) {
      return '(ref.null any)';
  }

  return code;
}
