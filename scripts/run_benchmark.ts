import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { compile } from '../src/compiler.ts';
import { performance } from 'perf_hooks';

// Dynamic import for binaryen
const binaryenPromise = import('binaryen');

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const benchmarkDir = path.join(projectRoot, 'benchmark');

// Helper to check if WebAssembly is supported
const isWasmSupported = typeof WebAssembly !== 'undefined';

interface BenchmarkResult {
    file: string;
    jsDuration: number;
    wasmICDuration: number | string;
    wasmNoICDuration: number | string;
}

async function runBenchmark() {
    const binaryen = (await binaryenPromise).default;
    const files = fs.readdirSync(benchmarkDir);
    const jsFiles = files.filter((f) => f.endsWith('.js'));

    console.log(`Found ${jsFiles.length} JS benchmarks in ${benchmarkDir}:`, jsFiles);

    const results: BenchmarkResult[] = [];

    for (const file of jsFiles) {
        console.log(`\n--- Benchmarking ${file} ---`);
        const filePath = path.join(benchmarkDir, file);
        const jsSource = fs.readFileSync(filePath, 'utf-8');

        let jsDuration = 0;
        // Since we are in ESM, we can import it?
        // But we want to run it fresh.
        // Let's use `child_process` to run node?
        // Or just eval the code?
        // The code has `console.log`.
        // Let's wrap it in a function.
        // Or just run it.
        // For now, let's skip precise JS benchmarking inside this script if it's tricky,
        // but `run_benchmark.ts` output shows "JS Best Duration".

        // Let's try to run it via `node`.
        const { execSync } = await import('child_process');
        try {
            // Run with node
            const start = performance.now();
            execSync(`node ${filePath}`, { stdio: 'ignore' });
            jsDuration = performance.now() - start;
            console.log(`JS Best Duration: ${jsDuration.toFixed(4)} ms`);
        } catch (e) {
            console.error(`JS execution failed: ${e}`);
        }

        // Wasm Compilation
        const compileAndRunWasm = async (enableIC: boolean): Promise<number | string> => {
            if (!isWasmSupported) return 'N/A';

            console.log(`Compiling to WAT (IC: ${enableIC})...`);
            let watText = '';
            try {
                watText = compile(jsSource, { enableInlineCache: enableIC });
            } catch (e) {
                console.error(`Compilation failed for ${file} (IC: ${enableIC}):`, e);
                return 'Error';
            }

            const watPath = path.join(benchmarkDir, `${file.replace('.js', '')}.${enableIC ? 'ic' : 'no_ic'}.wat`);
            fs.writeFileSync(watPath, watText);

            let binary: Uint8Array;
            const module = binaryen.parseText(watText);

            try {
                module.setFeatures(
                    binaryen.Features.GC | binaryen.Features.ReferenceTypes | binaryen.Features.BulkMemory,
                ); // Added BulkMemory

                if (!module.validate()) {
                    console.error(`Validation failed for ${file} (IC: ${enableIC})`);
                    module.dispose();
                    return 'Error';
                }

                // Optimize?
                // module.optimize();

                binary = module.emitBinary();
            } catch (e) {
                console.error(`Binaryen processing failed: ${e}`);
                module.dispose();
                return 'Error';
            } finally {
                module.dispose();
            }

            const wasmPath = path.join(benchmarkDir, `${file.replace('.js', '')}.${enableIC ? 'ic' : 'no_ic'}.wasm`);
            fs.writeFileSync(wasmPath, binary);

            // Execute Wasm
            try {
                const compiled = await WebAssembly.compile(binary as any);
                const imports = {
                    env: {
                        print_i32: () => {},
                        print_f64: () => {},
                        print_char: () => {},
                    },
                };

                const start = performance.now();
                const instance = await WebAssembly.instantiate(compiled, imports);
                const main = instance.exports.main as () => void;
                main();
                const duration = performance.now() - start;
                return duration;
            } catch (e) {
                console.error(`Execution failed for ${file} (IC: ${enableIC}):`, e);
                return 'Error';
            }
        };

        const wasmICDuration = await compileAndRunWasm(true);
        const wasmNoICDuration = await compileAndRunWasm(false);

        results.push({
            file,
            jsDuration,
            wasmICDuration,
            wasmNoICDuration,
        });
    }

    // Update README
    updateReadme(results);
}

function updateReadme(results: BenchmarkResult[]) {
    const readmePath = path.join(projectRoot, 'README.md');
    let content = fs.readFileSync(readmePath, 'utf-8');

    const tableHeader =
        '| Benchmark | JS (ms) | Wasm IC (ms) | Wasm No IC (ms) | Ratio Wasm(IC)/JS | Ratio Wasm(NoIC)/JS |\n|---|---|---|---|---|---|';
    let tableRows = '';

    results.forEach((r) => {
        const ratioIC = typeof r.wasmICDuration === 'number' ? (r.wasmICDuration / r.jsDuration).toFixed(2) : 'N/A';
        const ratioNoIC =
            typeof r.wasmNoICDuration === 'number' ? (r.wasmNoICDuration / r.jsDuration).toFixed(2) : 'N/A';

        const icVal = typeof r.wasmICDuration === 'number' ? r.wasmICDuration.toFixed(4) : r.wasmICDuration;
        const noIcVal = typeof r.wasmNoICDuration === 'number' ? r.wasmNoICDuration.toFixed(4) : r.wasmNoICDuration;

        tableRows += `\n| ${r.file} | ${r.jsDuration.toFixed(4)} | ${icVal} | ${noIcVal} | ${ratioIC} | ${ratioNoIC} |`;
    });

    const newTable = `${tableHeader}${tableRows}`;

    // Regex to replace existing table
    const regex = /# Benchmark Results\n\n[\s\S]*?(?=\n#|$)/;

    if (regex.test(content)) {
        content = content.replace(regex, `# Benchmark Results\n\n${newTable}`);
    } else {
        content += `\n\n# Benchmark Results\n\n${newTable}`;
    }

    fs.writeFileSync(readmePath, content);
    console.log('\nUpdated README.md');
}

runBenchmark().catch((e) => console.error(e));
