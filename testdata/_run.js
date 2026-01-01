import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { compile } from '../src/compiler.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '../../');
// We need to find where testdata is. If __dirname is /app/testdata, projectRoot is /app?
// Let's rely on finding testdata relative to this script.
const testDataDir = __dirname;

async function run() {
    const files = fs.readdirSync(testDataDir);
    // Exclude run.ts and run.js
    const jsFiles = files.filter(f => f.endsWith('.js') && f !== '_run.js' && f !== 'run.ts');

    console.log(`Found ${jsFiles.length} JS examples in ${testDataDir}:`, jsFiles);

    for (const file of jsFiles) {
        console.log(`\n--- Processing ${file} ---`);
        const filePath = path.join(testDataDir, file);
        const jsSource = fs.readFileSync(filePath, 'utf-8');

        console.log("Compiling to WAT...");
        let watText = "";
        try {
            watText = compile(jsSource);
        } catch (e) {
             console.error(`Compilation failed for ${file}:`, e);
             process.exit(1);
        }

        const watPath = path.join(testDataDir, `${file.replace('.js', '.wat')}`);
        fs.writeFileSync(watPath, watText);
        console.log(`WAT written to ${watPath}`);

        console.log("Parsing WAT with Binaryen...");
        const module = binaryen.parseText(watText);

        console.log("Setting features (GC | ReferenceTypes | Strings)...");
        module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.Strings);

        if (!module.validate()) {
            console.error(`Validation failed for ${file}`);
            process.exit(1);
        }

        const binary = module.emitBinary();
        module.dispose();

        try {
            const compiled = await WebAssembly.compile(binary);

            let output = "";
            const imports = {
                env: {
                    print_i32: (val) => { output += val + "\n"; },
                    print_f64: (val) => { output += val + "\n"; },
                    print_string: (val) => { output += val + "\n"; },
                }
            };

            const instance = await WebAssembly.instantiate(compiled, imports);

            const test = instance.exports.test;
            if (typeof test !== 'function') {
                console.error(`Example ${file} does not export a 'test' function.`);
                continue;
            }

            test();

            // Trim trailing newline if needed, or keep it. JS console.log adds newline.
            // My print helpers add newline in this variable accumulation.
            // Let's remove the last newline to match typical file output expectations if convenient,
            // but usually `*.out` files have a trailing newline.

            console.log(`Execution output:\n${output}`);

            const outPath = path.join(testDataDir, `${file.replace('.js', '.out')}`);
            fs.writeFileSync(outPath, output);
            console.log(`Output written to ${outPath}`);

        } catch (e) {
            console.error(`Execution failed for ${file}:`, e);
            process.exit(1);
        }
    }
    console.log("\nAll examples processed successfully!");
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
