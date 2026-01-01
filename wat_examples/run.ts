import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function run() {
    const files = fs.readdirSync(__dirname);
    const watFiles = files.filter(f => f.endsWith('.wat'));

    console.log(`Found ${watFiles.length} WAT examples:`, watFiles);

    for (const file of watFiles) {
        console.log(`\n--- Processing ${file} ---`);
        const filePath = path.join(__dirname, file);
        const watText = fs.readFileSync(filePath, 'utf-8');

        console.log("Parsing...");
        const module = binaryen.parseText(watText);

        console.log("Setting features (GC | ReferenceTypes | Strings)...");
        module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.Strings);

        if (!module.validate()) {
            console.error(`Validation failed for ${file}`);
            process.exit(1);
        }

        console.log("Optimizing...");
        module.optimize();

        const optimizedWat = module.emitText();
        const optimizedPath = path.join(__dirname, `${file}.optimized`);
        fs.writeFileSync(optimizedPath, optimizedWat);
        console.log(`Optimized WAT written to ${optimizedPath}`);

        const binary = module.emitBinary();

        try {
            const compiled = await WebAssembly.compile(binary);
            const instance = await WebAssembly.instantiate(compiled, {});

            const main = instance.exports.main as () => number;
            if (typeof main !== 'function') {
                console.error(`Example ${file} does not export a 'main' function.`);
                continue;
            }

            const result = main();
            console.log(`Execution result: ${result}`);

            const outPath = path.join(__dirname, `${file}.out`);
            fs.writeFileSync(outPath, result.toString());
            console.log(`Output written to ${outPath}`);

        } catch (e) {
            console.error(`Execution failed for ${file}:`, e);
            process.exit(1);
        } finally {
            module.dispose();
        }
    }
    console.log("\nAll examples processed successfully!");
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
