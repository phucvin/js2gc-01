import * as esbuild from 'esbuild';

await esbuild.build({
  entryPoints: ['scripts/run_benchmark.ts'],
  bundle: true,
  platform: 'node',
  format: 'esm',
  outfile: 'bench_runner.js',
  packages: 'external', // Mark all npm packages as external to keep bundle small and rely on node_modules
  logLevel: 'info',
});
