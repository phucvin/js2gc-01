import ts from 'typescript';
import { CompilationContext, registerStringLiteral } from '../context.ts';

export function compileLiteralExpression(
  expr: ts.Expression,
  ctx: CompilationContext,
  dropResult: boolean,
): string | null {
  // Helper to handle fallback
  const fallbackPure = (code: string) => (dropResult ? `(nop)` : code);

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
  }

  return null;
}
