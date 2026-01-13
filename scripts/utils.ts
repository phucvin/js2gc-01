import * as fs from 'fs';
import binaryen from 'binaryen';

export function findFiles(dir: string, ext: string, exclude: string[] = []): string[] {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter((f) => f.endsWith(ext) && !exclude.includes(f));
}

export interface ProcessingOptions {
  features?: number;
  optimize?: boolean;
}

export function processWat(
  watText: string,
  options: ProcessingOptions = {},
): { binary: Uint8Array; optimizedWat?: string } {
  const module = binaryen.parseText(watText);
  try {
    const features =
      options.features ??
      binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory;
    module.setFeatures(features);

    if (!module.validate()) {
      throw new Error('Validation failed');
    }

    let optimizedWat: string | undefined;
    if (options.optimize) {
      module.optimize();
      optimizedWat = module.emitText();
    }

    const binary = module.emitBinary();
    return { binary, optimizedWat };
  } finally {
    module.dispose();
  }
}

export async function runWasm(
  binary: Uint8Array,
  imports: WebAssembly.Imports,
): Promise<WebAssembly.Instance> {
  const compiled = await WebAssembly.compile(binary as any);
  return await WebAssembly.instantiate(compiled, imports);
}
