import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { spawn } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const excludedFiles = ['run_all.ts', 'debug.ts', 'probe.ts'];

async function runExamples() {
    const files = fs.readdirSync(__dirname);
    const tsFiles = files.filter(f => f.endsWith('.ts') && !excludedFiles.includes(f));

    console.log(`Found ${tsFiles.length} examples:`, tsFiles);

    for (const file of tsFiles) {
        console.log(`\n--- Running ${file} ---`);
        const filePath = path.join(__dirname, file);

        await new Promise<void>((resolve, reject) => {
            const child = spawn('npx', ['ts-node-esm', filePath], {
                stdio: 'inherit',
                shell: true
            });

            child.on('close', (code) => {
                if (code === 0) {
                    console.log(`✓ ${file} passed`);
                    resolve();
                } else {
                    console.error(`✗ ${file} failed with code ${code}`);
                    reject(new Error(`${file} failed`));
                }
            });

            child.on('error', (err) => {
                 console.error(`✗ ${file} error:`, err);
                 reject(err);
            });
        });
    }
    console.log("\nAll examples passed!");
}

runExamples().catch(e => {
    console.error(e);
    process.exit(1);
});
