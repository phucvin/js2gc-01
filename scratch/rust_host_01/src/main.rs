use wasmtime::*;
use std::env;
use std::fs;

fn main() -> Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <wasm-file>", args[0]);
        std::process::exit(1);
    }
    let wasm_file = &args[1];

    let mut config = Config::new();
    config.wasm_function_references(true);
    config.wasm_gc(true);
    config.wasm_reference_types(true);

    let engine = Engine::new(&config)?;
    let mut store = Store::new(&engine, ());

    let mut linker = Linker::new(&engine);

    // print_i32: (param i32)
    linker.func_wrap("env", "print_i32", |val: i32| {
        println!("{}", val);
    })?;

    // print_f64: (param f64)
    linker.func_wrap("env", "print_f64", |val: f64| {
        println!("{}", val);
    })?;

    // print_string: (param (ref string))
    // This is optional if disableStrings is true, but good to have if we manage to enable it.
    // If the module imports it, we provide it.
    let string_type = ValType::Ref(RefType::new(false, HeapType::Any));
    linker.func_new(
        "env",
        "print_string",
        FuncType::new(&engine, vec![string_type.clone()], vec![]),
        |mut _caller, _params, _results| {
             println!("(string)");
             Ok(())
        }
    )?;

    let wasm_bytes = fs::read(wasm_file)?;
    let module = Module::new(&engine, &wasm_bytes)?;

    let instance = linker.instantiate(&mut store, &module)?;

    let main_func = instance.get_func(&mut store, "main").expect("main function not found");

    // The main function in our compiler returns `anyref`.
    // We need to provide space for the result.
    let mut results = vec![Val::null_any_ref()];

    match main_func.call(&mut store, &[], &mut results) {
        Ok(_) => {},
        Err(e) => {
            eprintln!("Error calling main: {}", e);
        }
    }

    Ok(())
}
