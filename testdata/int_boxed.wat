(module
  (type $BoxedF64 (struct (field f64)))
  (type $BoxedI32 (struct (field i32)))
  (type $BoxedString (struct (field (ref string))))

  (func $main (export "main") (result anyref)
    (struct.new $BoxedI32 (i32.const 1073741824))
  )
)