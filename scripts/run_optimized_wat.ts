import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const testdataDir = path.join(projectRoot, 'testdata');

// Add console.log helper for Wasm execution
const imports = {
  env: {
    print_i32: (value: number) => process.stdout.write(value.toString() + '\n'),
    print_f64: (value: number) => process.stdout.write(value.toString() + '\n'),
    print_char: (value: number) => process.stdout.write(String.fromCharCode(value)),
  }
};

async function run() {
    const files = fs.readdirSync(testdataDir);
    const optimizedWatFiles = files.filter(f => f.endsWith('.optimized.wat'));

    console.log(`Found ${optimizedWatFiles.length} optimized WAT files in ${testdataDir}:`, optimizedWatFiles);

    let failed = false;

    for (const file of optimizedWatFiles) {
        console.log(`\n--- Processing ${file} ---`);
        const filePath = path.join(testdataDir, file);
        const originalFilePrefix = file.replace('.optimized.wat', '');
        const expectedOutPath = path.join(testdataDir, `${originalFilePrefix}.out`);

        let module;
        try {
            const watText = fs.readFileSync(filePath, 'utf-8');
            let expectedOutput = '';
            if (fs.existsSync(expectedOutPath)) {
                expectedOutput = fs.readFileSync(expectedOutPath, 'utf-8').trim();
            } else {
                console.warn(`No .out file found for ${originalFilePrefix}, skipping verification.`);
            }

            console.log("Parsing...");
            module = binaryen.parseText(watText);

            console.log("Setting features (GC | ReferenceTypes)...");
            module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes);

            if (!module.validate()) {
                console.error(`Validation failed for ${file}`);
                failed = true;
                continue;
            }

            const binary = module.emitBinary();

            try {
                // Capture stdout
                let actualOutput = '';
                const originalWrite = process.stdout.write;
                process.stdout.write = (chunk: string | Uint8Array, encoding?: any, cb?: any) => {
                    actualOutput += chunk.toString();
                    return true;
                };

                const compiled = await WebAssembly.compile(binary as any);
                const instance = await WebAssembly.instantiate(compiled, imports);

                const main = instance.exports.main as () => any;
                if (typeof main === 'function') {
                    const res = main();
                    // Some mains might return something, others just print.
                    // The .out file captures stdout + result if any.
                    // But our .out files usually just capture what's printed?
                    // Let's check the testdata run script.
                }

                // Restore stdout
                process.stdout.write = originalWrite;

                actualOutput = actualOutput.trim();

                console.log(`Actual output: "${actualOutput}"`);
                console.log(`Expected output: "${expectedOutput}"`);

                if (actualOutput === expectedOutput) {
                    console.log(`[PASS] ${file}`);
                } else {
                    console.error(`[FAIL] ${file} - Output mismatch`);
                    failed = true;
                }

            } catch (e) {
                console.error(`Execution failed for ${file}:`, e);
                failed = true;
            }
        } catch (e) {
            console.error(`Processing failed for ${file}:`, e);
            failed = true;
        } finally {
            if (module) module.dispose();
        }
    }

    if (failed) {
        console.error("\nSome tests failed.");
        process.exit(1);
    } else {
        console.log("\nAll optimized files verified successfully!");
    }
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
