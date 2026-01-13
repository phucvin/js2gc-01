import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { compile, type CompilerOptions } from '../src/compiler/index.ts';

// Dynamic import helper
export async function getBinaryen() {
    return binaryen;
}

export function findFiles(dir: string, ext: string): string[] {
    if (!fs.existsSync(dir)) return [];
    const files = fs.readdirSync(dir);
    return files.filter(f => f.endsWith(ext));
}

export function compileToWat(source: string, options?: CompilerOptions): string {
    return compile(source, options);
}

export async function createWasmModule(watText: string): Promise<{ binary: Uint8Array, module: binaryen.Module }> {
    const module = binaryen.parseText(watText);
    module.setFeatures(
        binaryen.Features.GC |
        binaryen.Features.ReferenceTypes |
        binaryen.Features.BulkMemory
    );

    if (!module.validate()) {
        module.dispose();
        throw new Error('Validation failed');
    }

    const binary = module.emitBinary();
    // We don't dispose here, caller might want to use module.
    // Actually, caller should dispose.
    // But to match previous logic, we return both.
    return { binary, module };
}

export async function runWasm(binary: Uint8Array, imports: any = {}): Promise<WebAssembly.Instance> {
    const compiled = await WebAssembly.compile(binary as any);
    return await WebAssembly.instantiate(compiled, imports);
}

export function getPrintImports(outputCallback: (str: string) => void) {
    return {
        env: {
            print_i32: (val: number) => outputCallback(val + "\n"),
            print_f64: (val: number) => outputCallback(val + "\n"),
            print_char: (val: number) => outputCallback(String.fromCharCode(val)),
        }
    };
}
