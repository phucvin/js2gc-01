import * as fs from 'fs';
import * as path from 'path';

export const isWasmSupported = typeof WebAssembly !== 'undefined';

export function findFiles(dir: string, ext: string): string[] {
    if (!fs.existsSync(dir)) return [];
    const files = fs.readdirSync(dir);
    return files.filter((f) => f.endsWith(ext));
}

export function compileToWasm(
    watText: string,
    binaryen: any,
    features: number = binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory,
): Uint8Array {
    const module = binaryen.parseText(watText);
    try {
        module.setFeatures(features);
        if (!module.validate()) {
            throw new Error('WASM validation failed');
        }
        return module.emitBinary();
    } finally {
        module.dispose();
    }
}

export async function runWasm(binary: Uint8Array, imports: any = {}): Promise<WebAssembly.Instance> {
    const compiled = await WebAssembly.compile(binary as any);
    return await WebAssembly.instantiate(compiled, imports);
}
