import os
import time
import glob
import sys
from wasmtime import Engine, Store, Module, Linker, Config, WasmtimeError, FuncType, ValType

def run_benchmark_file(engine, file_path):
    store = Store(engine)
    linker = Linker(engine)

    # Define imports expected by the compiler runtime
    linker.define_func("env", "print_i32", FuncType([ValType.i32()], []), lambda v: None)
    linker.define_func("env", "print_f64", FuncType([ValType.f64()], []), lambda v: None)

    try:
        module = Module.from_file(engine, file_path)
    except WasmtimeError as e:
        return None, f"Compilation failed: {e}"

    # Check if print_string is needed
    for imp in module.imports:
        if imp.module == "env" and imp.name == "print_string":
            try:
                 # Attempt to define generic print_string accepting anyref?
                 # If run_benchmark.ts uses stringref, we need stringref type or anyref.
                 # Assuming anyref for safety if python binding doesn't expose stringref valtype easily.
                 # ValType.anyref() is missing in this version, using externref as fallback.
                 linker.define_func("env", "print_string", FuncType([ValType.externref()], []), lambda v: None)
            except Exception:
                 pass
            break

    try:
        instance = linker.instantiate(store, module)
    except WasmtimeError as e:
         return None, f"Instantiation failed: {e}"

    main = instance.exports(store).get("main")
    if not main:
        main = instance.exports(store).get("test")
    if not main:
         return None, "No main export"

    best_time = float('inf')
    # Run 5 times
    for _ in range(5):
        start = time.perf_counter()
        try:
            main(store)
        except WasmtimeError as e:
            return None, f"Execution error: {e}"
        end = time.perf_counter()
        duration = (end - start) * 1000.0
        if duration < best_time:
            best_time = duration

    return best_time, None

def main():
    # Setup Engine
    config = Config()

    # Enable Reference Types (available as property)
    try:
        config.wasm_reference_types = True
    except AttributeError:
        pass

    # Enable Function References
    try:
        config.wasm_function_references = True
    except AttributeError:
        try:
            from wasmtime._bindings import wasmtime_config_wasm_function_references_set
            wasmtime_config_wasm_function_references_set(config.ptr(), True)
        except Exception as e:
            print(f"Warning: Failed to enable Function References: {e}")

    # Enable GC
    try:
        config.wasm_gc = True
    except AttributeError:
        try:
            from wasmtime._bindings import wasmtime_config_wasm_gc_set
            wasmtime_config_wasm_gc_set(config.ptr(), True)
        except Exception as e:
            print(f"Warning: Failed to enable GC: {e}")

    engine = Engine(config)

    # Locate benchmark directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    benchmark_dir = os.path.join(script_dir, "..", "benchmark")

    if not os.path.exists(benchmark_dir):
        print(f"Benchmark directory not found: {benchmark_dir}")
        sys.exit(1)

    js_files = [f for f in os.listdir(benchmark_dir) if f.endswith('.js')]
    js_files.sort()

    print(f"Found benchmarks: {js_files}")
    print("\nRunning benchmarks with Wasmtime...")

    results = {}

    for js_file in js_files:
        base_name = js_file
        results[base_name] = {}

        name_no_ext = js_file[:-3]
        ic_wasm = os.path.join(benchmark_dir, f"{name_no_ext}.ic.wasm")
        no_ic_wasm = os.path.join(benchmark_dir, f"{name_no_ext}.no_ic.wasm")

        if os.path.exists(ic_wasm):
            print(f"Running {js_file} (IC)...")
            duration, err = run_benchmark_file(engine, ic_wasm)
            if err:
                print(f"  Error: {err}")
                results[base_name]['ic'] = "Error"
            else:
                print(f"  Duration: {duration:.4f} ms")
                results[base_name]['ic'] = duration
        else:
            results[base_name]['ic'] = "N/A"

        if os.path.exists(no_ic_wasm):
            print(f"Running {js_file} (No IC)...")
            duration, err = run_benchmark_file(engine, no_ic_wasm)
            if err:
                print(f"  Error: {err}")
                results[base_name]['no_ic'] = "Error"
            else:
                print(f"  Duration: {duration:.4f} ms")
                results[base_name]['no_ic'] = duration
        else:
            results[base_name]['no_ic'] = "N/A"

    # Update README
    update_readme(results)

def update_readme(results):
    readme_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "README.md")

    new_section = "\n\n## Wasmtime Benchmark Results\n\n"
    new_section += "| Benchmark | Wasmtime IC (ms) | Wasmtime No IC (ms) |\n"
    new_section += "|---|---|---|\n"

    for name in sorted(results.keys()):
        data = results[name]
        ic = f"{data.get('ic', 'N/A'):.4f}" if isinstance(data.get('ic'), float) else data.get('ic', 'N/A')
        no_ic = f"{data.get('no_ic', 'N/A'):.4f}" if isinstance(data.get('no_ic'), float) else data.get('no_ic', 'N/A')
        new_section += f"| {name} | {ic} | {no_ic} |\n"

    if os.path.exists(readme_path):
        with open(readme_path, 'r') as f:
            content = f.read()

        header = "## Wasmtime Benchmark Results"
        if header in content:
            start = content.find(header)
            end = content.find("\n## ", start + len(header))
            if end == -1:
                end = len(content)
            # Replace in place
            content = content[:start] + new_section.strip() + "\n\n" + content[end:].lstrip()
        else:
            # Append if not found
            content = content.strip() + new_section

        with open(readme_path, 'w') as f:
            f.write(content)
        print("\nUpdated README.md")
    else:
        print("README.md not found.")

if __name__ == "__main__":
    main()
