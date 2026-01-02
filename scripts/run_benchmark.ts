import binaryen from 'binaryen';
import * as fs from 'fs';
import * as path from 'path';
import * as vm from 'vm';
import { fileURLToPath } from 'url';
import { compile } from '../src/compiler.ts';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const benchmarkDir = path.join(projectRoot, 'benchmark');

async function runBenchmark(jsSource: string, file: string, enableIC: boolean): Promise<{ duration: number, output: string }> {
    console.log(`Compiling to WAT (IC: ${enableIC})...`);
    let watText = "";
    try {
        watText = compile(jsSource, { enableInlineCache: enableIC });
    } catch (e) {
         console.error(`Compilation failed for ${file} (IC: ${enableIC}):`, e);
         return { duration: Infinity, output: "" };
    }

    const watPath = path.join(benchmarkDir, `${file.replace('.js', '')}.${enableIC ? 'ic' : 'no_ic'}.wat`);
    fs.writeFileSync(watPath, watText);

    const module = binaryen.parseText(watText);
    module.setFeatures(binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.Strings);

    if (!module.validate()) {
        console.error(`Validation failed for ${file} (IC: ${enableIC})`);
        return { duration: Infinity, output: "" };
    }

    const binary = module.emitBinary();
    module.dispose();

    let wasmDuration = Infinity;
    let wasmOutput = "";

    try {
        const compiled = await WebAssembly.compile(binary as any);

        for (let i = 0; i < 5; i++) {
            let currentOutput = "";
            const imports = {
                env: {
                    print_i32: (val: number) => { currentOutput += val + "\n"; },
                    print_f64: (val: number) => { currentOutput += val + "\n"; },
                    print_string: (val: string) => { currentOutput += val + "\n"; },
                }
            };
            const instance = await WebAssembly.instantiate(compiled, imports);
            const main = (instance.exports.main || instance.exports.test) as () => void;

            if (typeof main !== 'function') {
                console.error(`No main/test export in ${file}`);
                break;
            }

            const start = performance.now();
            main();
            const end = performance.now();
            const duration = end - start;
            // console.log(`Run ${i+1}: ${duration.toFixed(4)} ms`);

            if (duration < wasmDuration) {
                wasmDuration = duration;
                wasmOutput = currentOutput;
            }
        }
    } catch (e) {
        console.error(`Wasm execution failed (IC: ${enableIC}):`, e);
    }
    return { duration: wasmDuration, output: wasmOutput };
}

async function run() {
    if (!fs.existsSync(benchmarkDir)) {
        console.error(`Benchmark directory not found: ${benchmarkDir}`);
        process.exit(1);
    }
    const files = fs.readdirSync(benchmarkDir);
    const jsFiles = files.filter(f => f.endsWith('.js'));

    console.log(`Found ${jsFiles.length} JS benchmarks in ${benchmarkDir}:`, jsFiles);

    let report = "# Benchmark Results\n\n";
    report += "| Benchmark | JS (ms) | Wasm IC (ms) | Wasm No IC (ms) | Ratio Wasm(IC)/JS | Ratio Wasm(NoIC)/JS |\n";
    report += "|---|---|---|---|---|---|\n";

    for (const file of jsFiles) {
        console.log(`\n--- Benchmarking ${file} ---`);
        const filePath = path.join(benchmarkDir, file);
        const jsSource = fs.readFileSync(filePath, 'utf-8');

        // Run Wasm with IC
        const wasmIcResult = await runBenchmark(jsSource, file, true);
        console.log(`Wasm IC Best Duration: ${wasmIcResult.duration.toFixed(4)} ms`);

        // Run Wasm without IC
        const wasmNoIcResult = await runBenchmark(jsSource, file, false);
        console.log(`Wasm No IC Best Duration: ${wasmNoIcResult.duration.toFixed(4)} ms`);

        // Prepare JS Execution
        let jsDuration = Infinity;
        let jsOutput = "";
        try {
            for (let i = 0; i < 5; i++) {
                let currentOutput = "";
                const context = vm.createContext({
                    console: {
                        log: (...args: any[]) => {
                            currentOutput += args.join(' ') + "\n";
                        }
                    }
                });
                const script = new vm.Script(jsSource);
                script.runInContext(context);

                const main = context.main;

                if (typeof main === 'function') {
                    const start = performance.now();
                    main();
                    const end = performance.now();
                    const duration = end - start;
                    // console.log(`JS Run ${i+1}: ${duration.toFixed(4)} ms`);

                    if (duration < jsDuration) {
                        jsDuration = duration;
                        jsOutput = currentOutput;
                    }
                } else {
                    console.log("Could not find main function in JS context.");
                    break;
                }
            }
            console.log(`JS Best Duration: ${jsDuration.toFixed(4)} ms`);

        } catch (e) {
            console.error(`JS execution failed:`, e);
        }

        const jsTime = jsDuration !== Infinity ? jsDuration.toFixed(4) : "N/A";
        const wasmIcTime = wasmIcResult.duration !== Infinity ? wasmIcResult.duration.toFixed(4) : "N/A";
        const wasmNoIcTime = wasmNoIcResult.duration !== Infinity ? wasmNoIcResult.duration.toFixed(4) : "N/A";

        const ratioIc = (wasmIcResult.duration !== Infinity && jsDuration !== Infinity)
            ? (wasmIcResult.duration / jsDuration).toFixed(2)
            : "N/A";

        const ratioNoIc = (wasmNoIcResult.duration !== Infinity && jsDuration !== Infinity)
            ? (wasmNoIcResult.duration / jsDuration).toFixed(2)
            : "N/A";

        report += `| ${file} | ${jsTime} | ${wasmIcTime} | ${wasmNoIcTime} | ${ratioIc} | ${ratioNoIc} |\n`;
    }

    console.log("\n" + report);

    // Append to README
    const readmePath = path.join(projectRoot, 'README.md');
    let readme = fs.readFileSync(readmePath, 'utf-8');

    const benchHeader = "## Benchmark Results";

    // Remove old benchmark output if it exists
    if (readme.includes(benchHeader)) {
        const startIndex = readme.indexOf(benchHeader);
        let endIndex = readme.indexOf("\n## ", startIndex + benchHeader.length);
        if (endIndex === -1) endIndex = readme.length;

        // Remove the old section entirely
        readme = readme.substring(0, startIndex) + readme.substring(endIndex);
    }

    // Trim trailing newlines to keep it clean
    readme = readme.trimEnd();

    // Append new report
    readme += "\n\n" + benchHeader + "\n\n" + report.replace("# Benchmark Results\n\n", "");

    fs.writeFileSync(readmePath, readme);
    console.log("Updated README.md");
}

run().catch(e => {
    console.error(e);
    process.exit(1);
});
