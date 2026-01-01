(module
  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))

  (func $main (export "main") (result anyref)
    (ref.i31 (i32.const 42))
  )
)